#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <Adafruit_PN532.h>
#include <Keypad.h>
#include <Preferences.h>
#include <ThreeWire.h>  
#include <RtcDS1302.h>
#include <TOTP.h>
#include <Stepper.h>

// ===== WIFI + FIREBASE CONFIG =====
#define WIFI_SSID "Tro 1046 QT YN T3"
#define WIFI_PASSWORD "123456a@"
#define DATABASE_URL "https://henhung-99234-default-rtdb.asia-southeast1.firebasedatabase.app/"
#define DATABASE_SECRET "vhJUpPpyiFbtWKkTWQWB8e9ZlPlnV3VubODxXd6W"

// ===== ĐỊNH DANH NHÀ CỦA ADMIN =====
#define FIREBASE_HOUSE_ID "pVnqVaMNy5P2S3YIR9RB8WRu7lR2"
String basePath = String("/homes/") + FIREBASE_HOUSE_ID;

FirebaseData fbdo;
FirebaseData stream;
FirebaseAuth auth;
FirebaseConfig config;

// ===== RTC + TOTP =====
ThreeWire myWire(11, 10, 12); 
RtcDS1302<ThreeWire> Rtc(myWire);
uint8_t hmacKey[] = { 
  0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x30, 
  0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x30 
};
TOTP totp = TOTP(hmacKey, 20);

Preferences prefs;

// ===== HARDWARE PINS =====
#define SDA_PIN 8
#define SCL_PIN 9
#define SERVO_PIN 14
#define RAIN_SENSOR_PIN 13
#define WINDOW_SERVO_PIN 21
#define BUZZER_PIN 17
#define LED_DO 16
#define LED_XANH 15
#define LED_VANG 18

LiquidCrystal_I2C lcd(0x27, 16, 2);
Adafruit_PN532 nfc(SDA_PIN, SCL_PIN);

// ===== KEYPAD =====
const byte ROWS = 4, COLS = 4;
char keys[ROWS][COLS] = { 
  {'1','2','3','A'}, 
  {'4','5','6','B'}, 
  {'7','8','9','C'}, 
  {'*','0','#','D'} 
};
byte rowPins[ROWS] = {1,2,42,41};
byte colPins[COLS] = {40,39,38,37};
Keypad keypad(makeKeymap(keys), rowPins, colPins, ROWS, COLS);

// ===== STEPPER MOTOR =====
const int stepsPerRev = 2048;
Stepper independentGate(stepsPerRev, 4, 6, 5, 7); 

// ===== LOGIC VARIABLES =====
const int MAX_FAILS = 3;
const long LOCK_TIME = 30000;
String password = "123456";
String input = "";
int failCount = 0;
unsigned long lockUntil = 0;
String lastUsedOTP = "";
bool lightStatus = false;
bool windowStatus = false;
bool gateStatus = false;
bool doorStatus = false;
bool acStatus = false;
bool isRaining = false;
unsigned long lastManualAction = 0;    // Lưu thời điểm cuối cùng bấm nút/app
const long overrideDuration = 3000;   // Chặn tự động trong 30 giây (tùy chỉnh)

#define MAX_CARDS 20
String cardList[MAX_CARDS];
int cardCount = 0;
const String ADMIN_UID = "03:AD:13:F8";

enum SystemMode { 
  MODE_NORMAL, 
  MODE_ADD_CARD, 
  MODE_DELETE_CARD, 
  MODE_VERIFY_OLD_PASS, 
  MODE_CHANGE_PASS,
  MODE_CONFIRM_NEW_PASS
};
String tempPassword = "";
SystemMode currentMode = MODE_NORMAL;
String lastScannedUID = "";

