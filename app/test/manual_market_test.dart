import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/data/checklist_backup_repository.dart';
import 'package:tap2work/ui/manual_market_screen.dart';
import 'package:tap2work/ui/manual_tap_editor.dart';
import 'package:tap2work/ui/checklist_backup_screen.dart';
import 'package:tap2work/ui/components.dart';
import 'manual_workspace_test.dart' show directoryData;
import 'operations_test.dart' show response;

Json fixture() {
  final data = directoryData();
  data['workspaceId'] = 'store-one';
  data['manualCatalog'] = {
    'releaseId': 'release-one',
    'entries': [
      for (var i = 0; i < 2; i++)
        {
          'sourceId': 'common/$i',
          'title': '공용 TAP $i',
          'collectionName': '공통',
          'reviewedAt': '2026-10-04',
          'basis': '운영 제안',
          'steps': [
            {'id': 'one', 'title': '확인', 'manual': '확인 방법', 'tip': '확인 팁'},
          ],
          'installed': i == 0
              ? []
              : [
                  {'templateId': 'a', 'mode': 'linked'},
                ],
        },
    ],
  };
  data['catalogLinks'] = {
    'a': {'mode': 'linked'},
  };
  data['checklistBackup'] = {
    'format': 'tap2work-checklists',
    'schemaVersion': 1,
    'folders': data['checklistFolders'],
    'templates': [data['taskTemplates'][1]],
  };
  return data;
}

class FakeBackup extends ChecklistBackupRepository {
  String? value, exported, scope;
  bool fail = false;
  @override
  Future<String?> read(String scope) async => value;
  @override
  Future<void> save(String scope, String value) async {
    if (fail) throw StateError('storage full');
    this.scope = scope;
    this.value = value;
  }

  @override
  Future<bool> export(String value) async {
    exported = value;
    return true;
  }

  @override
  Future<String?> pick() async => value;
}

