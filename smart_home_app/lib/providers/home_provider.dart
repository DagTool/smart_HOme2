// lib/providers/home_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/models.dart';

class HomeProvider extends ChangeNotifier {
  final _service = FirebaseService();

  String? _houseId;
  HomeSettings _settings = const HomeSettings();
  List<Member> _members = [];
  StreamSubscription? _settingsSub;
  StreamSubscription? _membersSub;

  String? get houseId => _houseId;
  HomeSettings get settings => _settings;
  List<Member> get members => _members;

  Member? get currentMember {
    final uid = _service.uid;
    try {
      return _members.firstWhere((m) => m.uid == uid);
    } catch (_) {
      return null;
    }
  }

  bool get isAdmin => currentMember?.isAdmin ?? false;

  Future<void> loadHouseId() async {
    _houseId = await _service.getHouseId();
    if (_houseId != null) {
      _startStreams();
    }
    notifyListeners();
  }

  void setHouseId(String id) {
    _houseId = id;
    _startStreams();
    notifyListeners();
  }

  void _startStreams() {
    if (_houseId == null) return;

    _settingsSub?.cancel();
    _settingsSub = _service.settingsStream(_houseId!).listen((s) {
      _settings = s;
      notifyListeners();
    });

    _membersSub?.cancel();
    _membersSub = _service.membersStream(_houseId!).listen((m) {
      _members = m;
      notifyListeners();
    });
  }

  Future<String> createHome(String name, String displayName) async {
    final id = await _service.createHome(name, displayName);
    setHouseId(id);
    return id;
  }

  Future<bool> joinHome(String code, String displayName) async {
    final id = await _service.joinHomeByCode(code, displayName);
    if (id != null) {
      setHouseId(id);
      return true;
    }
    return false;
  }

  Future<void> removeMember(String memberUid) async {
    if (_houseId == null) return;
    await _service.removeMember(_houseId!, memberUid);
  }

  Future<void> regenerateCode() async {
    if (_houseId == null) return;
    await _service.regenerateInviteCode(_houseId!);
  }

  @override
  void dispose() {
    _settingsSub?.cancel();
    _membersSub?.cancel();
    super.dispose();
  }
}