// ===== FIREBASE STREAM CALLBACK =====
void streamCallback(FirebaseStream data) {
  Serial.println("📨 Stream Update:");
  Serial.println("Path: " + data.dataPath());
  Serial.println("Type: " + data.dataType());
  
  String path = data.dataPath();
  
  // 🚪 DOOR CONTROL
  if (path == "/door_status" || path.endsWith("/door_status")) {
    doorStatus = data.intData();
    Serial.println("Door: " + String(doorStatus));
    
    if (doorStatus == 1 && lockUntil == 0) {
      openDoor();
      Firebase.RTDB.setInt(&fbdo, basePath + "/device_control/door_status", 0);
    }
  }
  
  // 💡 LIGHT CONTROL
  else if (path == "/light_status" || path.endsWith("/light_status")) {
    lightStatus = data.intData();
    digitalWrite(LED_VANG, lightStatus);
    sendLog(lightStatus ? "Light ON via App" : "Light OFF via App");
    Serial.println("Light: " + String(lightStatus ? "ON" : "OFF"));
  }
  
  // 🪟 WINDOW CONTROL
  else if (path == "/window_status" || path.endsWith("/window_status")) {
    windowStatus = data.intData();
    moveWindow(windowStatus ? 90 : 0);
    
    lcd.clear();
    lcd.print(windowStatus ? "Window Opening" : "Window Closing");
    sendLog(windowStatus ? "Window OPEN via App" : "Window CLOSE via App");
    delay(1000);
    showNormalScreen();
  }
  
  // ❄️ AC CONTROL
  else if (path == "/ac_status" || path.endsWith("/ac_status")) {
    acStatus = data.intData();
    sendLog(acStatus ? "AC ON via App" : "AC OFF via App");
    Serial.println("AC: " + String(acStatus ? "ON" : "OFF"));
  }
  
  // 🔑 MASTER PASSWORD
  else if (path == "/master_password" || path.endsWith("/master_password")) {
    String newPass = data.stringData();
    Serial.println("New password from app: " + newPass);
    
    if (newPass.length() >= 4 && newPass.length() <= 16) {
      password = newPass;
      prefs.putString("pass", password);
      sendLog("Password changed from App");
      
      lcd.clear();
      lcd.print("Pass Updated!");
      delay(1500);
      showNormalScreen();
    }
  }
}

void streamTimeoutCallback(bool timeout) {
  if (timeout) {
    Serial.println("⚠️ Stream timeout, resuming...");
  }
}

// ===== BASIC FUNCTIONS =====
void moveServo(int angle) {
  int duty = map(angle, 0, 180, 410, 2048);
  ledcWrite(SERVO_PIN, duty);
}

void moveWindow(int angle) {
  // Chuyển đổi góc xoay sang giá trị Duty Cycle cho Servo
  int duty = map(angle, 0, 180, 410, 2048); 
  ledcWrite(WINDOW_SERVO_PIN, duty);

  // Nếu góc > 0 (tức là đang mở cửa), cập nhật mốc thời gian chặn tự động
  if (angle > 0) {
    lastManualAction = millis();
    Serial.println("👉 Manual/App Open detected. Rain auto-close paused.");
  }
}

void beepOK() { 
  digitalWrite(LED_XANH, HIGH); 
  tone(BUZZER_PIN, 2000, 100); 
  delay(150); 
  digitalWrite(LED_XANH, LOW); 
}

void beepFail() { 
  digitalWrite(LED_DO, HIGH); 
  tone(BUZZER_PIN, 500, 400); 
  delay(500); 
  digitalWrite(LED_DO, LOW); 
}

void showNormalScreen() {
  delay(500); 
  lcd.clear();
  lcd.print("Scan Card / PIN");
  lcd.setCursor(0, 1); 
  lcd.print("Ready");
}

void sendLog(String msg) {
  if (!Firebase.ready()) return;
  
  RtcDateTime now = Rtc.GetDateTime();
  char timeBuf[25];
  sprintf(timeBuf, "%02d:%02d %02d/%02d/%04d", now.Hour(), now.Minute(), now.Day(), now.Month(), now.Year());
  
  // Khai báo đối tượng JSON giống cấu trúc App Flutter
  FirebaseJson json;
  json.set("user", "Thiết bị ESP32");
  json.set("method", "Phần cứng (Thẻ/Phím)");
  json.set("action", msg);
  json.set("time", String(timeBuf));
  
  // Push JSON vào /logs để App Flutter có thể đọc đồng bộ
  Firebase.RTDB.pushJSON(&fbdo, basePath + "/logs", &json);
  
  // Update last event
  Firebase.RTDB.setString(&fbdo, basePath + "/status/last_event", msg);
  
  Serial.println(msg);
}

