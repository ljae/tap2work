import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/manual_workspace.dart';
import 'package:tap2work/ui/direct_edit.dart';
import 'operations_test.dart' show sample, response;

Json directoryData() {
  final data = sample();
  data['checklistFolders'] = [
    {'id': 'general', 'name': '오픈'},
    {'id': 'close', 'name': '마감'},
  ];
  data['taskTemplates'] = [
    for (final id in ['a', 'b'])
      {
        'id': id,
        'title': id == 'a' ? '위생 TAP' : '정리 TAP',
        'folderId': id == 'a' ? 'general' : 'close',
        'steps': [
          for (final step in id == 'a' ? ['s1', 's2'] : ['s3'])
            {
              'id': step,
              'title': {'s1': '손 씻기', 's2': '소독', 's3': '청소'}[step],
              'manual':
                  '${{'s1': '손 씻기', 's2': '소독', 's3': '청소'}[step]} 상세 매뉴얼',
              'tip': '안전 확인',
              'tags': ['공통'],
            },
        ],
      },
  ];
  data['manualSearch'] = [
    for (final item in [
      ('a', 's1', '손 씻기', 'general', '오픈'),
      ('a', 's2', '소독', 'general', '오픈'),
      ('b', 's3', '청소', 'close', '마감'),
    ])
      {
        'id': '${item.$1}/${item.$2}',
        'tapId': item.$1,
        'templateId': item.$1,
        'sourceStepId': item.$2,
        'folderId': item.$4,
        'folderName': item.$5,
        'tapTitle': item.$1 == 'a' ? '위생 TAP' : '정리 TAP',
        'title': item.$3,
        'manual': '${item.$3} 상세 매뉴얼',
        'tip': '안전 확인',
        'tags': ['공통'],
        'editable': true,
        'estimatedMinutes': item.$2 == 's1'
            ? 5
            : item.$2 == 's2'
            ? 10
            : null,
      },
  ];
  return data;
}

