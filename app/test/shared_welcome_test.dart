import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/l10n/app_localizations.dart';
import 'package:tap2work/l10n/store_messages.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/state/work_controller.dart';
import 'package:tap2work/ui/manual_workspace.dart';
import 'package:tap2work/ui/operations_screen.dart';
import 'package:tap2work/ui/shared_welcome_screen.dart';
import 'package:tap2work/ui/tap_workspace.dart';
import 'checklist_test.dart' show fixture;
import 'operations_test.dart' show response;
import 'work_controller_test.dart' show MemoryStore;

Json welcomeData({String actor = 'owner', bool pending = true}) {
  final data = fixture(actor: actor);
  data['workspaceId'] = 'shared-store';
  data['store'] = {'name': '가상 공통 매장'};
  data['welcome'] = {
    'revision': 1,
    'importantRevision': 1,
    'sourceLocale': 'ko',
    'title': '우리 매장의 함께 일하는 기준',
    'body': '도구와 장소를 확인하고, 어려운 일이 있으면 함께 확인해요.',
  };
  data['welcomeAcknowledgment'] = pending
      ? null
      : {'revision': 1, 'importantRevision': 1, 'at': '2026-10-10T09:00:00Z'};
  data['welcomeNeedsAcknowledgment'] = pending;
  data['manualSearch'] = [
    for (final template in data['taskTemplates'])
      for (final step in template['steps'])
        {
          ...step,
          'id': '${template['id']}/${step['id']}',
          'templateId': template['id'],
          'tapId': template['id'],
          'sourceStepId': step['id'],
          'tapTitle': template['title'],
          'folderId': template['folderId'],
          'folderName': '기본 업무',
          'editable': actor == 'owner',
        },
  ];
  return data;
}

