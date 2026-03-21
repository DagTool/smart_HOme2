// lib/models/models.dart
// Tất cả các data model của app

/// Trạng thái thiết bị nhà thông minh
class DeviceState {
  final bool light;
  final bool door;
  final bool window;
  final bool ac;
  final bool gate;
  final String masterPassword;
  final String currentOtp;
  final int otpCountdown;
  final String esp32Status;
  final String lastEvent;
  final String registeredCards;
  final int cardCount;
  final String? securityAlert;

  const DeviceState({
    this.light = false,
    this.door = false,
    this.window = false,
    this.ac = false,
    this.gate = false,
    this.masterPassword = '',
    this.currentOtp = '------',
    this.otpCountdown = 30,
    this.esp32Status = 'offline',
    this.lastEvent = '',
    this.registeredCards = '',
    this.cardCount = 0,
    this.securityAlert,
  });

  DeviceState copyWith({
    bool? light,
    bool? door,
    bool? window,
    bool? ac,
    bool? gate,
    String? masterPassword,
    String? currentOtp,
    int? otpCountdown,
    String? esp32Status,
    String? lastEvent,
    String? registeredCards,
    int? cardCount,
    String? securityAlert,
  }) {
    return DeviceState(
      light: light ?? this.light,
      door: door ?? this.door,
      window: window ?? this.window,
      ac: ac ?? this.ac,
      gate: gate ?? this.gate,
      masterPassword: masterPassword ?? this.masterPassword,
      currentOtp: currentOtp ?? this.currentOtp,
      otpCountdown: otpCountdown ?? this.otpCountdown,
      esp32Status: esp32Status ?? this.esp32Status,
      lastEvent: lastEvent ?? this.lastEvent,
      registeredCards: registeredCards ?? this.registeredCards,
      cardCount: cardCount ?? this.cardCount,
      securityAlert: securityAlert ?? this.securityAlert,
    );
  }

  factory DeviceState.fromMap(Map<dynamic, dynamic> map) {
    final control = map['device_control'] as Map? ?? {};
    final status = map['status'] as Map? ?? {};
    final alerts = map['alerts'] as Map? ?? {};

    return DeviceState(
      light: (control['light_status'] ?? 0) == 1,
      door: (control['door_status'] ?? 0) == 1,
      window: (control['window_status'] ?? 0) == 1,
      ac: (control['ac_status'] ?? 0) == 1,
      masterPassword: control['master_password']?.toString() ?? '',
      currentOtp: status['current_otp']?.toString() ?? '------',
      otpCountdown: (status['otp_countdown'] ?? 30) as int,
      esp32Status: status['esp32_status']?.toString() ?? 'offline',
      lastEvent: status['last_event']?.toString() ?? '',
      registeredCards: status['registered_cards']?.toString() ?? '',
      cardCount: (status['card_count'] ?? 0) as int,
      securityAlert: alerts['security']?.toString(),
    );
  }
}

/// Bản ghi lịch sử ra/vào
class LogEntry {
  final String id;
  final String user;
  final String method;
  final String action;
  final String time;

  const LogEntry({
    required this.id,
    required this.user,
    required this.method,
    required this.action,
    required this.time,
  });

  factory LogEntry.fromMap(String id, Map<dynamic, dynamic> map) {
    return LogEntry(
      id: id,
      user: map['user']?.toString() ?? 'Unknown',
      method: map['method']?.toString() ?? '-',
      action: map['action']?.toString() ?? '-',
      time: map['time']?.toString() ?? '-',
    );
  }

  Map<String, dynamic> toMap() => {
    'user': user,
    'method': method,
    'action': action,
    'time': time,
  };
}

/// Thành viên trong nhà
class Member {
  final String uid;
  final String name;
  final String email;
  final String role; // 'admin' | 'member' | 'guest'

  const Member({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
  });

  factory Member.fromMap(String uid, Map<dynamic, dynamic> map) {
    return Member(
      uid: uid,
      name: map['name']?.toString() ?? 'Unknown',
      email: map['email']?.toString() ?? '',
      role: map['role']?.toString() ?? 'member',
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'role': role,
  };

  bool get isAdmin => role == 'admin';
}

/// Cài đặt nhà
class HomeSettings {
  final String homeName;
  final String inviteCode;
  final String adminUid;

  const HomeSettings({
    this.homeName = 'Smart Home',
    this.inviteCode = '',
    this.adminUid = '',
  });

  factory HomeSettings.fromMap(Map<dynamic, dynamic> map) {
    return HomeSettings(
      homeName: map['home_name']?.toString() ?? 'Smart Home',
      inviteCode: map['invite_code']?.toString() ?? '',
      adminUid: map['admin_uid']?.toString() ?? '',
    );
  }
}