Future<void> mount(
  WidgetTester tester,
  OperationsController ops, {
  double width = 1200,
  String query = '',
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await ops.refresh();
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: Scaffold(
        body: ManualWorkspace(ops: ops, query: query),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> click(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

Future<void> moveTask(WidgetTester tester) async {
  await click(tester, 'manual-node-tap:a');
  await tester.longPress(
    find.byKey(const ValueKey('manual-node-group:general')),
  );
  await tester.pumpAndSettle();
  final start = tester.getCenter(
    find.byKey(const ValueKey('manual-drag-task:s1:a')),
  );
  final end = tester.getCenter(find.byKey(const ValueKey('manual-node-tap:b')));
  await tester.dragFrom(start, end - start);
  await tester.pumpAndSettle();
}

void main() {
  for (final entry in [
    ('group', 'general', null),
    ('tap', 'a', null),
    ('task', 's1', 'a'),
  ]) {
    testWidgets(
      'crew can read store recipes through manual index without template access',
      (tester) async {
        final data = directoryData();
        data.remove('taskTemplates');
        data['actor'] = {'id': 'crew', 'role': 'crew', 'name': '크루'};
        data['canEditTasks'] = false;
        for (final row in data['manualSearch'] as List) {
          if (row['templateId'] == 'a') row['menuManualId'] = 'menu';
        }
        final ops = OperationsController(
          client: MockClient((_) async => response(data)),
        );
        addTearDown(ops.dispose);
        await mount(tester, ops);
        await tester.tap(find.text('메뉴·레시피'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('store-recipe-a')));
        await tester.pumpAndSettle();
        expect(find.text('손 씻기 상세 매뉴얼'), findsOneWidget);
        expect(find.text('매뉴얼 저장'), findsNothing);
        expect(find.text('판매 메뉴 추가·관리'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('tree name click renames ${entry.$1} with exact identity', (
      tester,
    ) async {
      Json? sent;
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') sent = jsonDecode(r.body) as Json;
          return response(directoryData());
        }),
      );
      addTearDown(ops.dispose);
      await mount(tester, ops);
      await click(tester, 'manual-node-tap:a');
      final id =
          '${entry.$1}:${entry.$2}${entry.$3 == null ? '' : ':${entry.$3}'}';
      await tester.longPress(find.byKey(ValueKey('manual-rename-$id')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('manual-rename-$id')));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, '이름'), '새 이름');
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();
      expect(sent?['action'], 'edit_manual_node');
      expect(sent?['operation'], 'rename');
      expect(sent?['kind'], entry.$1);
      expect(sent?['id'], entry.$2);
      expect(sent?['parentId'], entry.$3);
      expect(sent?['name'], '새 이름');
      expect(sent?['revision'], 2);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'menu recipes are separate from operations and preserve menu identity',
    (tester) async {
      Json? sent;
      final data = directoryData();
      data['taskTemplates'][0]['menuManualId'] = 'menu-1';
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') sent = jsonDecode(r.body) as Json;
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await mount(tester, ops);
      expect(find.byKey(const ValueKey('manual-node-tap:a')), findsNothing);
      await tester.tap(find.text('메뉴·레시피'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('store-recipe-a')));
      await tester.pumpAndSettle();
      expect(find.text('파트·시간대·TAP 운영 설정'), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('manual-tap-title')),
        '우리 조리 기준',
      );
      await tester.tap(find.text('매뉴얼 저장'));
      await tester.pumpAndSettle();
      expect(sent?['action'], 'save_manual_tap');
      expect(sent?['templateId'], 'a');
      expect(sent?['title'], '위생 TAP');
      expect(sent?['manualTitle'], '우리 조리 기준');
      expect(sent?['revision'], 2);
    },
  );

  testWidgets(
    'empty folders and TAPs remain editable and accept the last Task',
    (tester) async {
      final data = directoryData();
      (data['checklistFolders'] as List).add({'id': 'empty', 'name': '빈 폴더'});
      (data['taskTemplates'] as List).add({
        'id': 'c',
        'title': '빈 TAP',
        'folderId': 'general',
        'steps': [],
      });
      var posts = 0;
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((r) async {
          if (r.method == 'POST') posts++;
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await mount(tester, ops);
      expect(find.byKey(const ValueKey('manual-node-tap:c')), findsOneWidget);
      await tester.longPress(find.byKey(const ValueKey('manual-node-tap:c')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('manual-actions-tap:c')));
      await tester.pumpAndSettle();
      expect(find.text('Task 추가'), findsOneWidget);
      expect(find.text('상세 수정'), findsOneWidget);
      expect(find.text('이름 변경'), findsOneWidget);
      expect(find.text('삭제'), findsOneWidget);
      await tester.tapAt(const Offset(1100, 20));
      await tester.pumpAndSettle();
      await click(tester, 'manual-node-tap:b');
      final start = tester.getCenter(
        find.byKey(const ValueKey('manual-drag-task:s3:b')),
      );
      final end = tester.getCenter(
        find.byKey(const ValueKey('manual-node-tap:c')),
      );
      await tester.dragFrom(start, end - start);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('manual-node-tap:b')), findsOneWidget);
      await click(tester, 'manual-node-tap:c');
      expect(
        find.byKey(const ValueKey('manual-node-task:s3:c')),
        findsOneWidget,
      );
      await tester.longPress(
        find.byKey(const ValueKey('manual-node-group:empty')),
      );
      await tester.pumpAndSettle();
      await click(tester, 'manual-actions-group:empty');
      expect(find.text('TAP 추가'), findsOneWidget);
      expect(posts, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('editing keeps tree rows compact and isolates the two panes', (
    tester,
  ) async {
    final ops = OperationsController(
      readOnly: true,
      client: MockClient((_) async => response(directoryData())),
    );
    addTearDown(ops.dispose);
    await mount(tester, ops);
    await click(tester, 'manual-node-tap:a');
    final task = find.byKey(const ValueKey('manual-node-task:s1:a'));
    final height = tester.getSize(task).height;
    await tester.longPress(task);
    await tester.pumpAndSettle();
    DirectEditFrame frame(String key) =>
        tester.widget<DirectEditFrame>(find.byKey(ValueKey(key)));
    expect(frame('manual-tree-frame-task:s1:a').active, isTrue);
    expect(frame('manual-tree-frame-task:s1:a').controls, isFalse);
    expect(frame('manual-tree-frame-task:s1:a').outline, isFalse);
    expect(frame('manual-content-frame-a/s1').active, isFalse);
    expect(tester.getSize(task).height, height);
    expect(
      tester.getTopLeft(task).dx,
      greaterThan(
        tester.getTopLeft(find.byKey(const ValueKey('manual-node-tap:a'))).dx,
      ),
    );
    await tester.tap(task);
    await tester.pumpAndSettle();
    expect(find.text('손 씻기 상세 매뉴얼'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('manual-actions-task:s1:a')));
    await tester.pumpAndSettle();
    expect(find.text('이름 변경'), findsOneWidget);
    expect(find.text('삭제'), findsOneWidget);
    await tester.tapAt(const Offset(1100, 20));
    await tester.pumpAndSettle();
    await tester.longPress(
      find.descendant(
        of: find.byKey(const ValueKey('manual-results')),
        matching: find.text('손 씻기'),
      ),
    );
    await tester.pumpAndSettle();
    expect(frame('manual-tree-frame-task:s1:a').active, isFalse);
    expect(frame('manual-content-frame-a/s1').active, isTrue);
    expect(
      find.byKey(const ValueKey('manual-actions-task:s1:a')),
      findsNothing,
    );
    expect(find.byTooltip('이름 변경'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'dropping Task on folder selects a child TAP without flattening hierarchy',
    (tester) async {
      var posts = 0;
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((r) async {
          if (r.method == 'POST') posts++;
          return response(directoryData());
        }),
      );
      addTearDown(ops.dispose);
      await mount(tester, ops);
      await click(tester, 'manual-node-tap:a');
      await tester.longPress(
        find.byKey(const ValueKey('manual-node-task:s1:a')),
      );
      await tester.pumpAndSettle();
      final start = tester.getCenter(
        find.byKey(const ValueKey('manual-drag-task:s1:a')),
      );
      final end = tester.getCenter(
        find.byKey(const ValueKey('manual-node-group:close')),
      );
      await tester.dragFrom(start, end - start);
      await tester.pumpAndSettle();
      expect(find.text('이 폴더의 TAP 선택'), findsOneWidget);
      await tester.tap(find.text('마감 / 정리 TAP · 맨 아래'));
      await tester.pumpAndSettle();
      await click(tester, 'manual-node-tap:b');
      expect(
        find.byKey(const ValueKey('manual-node-task:s1:b')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('manual-node-task:s1:a')), findsNothing);
      expect(posts, 0);
    },
  );

  testWidgets('phone tree edit menu fits and pane switch ends editing', (
    tester,
  ) async {
    final ops = OperationsController(
      readOnly: true,
      client: MockClient((_) async => response(directoryData())),
    );
    addTearDown(ops.dispose);
    await mount(tester, ops, width: 320);
    await click(tester, 'manual-node-tap:a');
    await tester.longPress(find.byKey(const ValueKey('manual-node-task:s1:a')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('매뉴얼 2'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<DirectEditFrame>(
            find.byKey(const ValueKey('manual-content-frame-a/s1')),
          )
          .active,
      isFalse,
    );
    expect(find.text('편집 완료'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Task manual edit opens exact step and previews without POST', (
    tester,
  ) async {
    var posts = 0;
    final ops = OperationsController(
      readOnly: true,
      client: MockClient((request) async {
        if (request.method == 'POST') posts++;
        return response(directoryData());
      }),
    );
    addTearDown(ops.dispose);
    await mount(tester, ops);
    await click(tester, 'manual-node-tap:a');
    await click(tester, 'manual-node-task:s1:a');
    await tester.tap(find.text('매뉴얼 편집'));
    await tester.pumpAndSettle();
    expect(find.text('보드 편집'), findsNothing);
    expect(find.text('매뉴얼 저장'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, '간단 매뉴얼 · 방법과 완료 기준'),
      '손을 충분히 씻어요',
    );
    await tester.tap(find.text('매뉴얼 저장'));
    await tester.pumpAndSettle();
    expect(ops.rows('taskTemplates').first['steps'][0]['manual'], '손을 충분히 씻어요');
    expect(ops.rows('taskTemplates').first['steps'][1]['manual'], '소독 상세 매뉴얼');
    expect(find.text('손을 충분히 씻어요'), findsOneWidget);
    expect(posts, 0);
  });

  testWidgets('Task manual save targets one step with opening revision', (
    tester,
  ) async {
    Json? sent;
    final ops = OperationsController(
      client: MockClient((request) async {
        if (request.method == 'POST') {
          sent = jsonDecode(request.body) as Json;
          return response(directoryData());
        }
        return response(directoryData());
      }),
    );
    addTearDown(ops.dispose);
    await mount(tester, ops);
    await click(tester, 'manual-node-tap:a');
    await click(tester, 'manual-node-task:s1:a');
    await tester.tap(find.text('매뉴얼 편집'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, '간단 매뉴얼 · 방법과 완료 기준'),
      '손을 충분히 씻어요',
    );
    await tester.tap(find.text('매뉴얼 저장'));
    await tester.pumpAndSettle();
    expect(sent?['action'], 'save_manual_tap');
    expect(sent?['templateId'], 'a');
    expect(sent?['revision'], 2);
    expect(sent?['steps'][0]['manual'], '손을 충분히 씻어요');
    expect(sent?['steps'][1]['manual'], '소독 상세 매뉴얼');
    expect(sent?.containsKey('templates'), isFalse);
  });

  testWidgets(
    'Linked manual body save preserves display alias and source title',
    (tester) async {
      final data = directoryData();
      data['taskTemplates'][0]['menuManualId'] = 'menu';
      data['taskTemplates'][0]['manualTitle'] = '조리 가이드';
      data['taskTemplates'][0]['steps'][0]['manualTitle'] = '완성 순서';
      Json? sent;
      final ops = OperationsController(
        client: MockClient((request) async {
          if (request.method == 'POST') {
            sent = jsonDecode(request.body) as Json;
            return response(data);
          }
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await mount(tester, ops);
      await tester.tap(find.text('메뉴·레시피'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('store-recipe-a')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Task 상세 수정').first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, '간단 매뉴얼 · 방법과 완료 기준'),
        '손을 충분히 씻어요',
      );
      await tester.tap(find.text('초안에 적용'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('매뉴얼 저장'));
      await tester.pumpAndSettle();
      expect(sent?['title'], '위생 TAP');
      expect(sent?['steps'][0]['manualTitle'], '완성 순서');
      expect(sent?['steps'][0]['title'], '손 씻기');
      expect(sent?['action'], 'save_manual_tap');
      expect(sent?['templateId'], 'a');
      expect(sent?['revision'], 2);
      expect(sent?['steps'][0]['manual'], '손을 충분히 씻어요');
      expect(sent?['steps'][1]['manual'], '소독 상세 매뉴얼');
      expect(sent?.containsKey('templates'), isFalse);
    },
  );

  testWidgets('directory filters search by group and opens a Task manual', (
    tester,
  ) async {
    final ops = OperationsController(
      readOnly: true,
      client: MockClient((_) async => response(directoryData())),
    );
    addTearDown(ops.dispose);
    await mount(tester, ops, query: '공통');
    await click(tester, 'manual-node-group:close');
    final results = find.byKey(const ValueKey('manual-results'));
    expect(
      find.descendant(of: results, matching: find.text('청소')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: results, matching: find.text('손 씻기')),
      findsNothing,
    );
    await click(tester, 'manual-node-task:s3:b');
    expect(find.text('청소 상세 매뉴얼'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Task cards show only duration and TAP tree sums configured Task times',
    (tester) async {
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((_) async => response(directoryData())),
      );
      addTearDown(ops.dispose);
      await mount(tester, ops);
      await click(tester, 'manual-node-tap:a');
      expect(find.text('약 15분'), findsOneWidget);
      final results = find.byKey(const ValueKey('manual-results'));
      expect(
        find.descendant(of: results, matching: find.text('약 5분')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: results, matching: find.text('오픈 / 위생 TAP')),
        findsNothing,
      );
    },
  );
  testWidgets('real drag moves Task and its manual in preview without a POST', (
    tester,
  ) async {
    var posts = 0;
    final ops = OperationsController(
      readOnly: true,
      client: MockClient((r) async {
        if (r.method == 'POST') posts++;
        return response(directoryData());
      }),
    );
    addTearDown(ops.dispose);
    await mount(tester, ops);
    await moveTask(tester);
    await click(tester, 'manual-node-tap:b');
    expect(find.byKey(const ValueKey('manual-node-task:s1:a')), findsNothing);
    await tester.tap(find.text('편집 완료'));
    await tester.pumpAndSettle();
    await click(tester, 'manual-node-task:s1:b');
    expect(find.text('손 씻기 상세 매뉴얼'), findsOneWidget);
    expect(find.text('마감 / 정리 TAP / Task'), findsOneWidget);
    expect(posts, 0);
  });
  testWidgets(
    'live drag sends opening revision and failure keeps original structure',
    (tester) async {
      Json? sent;
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') {
            sent = jsonDecode(r.body) as Json;
            return http.Response(
              jsonEncode({'error': '다른 동료가 수정했어요.'}),
              409,
              headers: {'content-type': 'application/json'},
            );
          }
          return response(directoryData());
        }),
      );
      addTearDown(ops.dispose);
      await mount(tester, ops);
      await moveTask(tester);
      expect(sent?['action'], 'move_manual_node');
      expect(sent?['revision'], 2);
      expect(sent?['sourceTapId'], 'a');
      expect(sent?['targetId'], 'b');
      expect(
        find.byKey(const ValueKey('manual-node-task:s1:a')),
        findsOneWidget,
      );
      expect(find.text('다른 동료가 수정했어요.'), findsOneWidget);
    },
  );
  testWidgets('phone tree and manual fit 320 pixels; crew cannot edit', (
    tester,
  ) async {
    final data = directoryData();
    data['actor'] = sample('crew')['actor'];
    final ops = OperationsController(
      readOnly: true,
      client: MockClient((_) async => response(data)),
    );
    addTearDown(ops.dispose);
    await mount(tester, ops, width: 320);
    expect(find.text('구조 편집'), findsNothing);
    await click(tester, 'manual-node-tap:a');
    await click(tester, 'manual-node-task:s1:a');
    expect(find.text('손 씻기 상세 매뉴얼'), findsOneWidget);
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('manual-directory')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
