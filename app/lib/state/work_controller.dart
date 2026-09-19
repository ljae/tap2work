import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/lesson.dart';

enum DemoRole { worker, buddy }

abstract interface class ProgressStore {
  Future<String?> read();
  Future<void> write(String value);
}

class DeviceProgressStore implements ProgressStore {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  static const key = 'tab2work.flutter.demo.v1';
  @override
  Future<String?> read() => _preferences.getString(key);
  @override
  Future<void> write(String value) => _preferences.setString(key, value);
}

class WorkController extends ChangeNotifier {
  WorkController(this.store);
  final ProgressStore store;
  DemoRole _role = DemoRole.worker;
  final Set<String> _practiced = {};
  final Set<String> _approved = {};
  bool _helpRequested = false;
  bool _shiftConfirmed = false;
  String? storageWarning;
  Future<void> _writes = Future.value();
  bool _disposed = false;

  DemoRole get role => _role;
  Set<String> get practiced => Set.unmodifiable(_practiced);
  Set<String> get approved => Set.unmodifiable(_approved);
  bool get helpRequested => _helpRequested;
  bool get shiftConfirmed => _shiftConfirmed;
  bool get allConfirmed => _approved.length == lessons.length;
  Future<void> get saved => _writes;
  Lesson? get nextLesson {
    for (final lesson in lessons) {
      if (!_practiced.contains(lesson.id)) return lesson;
    }
    return null;
  }

  Future<void> initialize() async {
    try {
      final raw = await store.read();
      if (raw == null) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final known = lessons.map((lesson) => lesson.id).toSet();
      final practice = data['practiced'];
      final approval = data['approved'];
      if (practice is List) {
        _practiced.addAll(practice.whereType<String>().where(known.contains));
      }
      if (approval is List) {
        _approved.addAll(
          approval.whereType<String>().where(_practiced.contains),
        );
      }
      _role = data['role'] == 'buddy' ? DemoRole.buddy : DemoRole.worker;
      _helpRequested = data['helpRequested'] == true;
      _shiftConfirmed = data['shiftConfirmed'] == true;
    } catch (_) {
      storageWarning = '이 기기의 이전 기록을 읽지 못했어요. 새 체험으로 시작해요.';
    }
    _notify();
  }

  void switchRole(DemoRole role) {
    _role = role;
    _persist();
  }

  bool practice(String id) {
    if (_role != DemoRole.worker || !lessons.any((lesson) => lesson.id == id)) {
      return false;
    }
    if (_practiced.add(id)) _persist();
    return true;
  }

  bool approve(String id) {
    if (_role != DemoRole.buddy || !_practiced.contains(id)) return false;
    if (_approved.add(id)) _persist();
    return true;
  }

  void requestHelp() {
    _helpRequested = true;
    _persist();
  }

  bool resolveHelp() {
    if (_role != DemoRole.buddy) return false;
    _helpRequested = false;
    _persist();
    return true;
  }

  void confirmShift() {
    _shiftConfirmed = true;
    _persist();
  }

  void reset() {
    _role = DemoRole.worker;
    _practiced.clear();
    _approved.clear();
    _helpRequested = false;
    _shiftConfirmed = false;
    _persist();
  }

  String status(Lesson lesson) => _approved.contains(lesson.id)
      ? '버디와 함께 확인했어요'
      : _practiced.contains(lesson.id)
      ? '같이 해봤어요 · 버디 확인 대기'
      : lesson.subtitle;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _persist() {
    final value = jsonEncode({
      'role': _role.name,
      'practiced': _practiced.toList(),
      'approved': _approved.toList(),
      'helpRequested': _helpRequested,
      'shiftConfirmed': _shiftConfirmed,
    });
    _notify();
    _writes = _writes.then((_) async {
      try {
        await store.write(value);
        if (storageWarning != null) {
          storageWarning = null;
          _notify();
        }
      } catch (_) {
        storageWarning = '기기에 저장하지 못했어요. 앱을 닫으면 진행 기록이 사라질 수 있어요.';
        _notify();
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