Future<void> mountShared(
  WidgetTester tester,
  OperationsController ops, {
  double width = 390,
  double scale = 1,
  Widget? screen,
  String language = 'ko',
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final work = WorkController(MemoryStore());
  addTearDown(work.dispose);
  await ops.refresh();
  await tester.pumpWidget(
    MaterialApp(
      locale: language == 'zh-Hans'
          ? const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans')
          : Locale(language),
      supportedLocales: appSupportedLocales,
      localizationsDelegates: [
        AppStrings.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: screen ?? OperationsScreen(operations: ops, work: work),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test(
    'static store resources cover eight locales with matching placeholders',
    () {
      final placeholder = RegExp(r'\{[^}]+\}');
      for (final entry in storeMessageRows.entries) {
        expect(entry.value, hasLength(8), reason: entry.key);
        final expected = placeholder
            .allMatches(entry.value.first)
            .map((m) => m.group(0))
            .toSet();
        for (final text in entry.value) {
          expect(text.trim(), isNotEmpty, reason: entry.key);
          expect(
            placeholder.allMatches(text).map((m) => m.group(0)).toSet(),
            expected,
            reason: entry.key,
          );
        }
        for (final language in appLanguageNames.keys) {
          expect(AppStrings(language).text(entry.key), isNot(entry.key));
        }
      }
    },
  );

  for (final actor in ['owner', 'crew']) {
    testWidgets(
      '$actor reads identical common welcome, tasks and manuals using own identity',
      (tester) async {
        final data = welcomeData(actor: actor);
        data['tasks'][0]['steps'][0]['completedAt'] = '2026-10-10T09:00:00Z';
        data['tasks'][0]['steps'][0]['completedBy'] = {
          'id': 'other-crew',
          'name': '동료',
        };
        final posts = <Json>[];
        final ops = OperationsController(
          accessToken: () async => 'test-session',
          client: MockClient((request) async {
            if (request.method == 'POST') {
              posts.add(jsonDecode(request.body) as Json);
            }
            return response(data);
          }),
        );
        addTearDown(ops.dispose);
        await mountShared(tester, ops);
        expect(find.byType(SharedWelcomeScreen), findsOneWidget);
        expect(find.text('우리 매장의 함께 일하는 기준'), findsOneWidget);
        expect(find.text('도구와 장소를 확인하고, 어려운 일이 있으면 함께 확인해요.'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('shared-welcome-edit')),
          actor == 'owner' ? findsOneWidget : findsNothing,
        );
        expect(ops.actorId, actor);
        await tester.tap(find.byKey(const ValueKey('shared-welcome-work')));
        await tester.pumpAndSettle();
        expect(find.byType(SharedWelcomeScreen), findsNothing);
        expect(find.byType(TapWorkspace), findsOneWidget);
        expect(find.byKey(const ValueKey('tap-daily-prep')), findsOneWidget);
        expect(find.text('1/2'), findsOneWidget);
        expect(
          ops.rows('tasks').first['steps'][0]['completedBy']['id'],
          'other-crew',
        );
        expect(ops.actorId, actor);
        await tester.tap(find.byKey(const ValueKey('floating-menu-1')));
        await tester.pumpAndSettle();
        expect(find.byType(ManualWorkspace), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('header-account-menu')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('웰컴 다시 보기').last);
        await tester.pumpAndSettle();
        expect(find.byType(SharedWelcomeScreen), findsOneWidget);
        expect(find.text('우리 매장의 함께 일하는 기준'), findsOneWidget);
        expect(posts, isEmpty);
        expect(ops.data?['welcomeNeedsAcknowledgment'], isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'acknowledgement stores displayed welcome revision with own scope, never completes work',
    (tester) async {
      final data = welcomeData(actor: 'crew');
      final posts = <Json>[];
      final ops = OperationsController(
        accessToken: () async => 'test-session',
        client: MockClient((request) async {
          if (request.method == 'POST') {
            final payload = jsonDecode(request.body) as Json;
            posts.add(payload);
            data['revision'] = 3;
            data['welcomeAcknowledgment'] = {
              'revision': 1,
              'importantRevision': 1,
              'at': '2026-10-10T09:00:00Z',
            };
            data['welcomeNeedsAcknowledgment'] = false;
          }
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await mountShared(tester, ops);
      await tester.tap(
        find.byKey(const ValueKey('shared-welcome-acknowledge')),
      );
      await tester.pumpAndSettle();
      expect(posts.single['action'], 'ack_welcome');
      expect(posts.single['welcomeRevision'], 1);
      expect(posts.single['revision'], 2);
      expect(posts.single['workspaceId'], 'shared-store');
      expect(posts.single.containsKey('actorId'), isFalse);
      expect(ops.actorId, 'crew');
      expect(find.byType(SharedWelcomeScreen), findsNothing);
      expect(
        ops.rows('tasks').every((task) => task['completedAt'] == null),
        isTrue,
      );
    },
  );

  testWidgets(
    'only a new important version automatically reopens after nonblocking continuation',
    (tester) async {
      final data = welcomeData();
      final ops = OperationsController(
        client: MockClient((_) async => response(data)),
      );
      addTearDown(ops.dispose);
      await mountShared(tester, ops);
      await tester.tap(find.byKey(const ValueKey('shared-welcome-work')));
      await tester.pumpAndSettle();
      data['welcome']['revision'] = 2;
      data['welcome']['body'] = '일반 변경';
      await ops.refresh();
      await tester.pumpAndSettle();
      expect(find.byType(SharedWelcomeScreen), findsNothing);
      data['welcome']['revision'] = 3;
      data['welcome']['importantRevision'] = 3;
      data['welcome']['body'] = '중요 변경';
      await ops.refresh();
      await tester.pumpAndSettle();
      expect(find.byType(SharedWelcomeScreen), findsOneWidget);
      expect(find.text('중요 변경'), findsOneWidget);
    },
  );

  testWidgets(
    'common welcome edits pin CAS, mark important changes and preserve input on error',
    (tester) async {
      final data = welcomeData();
      final posts = <Json>[];
      var fail = true;
      final ops = OperationsController(
        client: MockClient((request) async {
          if (request.method == 'POST') {
            final payload = jsonDecode(request.body) as Json;
            posts.add(payload);
            if (fail) return response({'error': '다른 변경을 먼저 확인해 주세요.'}, 409);
            data['welcome'] = {
              ...payload['welcome'] as Json,
              'revision': 2,
              'importantRevision': 2,
            };
            data['revision'] = 3;
          }
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await mountShared(tester, ops);
      await tester.tap(find.byKey(const ValueKey('shared-welcome-edit')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('welcome-editor-title')),
        '함께 확인할 새 기준',
      );
      await tester.enterText(
        find.byKey(const ValueKey('welcome-editor-body')),
        '내용은 모든 크루에게 함께 적용해요.',
      );
      await tester.ensureVisible(find.byType(SwitchListTile));
      await tester.tap(find.byType(SwitchListTile));
      await tester.tap(find.byKey(const ValueKey('welcome-editor-save')));
      await tester.pumpAndSettle();
      expect(find.byType(SharedWelcomeEditor), findsOneWidget);
      expect(find.text('함께 확인할 새 기준'), findsOneWidget);
      expect(find.text('다른 변경을 먼저 확인해 주세요.'), findsWidgets);
      expect(posts.single['action'], 'save_welcome');
      expect(posts.single['revision'], 2);
      expect(posts.single['important'], true);
      expect(posts.single['welcome']['sourceLocale'], 'ko');
      expect(posts.single['welcome']['body'], '내용은 모든 크루에게 함께 적용해요.');
      fail = false;
      await tester.tap(find.byKey(const ValueKey('welcome-editor-save')));
      await tester.pumpAndSettle();
      expect(find.byType(SharedWelcomeEditor), findsNothing);
      expect(find.text('함께 확인할 새 기준'), findsOneWidget);
      expect(
        ops.rows('tasks').every((task) => task['completedAt'] == null),
        isTrue,
      );
    },
  );

  testWidgets(
    'changing store clears welcome content and blocks an open editor draft',
    (tester) async {
      final data = welcomeData();
      var writes = 0;
      final ops = OperationsController(
        client: MockClient((request) async {
          if (request.method == 'POST') writes++;
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await mountShared(tester, ops);
      await tester.tap(find.byKey(const ValueKey('shared-welcome-edit')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('welcome-editor-body')),
        '다른 매장에 보내면 안 되는 초안',
      );
      data['workspaceId'] = 'other-store';
      await ops.refresh();
      await tester.pumpAndSettle();
      expect(find.text('다른 매장에 보내면 안 되는 초안'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('welcome-editor-save')),
            )
            .onPressed,
        isNull,
      );
      expect(writes, 0);
    },
  );

  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets(
      'public welcome stays nonblocking at $width with enlarged text and no writes',
      (tester) async {
        final data = welcomeData();
        data['welcome']['body'] = List.filled(60, '매장 안내는 함께 확인해요.').join('\n');
        var writes = 0;
        final ops = OperationsController(
          readOnly: true,
          client: MockClient((request) async {
            if (request.method == 'POST') writes++;
            return response(data);
          }),
        );
        addTearDown(ops.dispose);
        await mountShared(tester, ops, width: width, scale: 1.5);
        expect(
          find.byKey(const ValueKey('shared-welcome-acknowledge')),
          findsNothing,
        );
        final footer = tester.getRect(
          find.byKey(const ValueKey('shared-welcome-work')),
        );
        await tester.drag(find.byType(ListView).last, const Offset(0, -500));
        await tester.pumpAndSettle();
        expect(
          tester.getRect(find.byKey(const ValueKey('shared-welcome-work'))),
          footer,
        );
        await tester.tap(find.byKey(const ValueKey('shared-welcome-work')));
        await tester.pumpAndSettle();
        expect(find.byType(TapWorkspace), findsOneWidget);
        expect(writes, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'failed acknowledgement stays, reads latest welcome and retries its revision',
    (tester) async {
      final data = welcomeData(actor: 'crew');
      final posts = <Json>[];
      final ops = OperationsController(
        accessToken: () async => 'test-session',
        client: MockClient((request) async {
          if (request.method == 'POST') {
            final payload = jsonDecode(request.body) as Json;
            posts.add(payload);
            if (posts.length == 1) {
              data['revision'] = 4;
              data['welcome']['revision'] = 2;
              data['welcome']['importantRevision'] = 2;
              data['welcome']['body'] = '새 중요 안내를 확인해 주세요.';
              return response({'error': '안내가 바뀌었어요. 현재 내용을 확인해 주세요.'}, 409);
            }
            data['welcomeNeedsAcknowledgment'] = false;
          }
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await mountShared(tester, ops);
      await tester.tap(
        find.byKey(const ValueKey('shared-welcome-acknowledge')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SharedWelcomeScreen), findsOneWidget);
      expect(find.text('새 중요 안내를 확인해 주세요.'), findsOneWidget);
      expect(find.text('안내가 바뀌었어요. 현재 내용을 확인해 주세요.'), findsWidgets);
      expect(posts.single['welcomeRevision'], 1);
      await tester.tap(
        find.byKey(const ValueKey('shared-welcome-acknowledge')),
      );
      await tester.pumpAndSettle();
      expect(posts.last['welcomeRevision'], 2);
      expect(posts.last['revision'], 4);
      expect(find.byType(SharedWelcomeScreen), findsNothing);
    },
  );

  testWidgets(
    'registered welcome translation offers original view without runtime calls or work completion',
    (tester) async {
      final data = welcomeData();
      data['manualContentTranslations'] = {
        'welcome': {
          'en': {
            'title': {
              'sourceText': data['welcome']['title'],
              'text': 'Our shared store standards',
            },
            'body': {
              'sourceText': data['welcome']['body'],
              'text': 'Check tools and places and ask for help when needed.',
            },
          },
        },
      };
      data['manualContentTranslations'] = {
        'welcome': {
          'en': {
            'title': {
              'sourceText': data['welcome']['title'],
              'text': 'Our shared store standards',
            },
            'body': {
              'sourceText': data['welcome']['body'],
              'text': 'Check tools and places and ask for help when needed.',
            },
          },
        },
      };
      final operationsPosts = <Json>[];
      final translationPosts = <Json>[];
      final ops = OperationsController(
        accessToken: () async => 'test-session',
        client: MockClient((request) async {
          if (request.url.queryParameters['translate'] == 'content') {
            translationPosts.add(jsonDecode(request.body) as Json);
            return response({
              'status': 'translated',
              'original': data['welcome'],
              'translated': {
                'title': 'Our shared store standards',
                'body': 'Check tools and places and ask for help when needed.',
              },
            });
          }
          if (request.method == 'POST') {
            operationsPosts.add(jsonDecode(request.body) as Json);
          }
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await mountShared(tester, ops, language: 'en');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Our shared store standards'), findsOneWidget);
      expect(translationPosts, isEmpty);
      await tester.tap(find.text(AppStrings('en').text('manual.original')));
      await tester.pumpAndSettle();
      expect(find.text('우리 매장의 함께 일하는 기준'), findsOneWidget);
      expect(operationsPosts, isEmpty);
      expect(ops.data?['welcomeNeedsAcknowledgment'], true);
      expect(
        ops.rows('tasks').every((task) => task['completedAt'] == null),
        true,
      );
    },
  );

  for (final language in appLanguageNames.keys) {
    testWidgets(
      'welcome navigation is localized for $language and original content stays available',
      (tester) async {
        final data = welcomeData();
        final ops = OperationsController(
          readOnly: true,
          client: MockClient((_) async => response(data)),
        );
        addTearDown(ops.dispose);
        await mountShared(tester, ops, language: language);
        expect(
          find.text(AppStrings(language).text('welcome.heading')),
          findsOneWidget,
        );
        expect(
          find.text(AppStrings(language).text('welcome.continueWork')),
          findsOneWidget,
        );
        expect(find.text('우리 매장의 함께 일하는 기준'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
