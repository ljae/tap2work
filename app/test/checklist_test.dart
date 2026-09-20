import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/checklist_board.dart';
import 'operations_test.dart' show sample, response;

Json fixture() {
  final state = sample();
  final template = {
    'id': 'prep',
    'title': '전처리 준비',
    'folderId': 'general',
    'version': 1,
    'slot': '준비',
    'requiredRole': 'all',
    'zone': 'prep',
    'steps': [
      {
        'id': 's1',
        'title': '도구 나누기',
        'manual': '생재료와 완성식품 도구를 따로 놓아요.',
        'tip': '색상보다 용도를 확인해요.',
      },
      {
        'id': 's2',
        'title': '작업대 닦기',
        'manual': '오염을 제거하고 지정 절차대로 처리해요.',
        'tip': '제품 접촉시간을 확인해요.',
      },
    ],
    'sourceIds': <String>[],
  };
  state['checklistFolders'] = [
    {'id': 'general', 'name': '기본 업무'},
    {'id': 'close', 'name': '마감 폴더'},
  ];
  state['taskTemplates'] = [template];
  state['tasks'] = [
    {
      ...template,
      'id': 'daily-prep',
      'templateId': 'prep',
      'kind': 'routine',
      'emoji': '🥣',
      'canComplete': true,
      'completedAt': null,
    },
  ];
  state['checklistLibrary'] = {
    'sources': <Json>[],
    'industries': [
      {
        'id': 'cafe',
        'name': '카페·커피',
        'basis': '편집 제안',
        'tasks': [
          {...template, 'id': 'coffee', 'title': '우유 회로 관리'},
        ],
      },
    ],
  };
  return state;
}

Future<void> mount(
  WidgetTester tester,
  OperationsController ops, {
  bool editor = false,
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await ops.refresh();
  await tester.pumpWidget(
    MaterialApp(
      home: editor
          ? Builder(
              builder: (context) => Scaffold(
                body: FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ChecklistEditor(ops: ops),
                    ),
                  ),
                  child: const Text('목록 편집 시작'),
                ),
              ),
            )
          : Scaffold(
              body: AnimatedBuilder(
                animation: ops,
                builder: (_, _) => SingleChildScrollView(
                  child: ChecklistBoard(ops: ops, onStock: (_) async {}),
                ),
              ),
            ),
    ),
  );
  await tester.pumpAndSettle();
  if (editor) {
    await tester.tap(find.text('목록 편집 시작'));
    await tester.pumpAndSettle();
  }
}