void syncCardsToFirebase() {
  if (!Firebase.ready()) return;
  
  String allCards = "";
  for (int i = 0; i < cardCount; i++) {
    allCards += cardList[i];
    if (i < cardCount - 1) allCards += ", ";
  }
  
  Firebase.RTDB.setString(&fbdo, basePath + "/status/registered_cards", 
                         allCards.length() > 0 ? allCards : "No cards");
  Firebase.RTDB.setInt(&fbdo, basePath + "/status/card_count", cardCount);
}

void openDoor() {
  lcd.clear(); 
  lcd.print("Door OPEN");
  sendLog("Door Opened"); 
  
  moveServo(90); 
  beepOK(); 
  
  // Cập nhật Firebase
  if (Firebase.ready()) {
    Firebase.RTDB.setInt(&fbdo, basePath + "/device_control/door_status", 1);
  }
  
  delay(3000); 
  moveServo(0);
  
  lcd.clear(); 
  lcd.print("Door CLOSED");
  sendLog("Door Closed"); 
  
  // Cập nhật Firebase
  if (Firebase.ready()) {
    Firebase.RTDB.setInt(&fbdo, basePath + "/device_control/door_status", 0);
  }
  
  delay(1000);
  showNormalScreen();
}

// ===== CARD MANAGEMENT =====
void saveCardsToFlash() {
  prefs.putInt("count", cardCount);
  for (int i = 0; i < cardCount; i++) {
    prefs.putString(("card" + String(i)).c_str(), cardList[i]);
  }
  syncCardsToFirebase();
}

bool isEasyPassword(String pass) {
  bool allSame = true;
  for (int i = 1; i < pass.length(); i++) {
    if (pass[i] != pass[0]) {
      allSame = false;
      break;
    }
  }
  if (allSame) return true;

  bool consecutiveUp = true;
  for (int i = 1; i < pass.length(); i++) {
    if (pass[i] != pass[i-1] + 1) {
      consecutiveUp = false;
      break;
    }
  }
  if (consecutiveUp) return true;

  bool consecutiveDown = true;
  for (int i = 1; i < pass.length(); i++) {
    if (pass[i] != pass[i-1] - 1) {
      consecutiveDown = false;
      break;
    }
  }
  if (consecutiveDown) return true;

  return false;
}

bool cardExists(String uid) {
  for (int i = 0; i < cardCount; i++) {
    if (cardList[i] == uid) return true;
  }
  return false;
}

bool addCard(String uid) {
  if (uid == "" || cardExists(uid) || cardCount >= MAX_CARDS) return false;
  cardList[cardCount++] = uid;
  saveCardsToFlash();
  return true;
}

bool deleteCard(String uid) {
  for (int i = 0; i < cardCount; i++) {
    if (cardList[i] == uid) {
      for (int j = i; j < cardCount - 1; j++) {
        cardList[j] = cardList[j + 1];
      }
      cardCount--; 
      saveCardsToFlash(); 
      return true;
    }
  }
  return false;
}

void updateOTPToFirebase() {
  static unsigned long lastOTPUpdate = 0;
  
  if (millis() - lastOTPUpdate > 1000) {
    lastOTPUpdate = millis();
    
    if (!Firebase.ready()) return;
    
    long utcOffset = 7 * 3600;
    RtcDateTime now = Rtc.GetDateTime();
    String currentOTP = String(totp.getCode(now.TotalSeconds() - utcOffset));
    while (currentOTP.length() < 6) currentOTP = "0" + currentOTP;

    Firebase.RTDB.setString(&fbdo, basePath + "/status/current_otp", currentOTP);
    
    int countdown = 30 - (now.TotalSeconds() % 30);
    Firebase.RTDB.setInt(&fbdo, basePath + "/status/otp_countdown", countdown);
  }
}

