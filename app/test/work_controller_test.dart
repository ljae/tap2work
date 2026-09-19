import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:tap2work/domain/lesson.dart';
import 'package:tap2work/state/work_controller.dart';

class MemoryStore implements ProgressStore {
  String? value;
  bool fail = false;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String input) async {
    if (fail) throw StateError('device storage unavailable');
    value = input;
  }
}

void main() {
  test(
    'practice requires worker; confirmation requires buddy and prior practice',
    () async {
      final work = WorkController(MemoryStore());
      expect(work.approve('welcome'), isFalse);
      expect(work.practice('welcome'), isTrue);
      expect(work.approved, isEmpty);
      expect(work.approve('welcome'), isFalse);
      work.switchRole(DemoRole.buddy);
      expect(work.practice('hygiene'), isFalse);
      expect(work.approve('hygiene'), isFalse);
      expect(work.approve('welcome'), isTrue);
      expect(work.approved, {'welcome'});
      await work.saved;
    },
  );
  test(
    'all six practiced steps are not complete until buddy signs off',
    () async {
      final store = MemoryStore();
      final work = WorkController(store);
      for (final lesson in lessons) {
        work.practice(lesson.id);
      }
      expect(work.nextLesson, isNull);
      expect(work.allConfirmed, isFalse);
      work.switchRole(DemoRole.buddy);
      for (final lesson in lessons) {
        work.approve(lesson.id);
      }
      await work.saved;
      final restored = WorkController(store);
      await restored.initialize();
      expect(restored.allConfirmed, isTrue);
      expect(restored.approved.length, 6);
    },
  );
  test(
    'unknown IDs and orphan approvals cannot be restored as completed learning',
    () async {
      final store = MemoryStore()
        ..value = jsonEncode({
          'practiced': ['welcome', 'unknown'],
          'approved': ['welcome', 'hygiene', 'unknown'],
        });
      final work = WorkController(store);
      await work.initialize();
      expect(work.practiced, {'welcome'});
      expect(work.approved, {'welcome'});
      expect(work.practice('unknown'), isFalse);
    },
  );
  test(
    'help and shift state persist, then reset removes only the demo progress',
    () async {
      final store = MemoryStore();
      final work = WorkController(store);
      work.requestHelp();
      work.confirmShift();
      expect(work.resolveHelp(), isFalse);
      await work.saved;
      final restored = WorkController(store);
      await restored.initialize();
      expect(restored.helpRequested, isTrue);
      expect(restored.shiftConfirmed, isTrue);
      restored.switchRole(DemoRole.buddy);
      expect(restored.resolveHelp(), isTrue);
      restored.reset();
      await restored.saved;
      final reset = WorkController(store);
      await reset.initialize();
      expect(reset.role, DemoRole.worker);
      expect(reset.helpRequested, isFalse);
      expect(reset.shiftConfirmed, isFalse);
    },
  );
  test('storage failure is visible and a later save can recover', () async {
    final store = MemoryStore()..fail = true;
    final work = WorkController(store);
    work.practice('welcome');
    await work.saved;
    expect(work.storageWarning, isNotNull);
    store.fail = false;
    work.confirmShift();
    await work.saved;
    expect(work.storageWarning, isNull);
    expect(jsonDecode(store.value!)['practiced'], ['welcome']);
  });
}
