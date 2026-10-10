import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tap2work/domain/edit_conflict.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/team_screen.dart';
import 'calendar_test.dart' show calendarData;

Json snapshot() => {
  'revision': 1,
  'actor': {'id': 'owner', 'role': 'owner'},
  'store': {
    'name': '처음 매장',
    'note': '',
    'profile': {
      'industryId': 'restaurant',
      'serviceModes': ['hall'],
    },
  },
  'tappers': <Json>[],
};
http.Response response(Json value, [int code = 200]) => http.Response(
  jsonEncode(value),
  code,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
Json profileRequest(String name) => {
  'section': 'basic',
  'values': {
    'name': name,
    'note': '',
    'industryId': 'restaurant',
    'serviceModes': ['hall'],
    'address': '',
    'addressSelection': null,
    'addressDetail': '',
    'arrivalNote': '',
  },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'three-way merge preserves unrelated remote fields and treats arrays atomically',
    () {
      final merge = mergeEdit(
        {
          'name': 'old',
          'note': 'old',
          'modes': ['hall'],
        },
        {
          'name': 'old',
          'note': 'remote',
          'modes': ['hall', 'delivery'],
        },
        {
          'name': 'mine',
          'note': 'old',
          'modes': ['takeout'],
        },
      );
      expect(merge.values['name'], 'mine');
      expect(merge.values['note'], 'remote');
      expect(merge.conflicts.single.field, 'modes');
      expect(
        sameEditValue(
          {
            'a': 1,
            'b': [
              {'c': 2, 'd': 3},
            ],
          },
          {
            'b': [
              {'d': 3, 'c': 2},
            ],
            'a': 1,
          },
        ),
        isTrue,
      );
    },
  );
  test(
    'unrelated revision conflict reads latest and retries only after comparing the editor fields',
    () async {
      var live = snapshot();
      final writes = <Json>[];
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'GET') return response(live);
          final body = jsonDecode(r.body) as Json;
          writes.add(body);
          if (writes.length == 1) {
            live = {
              ...live,
              'revision': 2,
              'activity': [
                {'message': 'automatic rollover'},
              ],
            };
            return response({
              'error': 'changed',
              'code': 'REVISION_CONFLICT',
            }, 409);
          }
          live = {
            ...live,
            'revision': 3,
            'store': {...live['store'], 'name': body['values']['name']},
          };
          return response(live);
        }),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      final base = copyEditSnapshot(ops.data!);
      final ok = await ops.saveDraft(
        'save_store_profile',
        profileRequest('내 매장'),
        baseSnapshot: base,
        openingActor: 'owner',
        openingWorkspace: null,
        resolve: (_) async => throw StateError('unrelated change must not ask'),
      );
      expect(ok, isTrue);
      expect(writes.map((r) => r['revision']), [1, 2]);
      expect(ops.data!['store']['name'], '내 매장');
    },
  );
  test(
    'same field conflict requires choice and retains unrelated remote edits',
    () async {
      final base = snapshot(), writes = <Json>[];
      var questions = 0;
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') writes.add(jsonDecode(r.body));
          return response({...base, 'revision': 3});
        }),
      );
      addTearDown(ops.dispose);
      ops.data = {
        ...base,
        'revision': 2,
        'store': {...base['store'], 'name': '최신 매장', 'note': '최신 안내'},
      };
      final ok = await ops.saveDraft(
        'save_store_profile',
        profileRequest('내 매장'),
        baseSnapshot: base,
        openingActor: 'owner',
        openingWorkspace: null,
        resolve: (conflicts) async {
          questions++;
          expect(conflicts.single.latest, '최신 매장');
          return EditConflictChoice.useDraft;
        },
      );
      expect(ok, isTrue);
      expect(questions, 1);
      expect(writes.single['values']['name'], '내 매장');
      expect(writes.single['values']['note'], '최신 안내');
    },
  );
  test(
    'cancel, same-field newer update, and scope changes never write over reviewed values',
    () async {
      final base = snapshot(), writes = <Json>[];
      final ops = OperationsController(
        client: MockClient((r) async {
          writes.add({});
          return response(base);
        }),
      );
      addTearDown(ops.dispose);
      ops.data = {
        ...base,
        'revision': 2,
        'store': {...base['store'], 'name': '최신'},
      };
      for (final mode in ['cancel', 'revision', 'workspace']) {
        final ok = await ops.saveDraft(
          'save_store_profile',
          profileRequest('내 입력'),
          baseSnapshot: base,
          openingActor: 'owner',
          openingWorkspace: null,
          resolve: (_) async {
            if (mode == 'revision') ops.data = {...ops.data!, 'revision': 3};
            if (mode == 'workspace') ops.workspaceId = 'another';
            return mode == 'cancel'
                ? EditConflictChoice.keepEditing
                : EditConflictChoice.useDraft;
          },
        );
        expect(ok, isFalse);
      }
      expect(writes, isEmpty);
    },
  );
  test(
    'unknown create result uses stable request identity and confirms existing success without another write',
    () async {
      var live = snapshot();
      var posts = 0;
      final request = {
        'creationRequestId': 'a1234567890123456',
        'nickname': '신규',
        'nationality': 'VN',
        'guideLocale': 'vi',
        'rank': 'crew',
        'employmentType': '시간알바',
        'hourlyWon': 10320,
        'payPeriod': 'monthly',
        'kakaoUrl': '',
        'phone': '',
        'active': true,
      };
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'GET') return response(live);
          posts++;
          live = {
            ...live,
            'revision': 2,
            'tappers': [
              {'id': 'created', ...request},
            ],
          };
          throw Exception('connection lost after commit');
        }),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      final base = copyEditSnapshot(ops.data!);
      Future<bool> save() => ops.saveDraft(
        'save_tapper',
        request,
        baseSnapshot: base,
        openingActor: 'owner',
        openingWorkspace: null,
        resolve: (_) async => EditConflictChoice.keepEditing,
      );
      expect(await save(), isFalse);
      expect(await save(), isTrue);
      expect(posts, 1);
    },
  );
  testWidgets(
    'new crew form retains all inputs after forbidden response and closes only on successful retry',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final writes = <Json>[];
      final data = {
        ...calendarData(),
        'nationalityOptions': [
          {'code': 'VN', 'name': '베트남'},
        ],
      };
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') {
            writes.add(jsonDecode(r.body));
            if (writes.length == 1) {
              return response({'error': '저장 권한을 확인해 주세요.'}, 403);
            }
          }
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: TeamScreen(operations: ops)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('크루 등록'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '보존할 크루');
      await tester.tap(find.byKey(const ValueKey('crew-nationality')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('베트남').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('crew-guide-language')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();
      expect(find.text('보존할 크루'), findsOneWidget);
      expect(find.textContaining('저장 권한을 확인'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();
      expect(writes.length, 2);
      expect(writes[0]['creationRequestId'], writes[1]['creationRequestId']);
      expect(writes[1]['nationality'], 'VN');
      expect(find.text('보존할 크루'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
