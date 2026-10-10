import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/data/bundled_manual_translations.dart';
import 'package:tap2work/l10n/app_localizations.dart';
import 'package:tap2work/main.dart';
import 'package:tap2work/state/app_locale_controller.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/state/work_controller.dart';
import 'package:tap2work/ui/shared_welcome_screen.dart';
import 'package:tap2work/ui/manual_workspace.dart';
import 'package:tap2work/ui/tap_workspace.dart';
import 'package:tap2work/ui/translated_content.dart';
import 'app_locale_test.dart' show MemoryLocales;
import 'checklist_test.dart' show fixture;
import 'manual_action_slides_test.dart' show saved;
import 'operations_test.dart' show response;
import 'tap_workspace_test.dart' show openCard;
import 'work_controller_test.dart' show MemoryStore;

const _longText = {
  'ko': '도구와 장소를 확인하고 어려운 일이 있으면 동료에게 물어봐요. 위험한 상황은 혼자 처리하지 않아요.',
  'en':
      'Check the tools and location, and ask a colleague when work is unfamiliar. Do not handle a dangerous situation alone.',
  'vi':
      'Kiểm tra dụng cụ và vị trí; hỏi đồng nghiệp khi chưa biết cách làm. Không tự xử lý tình huống nguy hiểm một mình.',
  'zh-Hans': '检查工具和位置，不熟悉的工作请向同事询问。遇到危险情况时不要独自处理。',
  'ja': '道具と場所を確認し、分からない仕事は同僚に聞いてください。危険な状況は一人で対処しないでください。',
  'th':
      'ตรวจสอบอุปกรณ์และสถานที่ หากไม่คุ้นเคยกับงานให้ถามเพื่อนร่วมงาน อย่าจัดการสถานการณ์อันตรายเพียงลำพัง',
  'ne':
      'उपकरण र स्थान जाँच्नुहोस्। काम थाहा नभए सहकर्मीलाई सोध्नुहोस्। खतरनाक अवस्थालाई एक्लै समाधान नगर्नुहोस्।',
  'id':
      'Periksa alat dan lokasi; tanyakan kepada rekan saat belum memahami pekerjaan. Jangan menangani keadaan berbahaya sendirian.',
};

Json _cell(String original, String translated) => {
  'sourceText': original,
  'text': translated,
};

Json _crewData(String language) {
  final data = fixture(actor: 'crew');
  data['workspaceId'] = 'fictional-store';
  data['translationRuntimeEnabled'] = false;
  data['welcome'] = {
    'revision': 1,
    'importantRevision': 1,
    'sourceLocale': 'ko',
    'title': '매장 공통 안내',
    'body': List.filled(15, _longText['ko']).join('\n'),
  };
  data['welcomeNeedsAcknowledgment'] = true;
  final task = (data['tasks'] as List).first as Json;
  final first = (task['steps'] as List).first as Json;
  first['manual'] = List.filled(15, _longText['ko']).join('\n');
  final display = List.filled(15, _longText[language]).join('\n');
  data['manualContentTranslations'] = {
    'welcome': {
      language: {
        'title': _cell(
          '매장 공통 안내',
          AppStrings(language).text('welcome.heading'),
        ),
        'body': _cell(data['welcome']['body'], display),
      },
    },
    'manuals': {
      'prep': {
        language: {
          'title': _cell(
            task['title'],
            AppStrings(language).text('nav.manual'),
          ),
          'steps': {
            's1': {
              'title': _cell(
                first['title'],
                AppStrings(language).text('manual.checkComplete'),
              ),
              'manual': _cell(first['manual'], display),
              'tip': _cell(first['tip'], _longText[language]!),
            },
          },
        },
      },
    },
  };
  return data;
}

Future<AppLocaleController> _mount(
  WidgetTester t,
  OperationsController ops,
  String language,
  Widget home,
) async {
  t.view.physicalSize = const Size(320, 900);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  t.platformDispatcher.textScaleFactorTestValue = 1.5;
  addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
  final locale = AppLocaleController(store: MemoryLocales());
  addTearDown(locale.dispose);
  await locale.selectLanguage(language);
  final work = WorkController(MemoryStore());
  addTearDown(work.dispose);
  ops.actorId = 'crew';
  await ops.refresh();
  await t.pumpWidget(
    Tap2workApp(controller: work, localeController: locale, homeOverride: home),
  );
  await t.pumpAndSettle();
  return locale;
}

Finder get _check => find.byKey(const ValueKey('manual-action-check'));