void main() {
  for (final width in [320.0, 390.0, 1440.0]) {
    testWidgets('manual and folders remain readable at $width px', (
      tester,
    ) async {
      final ops = OperationsController(
        client: MockClient((_) async => response(fixture())),
      );
      addTearDown(ops.dispose);
      await mount(tester, ops, width: width);
      await tester.ensureVisible(find.text('🥣 전처리 준비'));
      await tester.tap(find.text('🥣 전처리 준비'));
      await tester.pumpAndSettle();
      expect(find.text('생재료와 완성식품 도구를 따로 놓아요.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('폴더 보기'));
      await tester.tap(find.text('폴더 보기'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.folder_outlined), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('manual action submits one step and shows shared attribution', (
    tester,
  ) async {
    final data = fixture();
    Json? submitted;
    final ops = OperationsController(
      client: MockClient((request) async {
        if (request.method == 'POST') {
          submitted = jsonDecode(request.body) as Json;
          (data['tasks'][0]['steps'][0] as Json).addAll({
            'completedAt': '2026-09-20T01:00:00Z',
            'completedBy': {'name': '민지'},
          });
        }
        return response(data);
      }),
    );
    addTearDown(ops.dispose);
    await mount(tester, ops);
    await tester.ensureVisible(find.text('🥣 전처리 준비'));
    await tester.tap(find.text('🥣 전처리 준비'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('행위 1 확인'));
    await tester.tap(find.text('행위 1 확인'));
    await tester.pumpAndSettle();
    expect(submitted?['action'], 'complete_step');
    expect(submitted?['stepId'], 's1');
    expect(find.text('✓ 민지 · 10:00'), findsOneWidget);
  });
  testWidgets('folder drag retains opening revision and conflict keeps draft', (
    tester,
  ) async {
    Json? submitted;
    var latest = 2;
    final ops = OperationsController(
      client: MockClient((request) async {
        if (request.method == 'POST') {
          submitted = jsonDecode(request.body) as Json;
          return response({'error': '다른 사람이 수정했어요'}, 409);
        }
        return response({...fixture(), 'revision': latest});
      }),
    );
    addTearDown(ops.dispose);
    await mount(tester, ops, editor: true, width: 900);
    final card = find.text('전처리 준비');
    final folder = find.text('마감 폴더 · 0');
    await tester.ensureVisible(card);
    final gesture = await tester.startGesture(tester.getCenter(card));
    await tester.pump(const Duration(milliseconds: 700));
    await gesture.moveTo(tester.getCenter(folder));
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('마감 폴더 · 1'), findsOneWidget);
    latest = 7;
    await ops.refresh();
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(submitted?['revision'], 2);
    expect(submitted?['templates'][0]['folderId'], 'close');
    expect(find.text('마감 폴더 · 1'), findsOneWidget);
    expect(find.textContaining('초안은 그대로'), findsOneWidget);
  });
  testWidgets('owner edits manual and removes action in isolated draft', (
    tester,
  ) async {
    Json? submitted;
    final ops = OperationsController(
      client: MockClient((request) async {
        if (request.method == 'POST') {
          submitted = jsonDecode(request.body) as Json;
        }
        return response(fixture());
      }),
    );
    addTearDown(ops.dispose);
    await mount(tester, ops, editor: true, width: 900);
    await tester.ensureVisible(find.text('매뉴얼 열기 · 수정'));
    await tester.tap(find.text('매뉴얼 열기 · 수정'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, '업무 이름'),
      '내 매장 준비',
    );
    final manual = find
        .widgetWithText(TextFormField, '간단 매뉴얼 · 방법과 완료 기준')
        .first;
    await tester.ensureVisible(manual);
    await tester.enterText(manual, '우리 매장 도구함에서 꺼내 확인해요.');
    final remove = find.byTooltip('행위 삭제').last;
    await tester.ensureVisible(remove);
    await tester.tap(remove);
    await tester.pumpAndSettle();
    await tester.tap(find.text('초안에 적용'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(submitted?['templates'][0]['title'], '내 매장 준비');
    expect(submitted?['templates'][0]['steps'], hasLength(1));
    expect(
      submitted?['templates'][0]['steps'][0]['manual'],
      '우리 매장 도구함에서 꺼내 확인해요.',
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('public library can be explored but never saved', (tester) async {
    var posts = 0;
    final ops = OperationsController(
      readOnly: true,
      client: MockClient((request) async {
        if (request.method == 'POST') posts++;
        return response(fixture());
      }),
    );
    addTearDown(ops.dispose);
    await mount(tester, ops, editor: true);
    await tester.tap(find.text('업종별 기본 목록'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('카페·커피'));
    await tester.pumpAndSettle();
    final import = find.text('선택한 1개 업무 가져오기');
    await tester.ensureVisible(import);
    await tester.tap(import);
    await tester.pumpAndSettle();
    expect(find.text('카페·커피 · 1'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, '저장'))
          .onPressed,
      isNull,
    );
    expect(posts, 0);
  });
  testWidgets('an off-screen empty manual cannot be applied', (tester) async {
    final data = fixture();
    data['taskTemplates'][0]['steps'] = [
      for (var i = 1; i <= 30; i++)
        {
          'id': 'step-$i',
          'title': '행위 $i',
          'manual': i == 30 ? '' : '방법과 결과를 확인해요.',
          'tip': '',
        },
    ];
    final ops = OperationsController(
      client: MockClient((_) async => response(data)),
    );
    addTearDown(ops.dispose);
    await mount(tester, ops, editor: true, width: 900);
    await tester.ensureVisible(find.text('매뉴얼 열기 · 수정'));
    await tester.tap(find.text('매뉴얼 열기 · 수정'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('초안에 적용'));
    await tester.pumpAndSettle();
    expect(find.text('행위 30의 매뉴얼을 1~700자로 입력해 주세요.'), findsOneWidget);
    expect(find.text('업무와 간단 매뉴얼'), findsOneWidget);
  });
  testWidgets('back navigation keeps unsaved manual edits until discarded', (
    tester,
  ) async {
    final ops = OperationsController(
      client: MockClient((_) async => response(fixture())),
    );
    addTearDown(ops.dispose);
    await mount(tester, ops, editor: true, width: 900);
    await tester.ensureVisible(find.text('매뉴얼 열기 · 수정'));
    await tester.tap(find.text('매뉴얼 열기 · 수정'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, '업무 이름'),
      '편집 중인 이름',
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('매뉴얼 편집을 취소할까요?'), findsOneWidget);
    await tester.tap(find.text('계속 편집'));
    await tester.pumpAndSettle();
    expect(find.text('편집 중인 이름'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('변경 버리기'));
    await tester.pumpAndSettle();
    expect(find.text('전처리 준비'), findsOneWidget);
    expect(find.text('편집 중인 이름'), findsNothing);
  });
  testWidgets(
    'reimport restores missing task and preserves custom title and folder',
    (tester) async {
      final data = fixture();
      data['taskTemplates'][0]['id'] = 'library-cafe-coffee';
      data['taskTemplates'][0]['title'] = '내 매장 우유 관리';
      final industry = data['checklistLibrary']['industries'][0] as Json;
      (industry['tasks'] as List).add({
        ...industry['tasks'][0] as Json,
        'id': 'closing',
        'title': '마감 정리',
      });
      Json? submitted;
      final ops = OperationsController(
        client: MockClient((request) async {
          if (request.method == 'POST') {
            submitted = jsonDecode(request.body) as Json;
          }
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await mount(tester, ops, editor: true, width: 900);
      await tester.tap(find.text('업종별 기본 목록'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('카페·커피'));
      await tester.pumpAndSettle();
      expect(find.text('이미 목록에 있어요 · 수정 내용 유지'), findsOneWidget);
      final import = find.text('선택한 1개 업무 가져오기');
      await tester.ensureVisible(import);
      await tester.tap(import);
      await tester.pumpAndSettle();
      expect(find.text('기본 업무 · 2'), findsOneWidget);
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();
      final tasks = (submitted!['templates'] as List).cast<Json>();
      expect(
        tasks.where((t) => t['id'] == 'library-cafe-coffee').single['title'],
        '내 매장 우유 관리',
      );
      expect(
        tasks
            .where((t) => t['id'] == 'library-cafe-closing')
            .single['folderId'],
        'general',
      );
    },
  );
  testWidgets('crew cannot access checklist editing', (tester) async {
    final ops = OperationsController(
      client: MockClient(
        (_) async => response({
          ...fixture(),
          'actor': {'role': 'crew'},
          'taskTemplates': <Json>[],
        }),
      ),
    );
    addTearDown(ops.dispose);
    await mount(tester, ops);
    expect(find.text('목록 정리 · 업종 가져오기'), findsNothing);
  });
}