// ===== SETUP =====
void setup() {
  Serial.begin(115200);
  
  pinMode(LED_DO, OUTPUT); 
  pinMode(LED_XANH, OUTPUT); 
  pinMode(LED_VANG, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(RAIN_SENSOR_PIN, INPUT);
  
  digitalWrite(LED_VANG, LOW);
  
  Wire.begin(SDA_PIN, SCL_PIN);
  lcd.init(); 
  lcd.backlight();
  
  Rtc.Begin(); 
  Rtc.SetIsRunning(true);
  
  nfc.begin(); 
  nfc.SAMConfig();
  
  // ✅ FIX: Dùng ledcAttach thay vì ledcAttachPin (ESP32 Core 3.x)
  ledcAttach(SERVO_PIN, 50, 14); // pin, freq, resolution
  moveServo(0);
  
  ledcAttach(WINDOW_SERVO_PIN, 50, 14);
  moveWindow(0);
  
  independentGate.setSpeed(10);

  prefs.begin("rfid", false);
  password = prefs.getString("pass", "123456");
  cardCount = prefs.getInt("count", 0);
  for (int i = 0; i < cardCount; i++) {
    cardList[i] = prefs.getString(("card" + String(i)).c_str(), "");
  }

  // Kết nối WiFi
  lcd.clear();
  lcd.print("Connecting WiFi");
  Serial.println("\n🔌 Connecting to WiFi...");
  
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    lcd.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✅ WiFi Connected!");
    Serial.print("IP: ");
    Serial.println(WiFi.localIP());
    
    lcd.clear();
    lcd.print("WiFi OK!");
    lcd.setCursor(0, 1);
    lcd.print(WiFi.localIP());
    delay(2000);

    // Cấu hình Firebase
    config.database_url = DATABASE_URL;
    config.signer.tokens.legacy_token = DATABASE_SECRET;

    Firebase.begin(&config, &auth);
    Firebase.reconnectWiFi(true);

    Serial.println("🔥 Firebase Initializing...");
    lcd.clear();
    lcd.print("Firebase...");
    
    delay(2000);

    if (Firebase.ready()) {
      Serial.println("✅ Firebase Ready!");
      lcd.clear();
      lcd.print("Firebase OK!");
      
      // Sync dữ liệu từ Firebase về ESP32
      if (Firebase.RTDB.getString(&fbdo, basePath + "/device_control/master_password")) {
        String fbPass = fbdo.stringData();
        if (fbPass.length() >= 4) {
          password = fbPass;
          prefs.putString("pass", password);
          Serial.println("Password from Firebase: " + password);
        }
      }
      
      // Đọc trạng thái thiết bị
      if (Firebase.RTDB.getInt(&fbdo, basePath + "/device_control/light_status")) {
        lightStatus = fbdo.intData();
        digitalWrite(LED_VANG, lightStatus);
      }
      
      if (Firebase.RTDB.getInt(&fbdo, basePath + "/device_control/window_status")) {
        windowStatus = fbdo.intData();
        moveWindow(windowStatus ? 90 : 0);
      }
      
      if (Firebase.RTDB.getInt(&fbdo, basePath + "/device_control/ac_status")) {
        acStatus = fbdo.intData();
      }
      
      // Bắt đầu Stream
      Serial.println("📡 Starting stream...");
      
      if (!Firebase.RTDB.beginStream(&stream, basePath + "/device_control")) {
        Serial.println("❌ Stream failed!");
        Serial.println("Reason: " + stream.errorReason());
      } else {
        Serial.println("✅ Stream started!");
        Firebase.RTDB.setStreamCallback(&stream, streamCallback, streamTimeoutCallback);
      }
      
      // Sync cards và set status
      syncCardsToFirebase();
      Firebase.RTDB.setString(&fbdo, basePath + "/status/esp32_status", "online");
      
    } else {
      Serial.println("❌ Firebase Connection Failed!");
      lcd.clear();
      lcd.print("Firebase Failed!");
    }
  } else {
    Serial.println("❌ WiFi Connection Failed!");
    lcd.clear();
    lcd.print("WiFi Failed!");
  }

  delay(2000);
  showNormalScreen();
}

