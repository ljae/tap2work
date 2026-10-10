import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/domain/manual_print.dart';
import 'package:tap2work/data/manual_pdf_repository.dart';
import 'package:tap2work/ui/manual_print_screen.dart';
import 'operations_test.dart' show response;
import 'manual_workspace_test.dart' show directoryData;

Json printFixture() {
  final data = directoryData();
  data['taskTemplates'][0]['partId'] = 'kitchen';
  data['taskTemplates'][0]['zone'] = 'sink';
  data['taskTemplates'][1]['partId'] = 'hall';
  data['taskTemplates'][1]['zone'] = 'table';
  data['workplace'] = {
    'parts': [
      {'id': 'kitchen', 'name': '주방'},
      {'id': 'hall', 'name': '홀'},
    ],
  };
  data['zones'] = [
    {'id': 'sink', 'name': '세척대'},
    {'id': 'table', 'name': '테이블'},
  ];
  return data;
}

class FakePdf extends ManualPdfRepository {
  int generated = 0, saved = 0, printed = 0;
  List<Json>? selected;
  Json? snapshotUsed;
  ManualPrintOptions? options;
  @override
  Future<Uint8List> generate(
    Json snapshot,
    List<Json> sources,
    ManualPrintOptions options,
  ) async {
    generated++;
    snapshotUsed = snapshot;
    selected = sources;
    this.options = options;
    return Uint8List.fromList('%PDF-1.7'.codeUnits);
  }

  @override
  Future<bool> save(Uint8List bytes, String filename) async {
    saved++;
    return true;
  }

  @override
  Future<bool> printPdf(Uint8List bytes, String name) async {
    printed++;
    return true;
  }
}

class DeferredPdf extends FakePdf {
  final pending = Completer<Uint8List>();
  @override
  Future<Uint8List> generate(
    Json snapshot,
    List<Json> sources,
    ManualPrintOptions options,
  ) async {
    await super.generate(snapshot, sources, options);
    return pending.future;
  }
}