void main() {
  setUpAll(() async {
    // Use actual bundled glyph metrics, including Thai/Devanagari shaping.
    for (final entry in {
      'Pretendard': 'assets/fonts/PretendardVariable.ttf',
      'NotoSansThai': 'assets/fonts/app/NotoSansThai-Variable.ttf',
      'NotoSansDevanagari': 'assets/fonts/app/NotoSansDevanagari-Variable.ttf',
      'NotoSansSC': 'assets/fonts/print/NotoSansSC-Regular.ttf',
      'NotoSansJP': 'assets/fonts/print/NotoSansJP-Regular.ttf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load(entry.value))).load();
    }
    // Asset-channel IO runs outside WidgetTester's fake clock. Await real
    // bundled data here, then render through the unmodified production loader.
    for (final language in ['en', 'vi']) {
      final dictionary = await BundledManualTranslations.load(language);
      expect(dictionary['인수인계에서 바뀐 일 찾기'], isNotEmpty);
    }
  });

  for (final language in appLanguageNames.keys) {
    testWidgets(
      'crew action slides fit $language at 320px/1.5 and retain completion IDs',
      (t) async {
        final data = _crewData(language);
        final writes = <Json>[];
        final ops = OperationsController(
          client: MockClient((request) async {
            if (request.method == 'POST') {
              final value = jsonDecode(request.body) as Json;
              writes.add(value);
              saved(data, value);
            }
            return response(data);
          }),
        );
        addTearDown(ops.dispose);
        await _mount(
          t,
          ops,
          language,
          Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: TapWorkspace(ops: ops, onStock: (_) async {}),
              ),
            ),
          ),
        );
        await openCard(t, 'tap-daily-prep');
        await openCard(t, 'small-s1');
        final footer = t.getRect(_check);
        expect(footer.left, greaterThanOrEqualTo(0));
        expect(footer.right, lessThanOrEqualTo(320));
        expect(footer.bottom, lessThanOrEqualTo(900));
        expect(find.textContaining(_longText[language]!), findsWidgets);
        if (language != 'ko') {
          await t.tap(
            find.text(AppStrings(language).text('manual.original')).first,
          );
          await t.pumpAndSettle();
          expect(find.textContaining(_longText['ko']!), findsWidgets);
          expect(writes, isEmpty);
          await t.tap(
            find.text(AppStrings(language).text('manual.translation')).first,
          );
          await t.pumpAndSettle();
        }
        await t.drag(
          find.byKey(const ValueKey('manual-action-pages')),
          const Offset(0, -500),
        );
        await t.pumpAndSettle();
        expect(t.getRect(_check), footer);
        expect(writes, isEmpty);
        await t.tap(_check);
        await t.pumpAndSettle();
        expect(writes.length, 1);
        expect(writes.single['action'], 'complete_step');
        expect(writes.single['taskId'], 'daily-prep');
        expect(writes.single['stepId'], 's1');
        expect(writes.single['revision'], 2);
        expect(
          find.text(
            AppStrings(
              language,
            ).text('work.actions', {'current': 2, 'total': 2}),
          ),
          findsOneWidget,
        );
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'shared welcome fits long $language text without completing work',
      (t) async {
        final data = _crewData(language);
        final writes = <Json>[];
        var workEntered = 0;
        final ops = OperationsController(
          client: MockClient((request) async {
            if (request.method == 'POST') {
              final value = jsonDecode(request.body) as Json;
              writes.add(value);
              data['welcomeNeedsAcknowledgment'] = false;
              data['revision'] = (data['revision'] as int) + 1;
            }
            return response(data);
          }),
        );
        addTearDown(ops.dispose);
        await _mount(
          t,
          ops,
          language,
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => openSharedWelcome(
                  context,
                  ops,
                  onWork: () => workEntered++,
                ),
                child: const Text('open fixture welcome'),
              ),
            ),
          ),
        );
        final originalWork = jsonEncode(ops.data?['tasks']);
        await t.tap(find.text('open fixture welcome'));
        await t.pumpAndSettle();
        final button = find.byKey(const ValueKey('shared-welcome-acknowledge'));
        final footer = t.getRect(button);
        expect(footer.right, lessThanOrEqualTo(320));
        expect(footer.bottom, lessThanOrEqualTo(900));
        expect(find.textContaining(_longText[language]!), findsOneWidget);
        await t.drag(find.byType(ListView).first, const Offset(0, -500));
        await t.pumpAndSettle();
        expect(t.getRect(button), footer);
        expect(writes, isEmpty);
        await t.tap(button);
        await t.pumpAndSettle();
        expect(writes.single['action'], 'ack_welcome');
        expect(writes.single['welcomeRevision'], 1);
        expect(workEntered, 1);
        expect(jsonEncode(ops.data?['tasks']), originalWork);
        expect(t.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'language and actor/store changes reject delayed dictionary results',
    (t) async {
      final data = _crewData('en');
      final ops = OperationsController(
        client: MockClient((_) async => response(data)),
      );
      addTearDown(ops.dispose);
      final dictionaries = {
        'en': Completer<Map<String, String>>(),
        'vi': Completer<Map<String, String>>(),
      };
      final locale = await _mount(
        t,
        ops,
        'en',
        Scaffold(
          body: TranslatedContent(
            ops: ops,
            kind: 'welcome',
            source: const {'title': 'fixture', 'body': 'source'},
            loadDictionary: (tag) => dictionaries[tag]!.future,
            builder: (_, displayed) => Text('${displayed['body']}'),
          ),
        ),
      );
      await locale.selectLanguage('vi');
      await t.pump();
      dictionaries['en']!.complete({
        'fixture': 'old title',
        'source': 'old English result',
      });
      await t.pumpAndSettle();
      expect(find.text('old English result'), findsNothing);
      ops.actorId = 'other-crew';
      ops.data = {...ops.data!, 'workspaceId': 'other-store'};
      dictionaries['vi']!.complete({
        'fixture': 'title',
        'source': 'stale store result',
      });
      await t.pumpAndSettle();
      expect(find.text('stale store result'), findsNothing);
      expect(find.text('source'), findsOneWidget);
    },
  );

  testWidgets(
    'registered English content is searchable with stable original step IDs',
    (t) async {
      final data = _crewData('en');
      data['manualSearch'] = [
        for (final template in data['taskTemplates'] as List)
          for (final step in template['steps'] as List)
            {
              ...step as Json,
              'id': '${template['id']}/${step['id']}',
              'templateId': template['id'],
              'tapId': template['id'],
              'sourceStepId': step['id'],
              'tapTitle': template['title'],
              'folderId': template['folderId'],
              'folderName': '기본 업무',
              'editable': false,
            },
      ];
      var writes = 0;
      final ops = OperationsController(
        client: MockClient((request) async {
          if (request.method == 'POST') writes++;
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await _mount(
        t,
        ops,
        'en',
        Scaffold(
          body: ManualWorkspace(ops: ops, query: 'colleague'),
        ),
      );
      // Open the result list using its existing phone navigation toggle.
      await t.tap(find.widgetWithIcon(TextButton, CupertinoIcons.doc_text));
      await t.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('manual-content-frame-prep/s1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('manual-content-frame-prep/s2')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('manual-content-frame-broth/b1')),
        findsNothing,
      );
      expect(
        find.text(AppStrings('en').text('manual.checkComplete')),
        findsWidgets,
      );
      expect(writes, 0);
      expect(t.takeException(), isNull);
    },
  );

  for (final language in ['en', 'vi']) {
    testWidgets(
      'bundled $language manual renders without paid requests or source ID changes',
      (t) async {
        const original = {
          'id': 'existing-step',
          'title': '인수인계에서 바뀐 일 찾기',
          'manual': '오늘 품절·예약·미완료 업무를 읽고 본인 업무에 영향을 주는 항목을 하나씩 짚어요.',
          'tip': '어제 메모를 오늘 공지로 착각하지 않도록 날짜부터 봐요.',
        };
        final data = _crewData(language)..remove('manualContentTranslations');
        var posts = 0;
        final ops = OperationsController(
          client: MockClient((request) async {
            if (request.method == 'POST') posts++;
            return response(data);
          }),
        );
        addTearDown(ops.dispose);
        await _mount(
          t,
          ops,
          language,
          Scaffold(
            body: TranslatedContent(
              ops: ops,
              kind: 'manual',
              entityId: 'existing-manual',
              stepId: 'existing-step',
              source: original,
              builder: (_, row) => Column(
                children: [
                  Text('${row['id']}'),
                  Text('${row['title']}'),
                  Text('${row['manual']}'),
                  Text('${row['tip']}'),
                ],
              ),
            ),
          ),
        );
        await t.runAsync(() async {
          await BundledManualTranslations.load(language);
          await Future<void>.delayed(Duration.zero);
        });
        await t.pumpAndSettle();
        expect(find.text('existing-step'), findsOneWidget);
        expect(
          find.text(
            language == 'en'
                ? 'Find changes in the handover'
                : 'Tìm những thay đổi trong bàn giao',
          ),
          findsOneWidget,
          reason: t
              .widgetList<Text>(find.byType(Text))
              .map((w) => w.data)
              .join(' | '),
        );
        expect(
          find.text(AppStrings(language).text('translation.prepared')),
          findsOneWidget,
        );
        expect(
          find.text(AppStrings(language).text('translation.needed')),
          findsNothing,
        );
        expect(posts, 0);
        expect(t.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'edited field falls back independently while prepared fields retain IDs',
    (t) async {
      final data = _crewData('vi');
      final ops = OperationsController(
        client: MockClient((_) async => response(data)),
      );
      addTearDown(ops.dispose);
      await _mount(
        t,
        ops,
        'vi',
        Scaffold(
          body: TranslatedContent(
            ops: ops,
            kind: 'manual',
            entityId: 'prep',
            stepId: 's1',
            source: const {
              'id': 's1',
              'title': '도구 나누기',
              'manual': '새로 수정한 원문',
              'tip': '색상보다 용도를 확인해요.',
            },
            loadDictionary: (_) async => {},
            builder: (_, displayed) => Column(
              children: [
                Text('${displayed['id']}'),
                Text('${displayed['title']}'),
                Text('${displayed['manual']}'),
                Text('${displayed['tip']}'),
              ],
            ),
          ),
        ),
      );
      expect(find.text('s1'), findsOneWidget);
      expect(find.text('새로 수정한 원문'), findsOneWidget);
      expect(
        find.text(AppStrings('vi').text('manual.checkComplete')),
        findsOneWidget,
      );
      expect(find.text(_longText['vi']!), findsOneWidget);
      expect(
        find.text(AppStrings('vi').text('translation.needed')),
        findsOneWidget,
      );
    },
  );
}
