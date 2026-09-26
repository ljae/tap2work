import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/checklist_board.dart';
import 'package:tap2work/ui/checklist_editor.dart';
import 'operations_test.dart' show sample, response;

Json fixture({String actor = 'owner'}) {
  final state = sample(actor);
  final template = {
    'id': 'prep',
    'title': '전처리 준비',
    'emoji': '🥣',
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
  final cookOnly = {
    ...template,
    'id': 'broth',
    'title': '육수 올리기',
    'emoji': '🍲',
    'requiredRole': 'cook',
    'steps': [
      {'id': 'b1', 'title': '솥 물량 확인', 'manual': '기준선까지 채워요.', 'tip': ''},
    ],
  };
  state['checklistFolders'] = [
    {'id': 'general', 'name': '기본 업무'},
    {'id': 'close', 'name': '마감 폴더'},
  ];
  state['taskTemplates'] = [template, cookOnly];
  state['tasks'] = [
    {
      ...template,
      'id': 'daily-prep',
      'templateId': 'prep',
      'kind': 'routine',
      'displayOrder': 0,
      'canComplete': true,
      'completedAt': null,
    },
    {
      ...cookOnly,
      'id': 'daily-broth',
      'templateId': 'broth',
      'kind': 'routine',
      'displayOrder': 1,
      'canComplete': actor == 'owner',
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
  return jsonDecode(jsonEncode(state)) as Json;
}

Future<void> mount(
  WidgetTester tester,
  OperationsController ops, {
  bool editor = false,
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width, 1400);
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

/// The round tap target left of an activity title.
Finder checkTarget(String title) => find
    .descendant(
      of: find.ancestor(of: find.text(title), matching: find.byType(Row)).first,
      matching: find.byType(InkResponse),
    )
    .first;

Future<void> longDrag(WidgetTester tester, Finder from, Finder to) async {
  final gesture = await tester.startGesture(tester.getCenter(from));
  await tester.pump(const Duration(milliseconds: 700));
  await gesture.moveTo(tester.getCenter(to));
  await tester.pump(const Duration(milliseconds: 300));
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 390.0, 1440.0]) {
    testWidgets('groups, activities and manuals stay readable at $width px', (
      tester,
    ) async {
      final ops = OperationsController(
        client: MockClient((_) async => response(fixture())),
      );
      addTearDown(ops.dispose);
      await mount(tester, ops, width: width);
      expect(find.text('오늘 활동 0 / 3 확인'), findsOneWidget);
      expect(find.text('준비 3'), findsOneWidget);
      expect(find.text('도구 나누기'), findsOneWidget);
      await tester.ensureVisible(find.text('도구 나누기'));
      await tester.tap(find.text('도구 나누기'));
      await tester.pumpAndSettle();
      expect(find.text('생재료와 완성식품 도구를 따로 놓아요.'), findsOneWidget);
      expect(find.text('💡 색상보다 용도를 확인해요.'), findsOneWidget);
      await tester.ensureVisible(find.text('전처리 준비'));
      await tester.tap(find.text('전처리 준비'));
      await tester.pumpAndSettle();
      expect(find.text('도구 나누기'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('tapping the circle confirms one activity and shows who did it', (
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
            'completedBy': {'id': 'owner', 'name': '서연'},
          });
        }
        return response(data);
      }),
    );
    addTearDown(ops.dispose);
    await mount(tester, ops);
    await tester.ensureVisible(checkTarget('도구 나누기'));
    await tester.tap(checkTarget('도구 나누기'));
    await tester.pumpAndSettle();
    expect(submitted?['action'], 'complete_step');
    expect(submitted?['stepId'], 's1');
    expect(ops.error, isNull);
    expect(find.text('서연 · 10:00 확인'), findsOneWidget);
    expect(find.text('오늘 활동 1 / 3 확인'), findsOneWidget);
  });
  testWidgets('a mis-tap can be reopened by its actor after confirmation', (
    tester,
  ) async {
    final data = fixture();
    (data['tasks'][0]['steps'][0] as Json).addAll({
      'completedAt': '2026-09-20T01:00:00Z',
      'completedBy': {'id': 'owner', 'name': '서연'},
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
    await mount(tester, ops);
    await tester.ensureVisible(checkTarget('도구 나누기'));
    await tester.tap(checkTarget('도구 나누기'));
    await tester.pumpAndSettle();
    expect(find.text('확인을 되돌릴까요?'), findsOneWidget);
    await tester.tap(find.text('그대로 두기'));
    await tester.pumpAndSettle();
    expect(submitted, isNull);
    await tester.tap(checkTarget('도구 나누기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('되돌리기'));
    await tester.pumpAndSettle();
    expect(submitted?['action'], 'reopen_step');
    expect(submitted?['stepId'], 's1');
  });
  testWidgets(
    'crew sees own filter, cannot edit, cannot tap a cook-only group or undo a colleague',
    (tester) async {
      final data = fixture(actor: 'crew');
      (data['tasks'][0]['steps'][1] as Json).addAll({
        'completedAt': '2026-09-20T01:00:00Z',
        'completedBy': {'id': 'cook', 'name': '현우'},
      });
      var posts = 0;
      final ops = OperationsController(
        client: MockClient((request) async {
          if (request.method == 'POST') posts++;
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await mount(tester, ops);
      expect(find.text('체크리스트 편집'), findsNothing);
      expect(find.text('내 담당만'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      await tester.ensureVisible(checkTarget('솥 물량 확인'));
      await tester.tap(checkTarget('솥 물량 확인'));
      await tester.pumpAndSettle();
      expect(find.textContaining('담당자나 사장님·매니저가 확인해요'), findsOneWidget);
      await tester.ensureVisible(checkTarget('작업대 닦기'));
      await tester.tap(checkTarget('작업대 닦기'));
      await tester.pumpAndSettle();
      expect(find.textContaining('현우님이 확인한 활동은'), findsOneWidget);
      expect(posts, 0);
      await tester.tap(find.text('내 담당만'));
      await tester.pumpAndSettle();
      expect(find.text('육수 올리기'), findsNothing);
      expect(find.text('전처리 준비'), findsOneWidget);
    },
  );
  testWidgets(
    'public preview shows taps on this device only, never posts, and can undo',
    (tester) async {
      var posts = 0;
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((request) async {
          if (request.method == 'POST') posts++;
          return response(fixture());
        }),
      );
      addTearDown(ops.dispose);
      await mount(tester, ops);
      await tester.ensureVisible(checkTarget('도구 나누기'));
      await tester.tap(checkTarget('도구 나누기'));
      await tester.pumpAndSettle();
      expect(find.textContaining('확인 · 체험 · 저장 안 됨'), findsOneWidget);
      expect(find.textContaining('공개 미리보기 · 확인 표시는'), findsOneWidget);
      expect(find.text('오늘 활동 1 / 3 확인'), findsOneWidget);
      await tester.tap(checkTarget('도구 나누기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('되돌리기'));
      await tester.pumpAndSettle();
      expect(find.textContaining('체험 · 저장 안 됨'), findsNothing);
      expect(find.text('오늘 활동 0 / 3 확인'), findsOneWidget);
      expect(posts, 0);
      expect(ops.error, isNull);
    },
  );
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
    await tester.ensureVisible(card);
    await longDrag(tester, card, find.text('마감 폴더 · 0'));
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
  testWidgets(
    'an activity dragged onto another group moves there in the draft',
    (tester) async {
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
      await tester.ensureVisible(find.text('도구 나누기'));
      await longDrag(tester, find.text('도구 나누기'), find.text('육수 올리기'));
      expect(find.textContaining('· Small TAP 1개'), findsOneWidget);
      expect(find.textContaining('· Small TAP 2개'), findsOneWidget);
      await tester.ensureVisible(find.text('솥 물량 확인'));
      await longDrag(tester, find.text('솥 물량 확인'), find.text('전처리 준비'));
      await tester.ensureVisible(find.text('도구 나누기'));
      await longDrag(tester, find.text('도구 나누기'), find.text('전처리 준비'));
      expect(find.text('그룹에는 활동이 하나 이상 남아야 해요.'), findsOneWidget);
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();
      final templates = (submitted!['templates'] as List).cast<Json>();
      expect((templates[0]['steps'] as List).map((s) => s['id']), ['s2', 'b1']);
      expect((templates[1]['steps'] as List).map((s) => s['id']), ['s1']);
    },
  );
  testWidgets(
    'owner edits group info, an activity manual, and removes an activity',
    (tester) async {
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
      await tester.ensureVisible(find.text('전처리 준비'));
      await tester.tap(find.text('전처리 준비'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'TAP 이름'),
        '내 매장 준비',
      );
      await tester.tap(find.text('브레이크'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('TAP 정보 적용'));
      await tester.pumpAndSettle();
      expect(find.text('내 매장 준비'), findsOneWidget);
      await tester.ensureVisible(find.text('도구 나누기'));
      await tester.tap(find.text('도구 나누기'));
      await tester.pumpAndSettle();
      expect(find.text('Small TAP과 간단 매뉴얼'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, '간단 매뉴얼 · 방법과 완료 기준'),
        '우리 매장 도구함에서 꺼내 확인해요.',
      );
      await tester.tap(find.text('초안에 적용'));
      await tester.pumpAndSettle();
      final remove = find
          .widgetWithIcon(IconButton, Icons.delete_outline)
          .at(1);
      await tester.ensureVisible(remove);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();
      final first = submitted?['templates'][0] as Json;
      expect(first['title'], '내 매장 준비');
      expect(first['slot'], '브레이크');
      expect(first['steps'], hasLength(1));
      expect(first['steps'][0]['manual'], '우리 매장 도구함에서 꺼내 확인해요.');
      expect(tester.takeException(), isNull);
    },
  );
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
    final import = find.text('선택한 1개 그룹 가져오기');
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
  testWidgets('an off-screen empty manual blocks saving with the group named', (
    tester,
  ) async {
    final data = fixture();
    data['taskTemplates'][1]['steps'] = [
      for (var i = 1; i <= 30; i++)
        {
          'id': 'step-$i',
          'title': '활동 $i',
          'manual': i == 30 ? '' : '방법과 결과를 확인해요.',
          'tip': '',
        },
    ];
    var posts = 0;
    final ops = OperationsController(
      client: MockClient((request) async {
        if (request.method == 'POST') posts++;
        return response(data);
      }),
    );
    addTearDown(ops.dispose);
    await mount(tester, ops, editor: true, width: 900);
    await tester.ensureVisible(find.text('도구 나누기'));
    await tester.tap(find.text('도구 나누기'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, '간단 매뉴얼 · 방법과 완료 기준'),
      '',
    );
    await tester.tap(find.text('초안에 적용'));
    await tester.pumpAndSettle();
    expect(find.text('매뉴얼을 1~700자로 입력해 주세요.'), findsOneWidget);
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('변경 버리기'));
    await tester.pumpAndSettle();
    // Any real change enables saving; the blank manual is then caught before the request.
    await tester.tap(
      find.widgetWithIcon(IconButton, Icons.delete_outline).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.textContaining('「육수 올리기」 · 활동 30의 매뉴얼'), findsWidgets);
    expect(find.text('보드 편집'), findsOneWidget);
    expect(posts, 0);
  });
  testWidgets('back navigation keeps unsaved activity edits until discarded', (
    tester,
  ) async {
    final ops = OperationsController(
      client: MockClient((_) async => response(fixture())),
    );
    addTearDown(ops.dispose);
    await mount(tester, ops, editor: true, width: 900);
    await tester.ensureVisible(find.text('도구 나누기'));
    await tester.tap(find.text('도구 나누기'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Small TAP 이름'),
      '편집 중인 이름',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(find.text('매뉴얼 편집을 취소할까요?'), findsOneWidget);
    await tester.tap(find.text('계속 편집'));
    await tester.pumpAndSettle();
    expect(find.text('편집 중인 이름'), findsOneWidget);
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('변경 버리기'));
    await tester.pumpAndSettle();
    expect(find.text('도구 나누기'), findsOneWidget);
    expect(find.text('편집 중인 이름'), findsNothing);
  });
  testWidgets(
    'reimport restores missing group and preserves custom title and folder',
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
      final import = find.text('선택한 1개 그룹 가져오기');
      await tester.ensureVisible(import);
      await tester.tap(import);
      await tester.pumpAndSettle();
      expect(find.text('기본 업무 · 3'), findsOneWidget);
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
}