Future<void> mount(
  WidgetTester tester,
  OperationsController ops, {
  double width = 390,
  ManualPdfRepository? repository,
  Widget? child,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await ops.refresh();
  await tester.pumpWidget(
    MaterialApp(
      home: child ?? ManualPrintScreen(ops: ops, repository: repository),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test(
    'grouping uses stable part/place IDs and stale translations fall back to source',
    () {
      final data = printFixture(), sources = manualPrintSources(data);
      final s = sources.first;
      expect(printGroupName(s, 'part', data, 'en'), '주방');
      expect(printGroupName(s, 'zone', data, 'ko'), '세척대');
      expect(translationState(s, 'en'), 'missing');
      s['translations'] = {
        'en': {'sourceHash': s['sourceHash'], 'title': 'Hygiene', 'steps': []},
      };
      expect(translatedPrintContent(s, 'en')['title'], 'Hygiene');
      s['sourceHash'] = 'changed';
      expect(translationState(s, 'en'), 'stale');
      expect(translatedPrintContent(s, 'en')['title'], '위생 TAP');
    },
  );
  test(
    'crew printing joins only active definition metadata with the manual index',
    () {
      final data = printFixture();
      final metadata = manualPrintSources(
        data,
      ).map((s) => <String, dynamic>{...s}..remove('steps')).toList();
      data.remove('taskTemplates');
      data['manualPrintTemplates'] = metadata;
      final sources = manualPrintSources(data);
      expect(sources.first['steps'], hasLength(2));
      expect(sources.first['steps'][0]['id'], 's1');
      expect(sources.first['steps'][0]['manual'], '손 씻기 상세 매뉴얼');
      expect(printGroupName(sources.first, 'zone', data, 'ko'), '세척대');
    },
  );
  testWidgets(
    'part filter limits the actual PDF while retaining choices for other parts',
    (tester) async {
      final repo = FakePdf();
      final ops = OperationsController(
        client: MockClient((_) async => response(printFixture())),
      );
      addTearDown(ops.dispose);
      await mount(tester, ops, repository: repo);
      await tester.scrollUntilVisible(
        find.text('주방'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('주방'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('manual-print-generate')));
      await tester.pumpAndSettle();
      expect(repo.selected!.map((s) => s['id']), ['a']);
      await tester.tap(find.text('홀'));
      await tester.pumpAndSettle();
      expect(find.text('PDF 저장'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('manual-print-generate')));
      await tester.pumpAndSettle();
      expect(repo.selected!.map((s) => s['id']), ['b']);
    },
  );
  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets(
      'print form selection, generation and export fit $width without writes',
      (tester) async {
        var posts = 0;
        final repo = FakePdf();
        final ops = OperationsController(
          readOnly: true,
          client: MockClient((r) async {
            if (r.method == 'POST') posts++;
            return response(printFixture());
          }),
        );
        addTearDown(ops.dispose);
        await mount(tester, ops, width: width, repository: repo);
        final selection = find.byKey(const ValueKey('print-select-b'));
        await tester.scrollUntilVisible(
          selection,
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(selection);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('manual-print-generate')));
        await tester.pumpAndSettle();
        expect(repo.selected!.map((s) => s['id']), ['a']);
        await tester.tap(find.text('PDF 저장'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('인쇄'));
        await tester.pumpAndSettle();
        expect(repo.saved, 1);
        expect(repo.printed, 1);
        expect(posts, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'translation saves the opening source and revision, retains draft on conflict',
    (tester) async {
      final data = printFixture(), source = manualPrintSources(data).last;
      Json? sent;
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') {
            sent = jsonDecode(r.body) as Json;
            return response({'error': '먼저 저장된 변경이 있어요.'}, 409);
          }
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await mount(
        tester,
        ops,
        child: ManualPrintTranslationScreen(
          ops: ops,
          source: source,
          locale: 'en',
        ),
      );
      for (final (label, value) in [
        ('TAP 이름 번역', 'Cleanup'),
        ('Task 이름 번역', 'Clean'),
        ('진행 방법 번역', 'Clean the area.'),
        ('주의사항 번역', 'Check safety.'),
      ]) {
        final f = find.widgetWithText(TextFormField, label);
        await tester.ensureVisible(f);
        await tester.enterText(f, value);
      }
      data['revision'] = 3;
      await ops.refresh();
      await tester.pumpAndSettle();
      await tester.tap(find.text('검토한 번역 저장'));
      await tester.pumpAndSettle();
      expect(sent?['action'], 'save_manual_print_translation');
      expect(sent?['revision'], 2);
      expect(sent?['sourceHash'], source['sourceHash']);
      expect(find.text('먼저 저장된 변경이 있어요.'), findsOneWidget);
      expect(find.text('Cleanup'), findsOneWidget);
    },
  );
  testWidgets('switching account hides old print content and blocks output', (
    tester,
  ) async {
    final ops = OperationsController(
      client: MockClient((_) async => response(printFixture())),
    );
    addTearDown(ops.dispose);
    final repo = FakePdf();
    await mount(tester, ops, repository: repo);
    await tester.tap(find.byKey(const ValueKey('manual-print-generate')));
    await tester.pumpAndSettle();
    ops.data!['workspaceId'] = 'different-store';
    ops.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('print-select-a')), findsNothing);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'PDF 저장'),
    );
    expect(button.onPressed, isNull);
    expect(repo.saved, 0);
  });
  for (final scope in ['workspace', 'account']) {
    testWidgets(
      'switching $scope before first PDF generation blocks old content',
      (tester) async {
        final data = printFixture()..['workspaceId'] = 'print-store-one';
        final ops = OperationsController(
          client: MockClient((_) async => response(data)),
        );
        addTearDown(ops.dispose);
        final repo = FakePdf();
        await mount(tester, ops, repository: repo);
        if (scope == 'workspace') {
          ops.data!['workspaceId'] = 'print-store-two';
        } else {
          ops.actorId = 'crew';
        }
        ops.notifyListeners();
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('print-select-a')), findsNothing);
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const ValueKey('manual-print-generate')),
              )
              .onPressed,
          isNull,
        );
        expect(repo.generated, 0);
        expect(repo.saved, 0);
        expect(repo.printed, 0);
      },
    );
  }
  testWidgets('PDF generation uses a deep copy of the opening snapshot', (
    tester,
  ) async {
    final ops = OperationsController(
      client: MockClient((_) async => response(printFixture())),
    );
    addTearDown(ops.dispose);
    final repo = FakePdf();
    await mount(tester, ops, repository: repo);
    ops.data!['revision'] = 99;
    ops.data!['taskTemplates'][0]['title'] = '나중에 수정한 제목';
    ops.data!['taskTemplates'][0]['steps'][0]['manual'] = '나중에 수정한 방법';
    await tester.tap(find.byKey(const ValueKey('manual-print-generate')));
    await tester.pumpAndSettle();
    expect(repo.snapshotUsed?['revision'], 2);
    expect(repo.selected!.first['title'], '위생 TAP');
    expect(repo.selected!.first['steps'][0]['manual'], '손 씻기 상세 매뉴얼');
  });
  testWidgets(
    'a PDF finishing after a workspace change is not offered for output',
    (tester) async {
      final data = printFixture()..['workspaceId'] = 'print-store-one';
      final ops = OperationsController(
        client: MockClient((_) async => response(data)),
      );
      addTearDown(ops.dispose);
      final repo = DeferredPdf();
      await mount(tester, ops, repository: repo);
      await tester.tap(find.byKey(const ValueKey('manual-print-generate')));
      await tester.pump();
      expect(repo.generated, 1);
      ops.data!['workspaceId'] = 'print-store-two';
      ops.notifyListeners();
      repo.pending.complete(Uint8List.fromList('%PDF-1.7'.codeUnits));
      await tester.pumpAndSettle();
      expect(find.text('PDF 저장'), findsNothing);
      expect(find.text('미리보기'), findsNothing);
      expect(repo.saved, 0);
      expect(repo.printed, 0);
    },
  );
  testWidgets(
    'generates actual five-language PDFs with bilingual content and long pagination',
    (tester) async {
      final data = printFixture();
      final sources = manualPrintSources(data);
      const translated = {
        'en': [
          'Hygiene checklist',
          'Wash hands',
          'Wash and dry your hands.',
          'Check safety.',
        ],
        'vi': [
          'Danh sách vệ sinh',
          'Rửa tay',
          'Rửa tay và lau khô tay.',
          'Kiểm tra an toàn.',
        ],
        'zh-Hans': ['卫生检查清单', '洗手', '洗手并擦干双手。', '确认安全。'],
        'ja': ['衛生チェックリスト', '手を洗う', '手を洗い、よく乾かします。', '安全を確認します。'],
      };
      await tester.runAsync(() async {
        final out = Directory('../.local/manual-print-review')
          ..createSync(recursive: true);
        for (final locale in printLanguages.keys) {
          final local = jsonDecode(jsonEncode(sources)) as List;
          final rows = local.cast<Json>();
          if (locale != 'ko') {
            final words = translated[locale]!;
            for (final s in rows) {
              s['translations'] = {
                locale: {
                  'sourceHash': s['sourceHash'],
                  'title': words[0],
                  'steps': [
                    for (final step in printRows(s['steps']))
                      {
                        'id': step['id'],
                        'title': words[1],
                        'manual': words[2],
                        'tip': words[3],
                      },
                  ],
                },
              };
            }
          }
          final bytes = await ManualPdfRepository().generate(
            data,
            rows,
            ManualPrintOptions(locale: locale, groupBy: 'zone'),
          );
          expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
          expect(bytes.length, greaterThan(1000));
          File('${out.path}/manual-$locale.pdf').writeAsBytesSync(bytes);
        }
        final stale = manualPrintSources(data);
        stale.first['translations'] = {
          'en': {
            'sourceHash': 'outdated',
            'title': 'UNSAFE OLD TITLE',
            'steps': [],
          },
        };
        final fallback = await ManualPdfRepository().generate(
          data,
          stale,
          const ManualPrintOptions(
            locale: 'en',
            format: 'manual',
            bilingual: false,
          ),
        );
        File('${out.path}/fallback-en.pdf').writeAsBytesSync(fallback);
        final long = manualPrintSources(data);
        long[0]['steps'][0]['manual'] = List.filled(
          90,
          '긴 설명도 페이지를 넘어가며 읽을 수 있어야 해요.',
        ).join('\n');
        final bytes = await ManualPdfRepository().generate(
          data,
          long,
          const ManualPrintOptions(paper: 'a5', format: 'manual'),
        );
        File('${out.path}/long-a5.pdf').writeAsBytesSync(bytes);
      });
    },
  );
}