// ===== LOOP =====
void loop() {
  // Update OTP
  updateOTPToFirebase();

  // Xử lý Lock
  if (lockUntil > 0) {
    if (millis() < lockUntil) {
      lcd.setCursor(0, 0); 
      lcd.print("LOCKED! Wait... ");
      lcd.setCursor(0, 1); 
      lcd.print("Time: "); 
      lcd.print((lockUntil - millis()) / 1000); 
      lcd.print("s    ");
      return;
    } else { 
      lockUntil = 0; 
      failCount = 0; 
      showNormalScreen(); 
    }
  }

  // Xử lý Keypad
  char key = keypad.getKey();
  if (key) handleKeypad(key);

  // Xử lý RFID
  static unsigned long lastRFID = 0;
  if (millis() - lastRFID >= 200) {
    lastRFID = millis();
    
    uint8_t uid[7], uidLength;
    if (nfc.readPassiveTargetID(PN532_MIFARE_ISO14443A, uid, &uidLength, 50)) {
      String uidStr = "";
      for (uint8_t i = 0; i < uidLength; i++) {
        if (uid[i] < 0x10) uidStr += "0";
        uidStr += String(uid[i], HEX);
        if (i < uidLength - 1) uidStr += ":";
      }
      uidStr.toUpperCase();
      lastScannedUID = uidStr;

      if (uidStr == ADMIN_UID && currentMode == MODE_NORMAL) {
        lcd.clear(); 
        lcd.print("Admin Card"); 
        lcd.setCursor(0, 1); 
        lcd.print("A:Add B:Del C:Change"); 
        beepOK(); 
        return;
      }

      if (currentMode == MODE_ADD_CARD) {
        if (uidStr == ADMIN_UID) { 
          beepFail(); 
          currentMode = MODE_NORMAL; 
          showNormalScreen(); 
          return; 
        }
        lcd.clear(); 
        lcd.print(cardExists(uidStr) ? "Exists!" : "New Card:");
        lcd.setCursor(0, 1); 
        lcd.print(uidStr);
        if (cardExists(uidStr)) beepFail();
        return;
      }

      if (currentMode == MODE_DELETE_CARD) {
        if (uidStr == ADMIN_UID) { 
          beepFail(); 
          currentMode = MODE_NORMAL; 
          showNormalScreen(); 
          return; 
        }
        lcd.clear(); 
        lcd.print(!cardExists(uidStr) ? "Not Found" : "Delete?");
        lcd.setCursor(0, 1); 
        lcd.print(uidStr);
        if (!cardExists(uidStr)) beepFail();
        return;
      }

      if (cardExists(uidStr)) {
        openDoor();
      } else { 
        lcd.clear(); 
        lcd.print("Denied"); 
        sendLog("Unauthorized Card: " + uidStr); 
        beepFail(); 
        delay(1500);
        showNormalScreen(); 
      }
    }
  }
  
  // 🔥 CẬP NHẬT LOGIC ANALOG TRÊN CHÂN 35
  // 🔥 XỬ LÝ MƯA TRÊN ESP32-S3 (CHÂN 13)
  static unsigned long lastRainCheck = 0;
  if (millis() - lastRainCheck > 500) {
      lastRainCheck = millis();
      
      // ESP32-S3 ADC
      int rainAnalogVal = analogRead(RAIN_SENSOR_PIN); 
      static int wetCount = 0;

      // In giá trị THẬT để bạn soi
      Serial.print("🌧️ ADC Val (Pin 13): "); 
      Serial.println(rainAnalogVal);

      // Ngưỡng phát hiện (Thử 500 trước)
      bool isWet = (rainAnalogVal > 500); 

      if (isWet) {
          wetCount++;
          if (wetCount >= 3) {
              isRaining = true; 
              if (windowStatus == true && (millis() - lastManualAction > overrideDuration)) {
                  Serial.println("☔ [SYSTEM] Raining! Closing window...");
                  windowStatus = false;
                  
                  // Đóng Servo
                  int duty = map(0, 0, 180, 410, 2048); 
                  ledcWrite(WINDOW_SERVO_PIN, duty);

                  if (Firebase.ready()) Firebase.RTDB.setInt(&fbdo, basePath + "/device_control/window_status", 0);
                  lcd.clear(); lcd.print("RAIN! Closing...");
                  delay(1500);
                  showNormalScreen();
              }
          }
      } else {
          wetCount = 0;
          isRaining = false;
      }
  }

  delay(100);
}

