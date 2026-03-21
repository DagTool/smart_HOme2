// lib/providers/device_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/models.dart';

class DeviceProvider extends ChangeNotifier {
  final _service = FirebaseService();

  String? _houseId;
  DeviceState _state = const DeviceState();
  List<LogEntry> _logs = [];
  StreamSubscription? _homeSub;
  StreamSubscription? _logsSub;

  bool _loading = true;
  String? _error;

  DeviceState get state => _state;
  List<LogEntry> get logs => _logs;
  bool get loading => _loading;
  String? get error => _error;

  void init(String houseId) {
    _houseId = houseId;
    _loading = true;
    notifyListeners();

    _homeSub?.cancel();
    _homeSub = _service.homeStream(houseId).listen(
      (s) {
        _state = s;
        _loading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _loading = false;
        notifyListeners();
      },
    );

    _logsSub?.cancel();
    _logsSub = _service.logsStream(houseId).listen((entries) {
      _logs = entries;
      notifyListeners();
    });
  }

  Future<void> _run(Future<void> Function() action, String logMsg) async {
    if (_houseId == null) return;
    try {
      await action();
      await _service.sendLog(_houseId!, logMsg);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleLight() => _run(
        () => _service.setLight(_houseId!, !_state.light),
        _state.light ? 'Light OFF via App' : 'Light ON via App',
      );

  Future<void> openDoor() => _run(
        () => _service.setDoor(_houseId!, true),
        'Door opened via App',
      );

  Future<void> toggleWindow() => _run(
        () => _service.setWindow(_houseId!, !_state.window),
        _state.window ? 'Window CLOSE via App' : 'Window OPEN via App',
      );

  Future<void> toggleAC() => _run(
        () => _service.setAC(_houseId!, !_state.ac),
        _state.ac ? 'AC OFF via App' : 'AC ON via App',
      );

  Future<void> changeMasterPassword(String newPass) => _run(
        () => _service.setMasterPassword(_houseId!, newPass),
        'Password changed via App',
      );

  Future<void> clearAlert() async {
    if (_houseId == null) return;
    await _service.clearSecurityAlert(_houseId!);
  }

  @override
  void dispose() {
    _homeSub?.cancel();
    _logsSub?.cancel();
    super.dispose();
  }
}