Future<void> mount(
  WidgetTester tester,
  OperationsController ops,
  Widget screen, {
  double width = 390,
  double scale = 1,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await ops.refresh();
  await tester.pumpWidget(
    MaterialApp(
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showAppSheet(context, builder: (_) => screen),
            child: const Text('열기'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'market selects only new source and sends pinned release/revision',
    (tester) async {
      Json? sent;
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') sent = jsonDecode(r.body);
          return response(fixture());
        }),
      );
      addTearDown(ops.dispose);
      await mount(tester, ops, ManualMarketScreen(ops: ops));
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox).last).onChanged,
        isNull,
      );
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('담은 1개 확인'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('선택한 1개 가져오기'));
      await tester.pumpAndSettle();
      expect(sent?['folderMode'], 'purpose');
      expect(sent?['action'], 'import_market_taps');
      expect(sent?['releaseId'], 'release-one');
      expect(sent?['revision'], 2);
      expect(sent?['sourceIds'], ['common/0']);
      expect(find.text('매뉴얼 마켓'), findsNothing);
    },
  );
  testWidgets(
    'TAP details save title, reordered Tasks and unchanged manual content',
    (tester) async {
      Json? sent;
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') sent = jsonDecode(r.body);
          return response(fixture());
        }),
      );
      addTearDown(ops.dispose);
      await mount(
        tester,
        ops,
        ManualTapEditor(ops: ops, templateId: 'a'),
        width: 1200,
      );
      expect(find.textContaining('공용 업데이트 대신 백업'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('manual-tap-title')),
        '개인화 위생',
      );
      await tester.ensureVisible(find.byTooltip('아래로').first);
      await tester.tap(find.byTooltip('아래로').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('매뉴얼 저장'));
      await tester.pumpAndSettle();
      expect(sent?['action'], 'save_manual_tap');
      expect(sent?['templateId'], 'a');
      expect(sent?['title'], '개인화 위생');
      expect(sent?['steps'][0]['id'], 's2');
      expect(sent?['steps'][1]['manual'], '손 씻기 상세 매뉴얼');
      expect(sent?.containsKey('settings'), isFalse);
    },
  );
  testWidgets('failed TAP save retains draft and opening revision', (
    tester,
  ) async {
    Json? sent;
    final ops = OperationsController(
      client: MockClient((r) async {
        if (r.method == 'POST') {
          sent = jsonDecode(r.body);
          return response({'error': '동료가 수정했어요'}, 409);
        }
        return response(fixture());
      }),
    );
    addTearDown(ops.dispose);
    await mount(tester, ops, ManualTapEditor(ops: ops, templateId: 'a'));
    await tester.enterText(
      find.byKey(const ValueKey('manual-tap-title')),
      '저장할 초안',
    );
    ops.data!['revision'] = 99;
    await tester.tap(find.text('매뉴얼 저장'));
    await tester.pumpAndSettle();
    expect(find.text('저장할 초안'), findsOneWidget);
    expect(find.textContaining('동료가 수정했어요'), findsWidgets);
    expect(sent?['revision'], 2);
  });
  testWidgets(
    'device backup, file export and restore preserve payload and reset context',
    (tester) async {
      Json? sent;
      final repo = FakeBackup();
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') sent = jsonDecode(r.body);
          return response(fixture());
        }),
      );
      addTearDown(ops.dispose);
      await mount(
        tester,
        ops,
        ChecklistBackupScreen(ops: ops, repository: repo),
        width: 1200,
      );
      await tester.tap(find.text('이 기기에 백업'));
      await tester.pumpAndSettle();
      expect(repo.scope, 'store-one/owner');
      expect(jsonDecode(repo.value!)['templates'].length, 1);
      await tester.tap(find.text('백업 파일 내보내기'));
      await tester.pumpAndSettle();
      expect(repo.exported, repo.value);
      await tester.tap(find.text('백업 파일 선택'));
      await tester.pumpAndSettle();
      expect(find.text('복원할 TAP 1개'), findsOneWidget);
      await tester.ensureVisible(find.text('개인화 사본으로 추가 복원'));
      await tester.tap(find.text('개인화 사본으로 추가 복원'));
      await tester.pumpAndSettle();
      expect(sent?['action'], 'restore_checklist_backup');
      expect(sent?['revision'], 2);
      expect(sent?['backup'], jsonDecode(repo.value!));
      expect(find.text('복원할 TAP 1개'), findsNothing);
    },
  );
  testWidgets(
    'invalid backup and failed storage do not produce success or writes',
    (tester) async {
      int writes = 0;
      final repo = FakeBackup()
        ..fail = true
        ..value =
            '{"format":"tap2work-checklists","schemaVersion":1,"folders":[],"templates":[null]}';
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') writes++;
          return response(fixture());
        }),
      );
      addTearDown(ops.dispose);
      await mount(
        tester,
        ops,
        ChecklistBackupScreen(ops: ops, repository: repo),
      );
      await tester.tap(find.text('이 기기에 백업'));
      await tester.pumpAndSettle();
      expect(find.textContaining('처리하지 못했어요'), findsOneWidget);
      await tester.tap(find.text('백업 파일 선택'));
      await tester.pumpAndSettle();
      expect(find.text('개인화 사본으로 추가 복원'), findsNothing);
      expect(writes, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('new TAP Task draft is applied before one shared save', (
    tester,
  ) async {
    Json? sent;
    final ops = OperationsController(
      client: MockClient((r) async {
        if (r.method == 'POST') sent = jsonDecode(r.body);
        return response(fixture());
      }),
    );
    addTearDown(ops.dispose);
    await mount(tester, ops, ManualTapEditor(ops: ops));
    await tester.enterText(
      find.byKey(const ValueKey('manual-tap-title')),
      '자체 점검',
    );
    await tester.ensureVisible(find.text('Task 추가'));
    await tester.tap(find.text('Task 추가'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Task 이름'),
      '상태 확인',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '간단 매뉴얼 · 방법과 완료 기준'),
      '매장 기준으로 확인해요.',
    );
    await tester.tap(find.text('초안에 적용'));
    await tester.pumpAndSettle();
    expect(sent, isNull);
    await tester.tap(find.text('매뉴얼 저장'));
    await tester.pumpAndSettle();
    expect(sent?['action'], 'save_manual_tap');
    expect(sent?['templateId'], isNull);
    expect(sent?['steps'][0]['manual'], '매장 기준으로 확인해요.');
  });
  testWidgets('changing workspace while editor is open cannot send old draft', (
    tester,
  ) async {
    int writes = 0;
    final ops = OperationsController(
      client: MockClient((r) async {
        if (r.method == 'POST') writes++;
        return response(fixture());
      }),
    );
    addTearDown(ops.dispose);
    await mount(tester, ops, ManualTapEditor(ops: ops, templateId: 'a'));
    await tester.enterText(
      find.byKey(const ValueKey('manual-tap-title')),
      '다른 매장에 저장 금지',
    );
    ops.data!['workspaceId'] = 'store-two';
    await tester.tap(find.text('매뉴얼 저장'));
    await tester.pumpAndSettle();
    expect(writes, 0);
  });
  for (final width in [320.0, 390.0, 1200.0]) {
    for (final screen in ['market', 'editor', 'backup']) {
      testWidgets('$screen fits $width with enlarged text', (tester) async {
        final ops = OperationsController(
          client: MockClient((r) async => response(fixture())),
        );
        addTearDown(ops.dispose);
        await mount(
          tester,
          ops,
          switch (screen) {
            'market' => ManualMarketScreen(ops: ops),
            'editor' => ManualTapEditor(ops: ops, templateId: 'a'),
            _ => ChecklistBackupScreen(ops: ops, repository: FakeBackup()),
          },
          width: width,
          scale: 1.3,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