void handleKeypad(char key) {
  tone(BUZZER_PIN, 3000, 50);
  
  if (key == 'D') {
    if (currentMode != MODE_NORMAL) {
      currentMode = MODE_NORMAL;
      input = "";
      lcd.clear();
      lcd.print("Exiting Menu...");
      showNormalScreen();
    } else {
      lightStatus = !lightStatus;
      digitalWrite(LED_VANG, lightStatus);
      
      if (Firebase.ready()) {
        Firebase.RTDB.setInt(&fbdo, basePath + "/device_control/light_status", lightStatus);
      }
      
      lcd.clear();
      lcd.print("Light: ");
      lcd.print(lightStatus ? "ON" : "OFF");
      sendLog(lightStatus ? "Light ON via Keypad" : "Light OFF via Keypad");
      delay(1000); 
      showNormalScreen();
    }
    return;
  }
  
  if (key == 'C' && lastScannedUID == ADMIN_UID) {
    currentMode = MODE_VERIFY_OLD_PASS;
    input = ""; 
    lcd.clear();
    lcd.print("OLD PASSWORD:");
    lcd.setCursor(0, 1);
    lcd.print("In: ");
    return;
  }
  
  if (key == 'A' && lastScannedUID == ADMIN_UID) { 
    currentMode = MODE_ADD_CARD; 
    lcd.clear(); 
    lcd.print("ADD CARD MODE"); 
    return; 
  }
  
  if (key == 'B' && lastScannedUID == ADMIN_UID) { 
    currentMode = MODE_DELETE_CARD; 
    lcd.clear(); 
    lcd.print("DEL CARD MODE"); 
    return; 
  }

  if (key == '*') { 
    input = ""; 
    lcd.setCursor(0, 1); 
    lcd.print("Ready           "); 
  }
  else if (key == '#') {
    if (currentMode == MODE_ADD_CARD) {
      if (addCard(lastScannedUID)) { 
        lcd.clear(); 
        lcd.print("Card Added"); 
        sendLog("Added Card: " + lastScannedUID); 
        beepOK(); 
      } else {
        beepFail();
      }
      currentMode = MODE_NORMAL; 
      lastScannedUID = ""; 
      delay(1500);
      showNormalScreen(); 
      return;
    }
    
    if (currentMode == MODE_DELETE_CARD) {
      String toDel = lastScannedUID;
      if (deleteCard(toDel)) { 
        lcd.clear(); 
        lcd.print("Deleted"); 
        sendLog("Deleted Card: " + toDel); 
        beepOK(); 
      } else {
        beepFail();
      }
      currentMode = MODE_NORMAL; 
      lastScannedUID = ""; 
      delay(1500);
      showNormalScreen(); 
      return;
    }
    
    if (currentMode == MODE_VERIFY_OLD_PASS) {
      if (input == password) {
        currentMode = MODE_CHANGE_PASS;
        lcd.clear();
        lcd.print("NEW PASSWORD:");
        lcd.setCursor(0, 1);
        lcd.print("In: ");
        beepOK();
      } else {
        lcd.clear();
        lcd.print("WRONG OLD PASS!");
        beepFail();
        currentMode = MODE_NORMAL;
        showNormalScreen();
      }
      input = "";
      return;
    }

    // 2. Nhập mật khẩu mới (Bước 1)
    if (currentMode == MODE_CHANGE_PASS) {
      if (input.length() < 6) {
        lcd.clear(); lcd.print("TOO SHORT!"); beepFail();
        delay(1000); lcd.clear(); lcd.print("NEW PASSWORD:"); lcd.setCursor(0, 1); lcd.print("In: ");
      } else if (isEasyPassword(input)) {
        lcd.clear(); lcd.print("TOO SIMPLE!"); beepFail();
        delay(1000); lcd.clear(); lcd.print("NEW PASSWORD:"); lcd.setCursor(0, 1); lcd.print("In: ");
      } else {
        tempPassword = input; // Lưu tạm
        currentMode = MODE_CONFIRM_NEW_PASS; // Chuyển sang bước xác nhận
        lcd.clear();
        lcd.print("CONFIRM PASS:");
        lcd.setCursor(0, 1);
        lcd.print("In: ");
        beepOK();
      }
      input = "";
      return;
    }

    // 3. Xác nhận mật khẩu mới (Bước 2)
    if (currentMode == MODE_CONFIRM_NEW_PASS) {
      if (input == tempPassword) {
        password = input;
        prefs.putString("pass", password);
        if (Firebase.ready()) Firebase.RTDB.setString(&fbdo, basePath + "/device_control/master_password", password);
        
        lcd.clear();
        lcd.print("PASS CHANGED!");
        sendLog("Password changed");
        beepOK();
        currentMode = MODE_NORMAL;
        lastScannedUID = "";
        delay(1500);
        showNormalScreen();
      } else {
        lcd.clear();
        lcd.print("NOT MATCH!");
        beepFail();
        delay(1500);
        // Quay lại bước nhập mới
        currentMode = MODE_CHANGE_PASS;
        lcd.clear();
        lcd.print("NEW PASSWORD:");
        lcd.setCursor(0, 1);
        lcd.print("In: ");
      }
      input = "";
      tempPassword = "";
      return;
    }

    // Xử lý mở cửa bằng PIN/OTP
    long utcOffset = 7 * 3600;
    String currentOTP = String(totp.getCode(Rtc.GetDateTime().TotalSeconds() - utcOffset));
    while (currentOTP.length() < 6) currentOTP = "0" + currentOTP; 

    if (input == password) {
      failCount = 0; 
      openDoor();
    } else if (input == currentOTP) {
      if (input == lastUsedOTP) {
        lcd.clear();
        lcd.print("OTP ALREADY USED");
        lcd.setCursor(0, 1);
        lcd.print("Wait for new one");
        sendLog("Denied: Reused OTP");
        beepFail();
      } else {
        lastUsedOTP = input;
        sendLog("Opened by OTP");
        failCount = 0; 
        openDoor();
      }
    } else {
      failCount++;
      if (failCount >= MAX_FAILS) {
        lockUntil = millis() + LOCK_TIME;
        
        if (Firebase.ready()) {
          Firebase.RTDB.setString(&fbdo, basePath + "/alerts/security", "BRUTE FORCE: 3 wrong attempts!");
        }
        
        sendLog("!!! ALERT: BRUTE FORCE ATTEMPT !!!");
        digitalWrite(LED_DO, HIGH); 
        tone(BUZZER_PIN, 500, 2000); 
        delay(2000); 
        digitalWrite(LED_DO, LOW);
        lcd.clear();
        lcd.print("SYSTEM LOCKED!");
      } else { 
        lcd.setCursor(0, 1); 
        lcd.print("Wrong! "); 
        lcd.print(failCount); 
        sendLog("Wrong PIN #" + String(failCount)); 
        beepFail(); 
      }
    }
    input = "";
  } else {
    if (input.length() < 16) {
      input += key;
      lcd.setCursor(4, 1); // Đặt sau chữ "In: "
      
      // Hiện dấu * cho tất cả các mode nhập mật khẩu/PIN
      for (int i = 0; i < input.length(); i++) lcd.print("*");
      lcd.print("                ");
    }
  }
}