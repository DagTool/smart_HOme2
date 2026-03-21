// lib/services/firebase_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';
import '../models/models.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance;
  final _rng = Random();

  User? get currentUser => _auth.currentUser;
  String get uid => _auth.currentUser?.uid ?? '';

  // ─────────────────────────────────────────
  // AUTH
  // ─────────────────────────────────────────

  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> register(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ─────────────────────────────────────────
  // USER / HOUSE MANAGEMENT
  // ─────────────────────────────────────────

  /// Lấy house_id của user hiện tại
  Future<String?> getHouseId() async {
    final snap = await _db.ref('users/$uid/house_id').get();
    return snap.exists ? snap.value?.toString() : null;
  }

  /// Tạo nhà mới (admin mới)
  Future<String> createHome(String homeName, String displayName) async {
    final houseId = uid; // admin UID = house ID
    final inviteCode = _generateCode();

    // Tạo cấu trúc nhà
    await _db.ref('homes/$houseId').set({
      'settings': {
        'home_name': homeName,
        'admin_uid': uid,
        'invite_code': inviteCode,
        'created_at': ServerValue.timestamp,
      },
      'users': {
        uid: {
          'name': displayName,
          'email': currentUser?.email ?? '',
          'role': 'admin',
          'joined_at': ServerValue.timestamp,
        }
      },
      'device_control': {
        'light_status': 0,
        'door_status': 0,
        'window_status': 0,
        'ac_status': 0,
        'master_password': '123456',
      },
      'status': {
        'esp32_status': 'offline',
        'current_otp': '------',
        'otp_countdown': 30,
        'last_event': 'Home created',
        'registered_cards': 'No cards',
        'card_count': 0,
      },
    });

    // Lưu mã mời để tra cứu
    await _db.ref('invite_codes/$inviteCode').set({'house_id': houseId});

    // Ghi house_id vào user
    await _db.ref('users/$uid').set({'house_id': houseId});

    return houseId;
  }

  /// Tham gia nhà bằng mã mời
  Future<String?> joinHomeByCode(String code, String displayName) async {
    final snap = await _db.ref('invite_codes/$code').get();
    if (!snap.exists) return null;

    final houseId = (snap.value as Map)['house_id']?.toString();
    if (houseId == null) return null;

    // Thêm user vào danh sách thành viên
    await _db.ref('homes/$houseId/users/$uid').set({
      'name': displayName,
      'email': currentUser?.email ?? '',
      'role': 'member',
      'joined_at': ServerValue.timestamp,
    });

    // Ghi house_id vào user
    await _db.ref('users/$uid').set({'house_id': houseId});

    return houseId;
  }

  // ─────────────────────────────────────────
  // DEVICE CONTROL
  // ─────────────────────────────────────────

  String _basePath(String houseId) => 'homes/$houseId/device_control';

  Future<void> setLight(String houseId, bool on) async {
    await _db.ref('${_basePath(houseId)}/light_status').set(on ? 1 : 0);
  }

  Future<void> setDoor(String houseId, bool open) async {
    await _db.ref('${_basePath(houseId)}/door_status').set(open ? 1 : 0);
  }

  Future<void> setWindow(String houseId, bool open) async {
    await _db.ref('${_basePath(houseId)}/window_status').set(open ? 1 : 0);
  }

  Future<void> setAC(String houseId, bool on) async {
    await _db.ref('${_basePath(houseId)}/ac_status').set(on ? 1 : 0);
  }

  Future<void> setMasterPassword(String houseId, String password) async {
    await _db.ref('${_basePath(houseId)}/master_password').set(password);
  }

  // ─────────────────────────────────────────
  // STREAMS - REALTIME LISTENER
  // ─────────────────────────────────────────

  /// Stream toàn bộ dữ liệu nhà (cho DeviceProvider)
  Stream<DeviceState> homeStream(String houseId) {
    return _db.ref('homes/$houseId').onValue.map((event) {
      if (!event.snapshot.exists) return const DeviceState();
      return DeviceState.fromMap(
          event.snapshot.value as Map<dynamic, dynamic>);
    });
  }

  /// Stream logs lịch sử ra vào (50 bản ghi mới nhất)
  Stream<List<LogEntry>> logsStream(String houseId) {
    return _db
        .ref('homes/$houseId/logs')
        .orderByKey()
        .limitToLast(50)
        .onValue
        .map((event) {
      if (!event.snapshot.exists) return [];
      final map = event.snapshot.value as Map<dynamic, dynamic>;
      final entries = map.entries
          .map((e) => LogEntry.fromMap(e.key.toString(),
              e.value as Map<dynamic, dynamic>))
          .toList();
      return entries.reversed.toList(); // Mới nhất lên đầu
    });
  }

  /// Stream danh sách thành viên
  Stream<List<Member>> membersStream(String houseId) {
    return _db.ref('homes/$houseId/users').onValue.map((event) {
      if (!event.snapshot.exists) return [];
      final map = event.snapshot.value as Map<dynamic, dynamic>;
      return map.entries
          .map((e) => Member.fromMap(
              e.key.toString(), e.value as Map<dynamic, dynamic>))
          .toList();
    });
  }

  /// Stream cài đặt nhà
  Stream<HomeSettings> settingsStream(String houseId) {
    return _db.ref('homes/$houseId/settings').onValue.map((event) {
      if (!event.snapshot.exists) return const HomeSettings();
      return HomeSettings.fromMap(
          event.snapshot.value as Map<dynamic, dynamic>);
    });
  }

  // ─────────────────────────────────────────
  // MEMBER MANAGEMENT (Admin only)
  // ─────────────────────────────────────────

  Future<void> removeMember(String houseId, String memberUid) async {
    await _db.ref('homes/$houseId/users/$memberUid').remove();
    await _db.ref('users/$memberUid/house_id').remove();
  }

  Future<void> changeRole(
      String houseId, String memberUid, String newRole) async {
    await _db
        .ref('homes/$houseId/users/$memberUid/role')
        .set(newRole);
  }

  Future<void> regenerateInviteCode(String houseId) async {
    final oldSnap =
        await _db.ref('homes/$houseId/settings/invite_code').get();
    if (oldSnap.exists) {
      await _db
          .ref('invite_codes/${oldSnap.value}')
          .remove();
    }

    final newCode = _generateCode();
    await _db.ref('homes/$houseId/settings/invite_code').set(newCode);
    await _db.ref('invite_codes/$newCode').set({'house_id': houseId});
  }

  /// Tạo mã mời ngẫu nhiên 8 ký tự
  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(8, (_) => chars[_rng.nextInt(chars.length)]).join();
  }

  /// Gửi log từ app
  Future<void> sendLog(String houseId, String action) async {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} '
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    await _db.ref('homes/$houseId/logs').push().set({
      'user': currentUser?.email ?? 'App User',
      'method': 'App Flutter',
      'action': action,
      'time': timeStr,
    });
  }

  /// Xóa cảnh báo bảo mật
  Future<void> clearSecurityAlert(String houseId) async {
    await _db.ref('homes/$houseId/alerts/security').remove();
  }
}
