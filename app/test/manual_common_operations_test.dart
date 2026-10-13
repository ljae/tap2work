import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/domain/manual_market_catalog.dart';
import 'package:tap2work/l10n/app_localizations.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/manual_action_slides.dart';
import 'package:tap2work/ui/manual_hierarchy.dart';
import 'package:tap2work/ui/manual_market_screen.dart';
import 'package:tap2work/ui/manual_workspace.dart';
import 'package:tap2work/ui/tap_card.dart';
import 'checklist_test.dart' show fixture;
import 'manual_workspace_test.dart' show directoryData;
import 'manual_workspace_test.dart' as directory;
import 'operations_test.dart' show response;
import 'tap_workspace_test.dart' show mountBoard, openCard;

void main() {
  for (final width in [390.0, 1200.0]) {
    for (final destination in ['folder', 'tap']) {
      testWidgets(
        'manual directory returns to actual $destination at $width with reduced motion',
        (tester) async {
          var writes = 0;
          final ops = OperationsController(
            client: MockClient((r) async {
              if (r.method == 'POST') writes++;
              return response(directoryData());
            }),
          );
          addTearDown(ops.dispose);
          await directory.mount(tester, ops, width: width);
          await directory.click(tester, 'manual-node-tap:a');
          await directory.click(tester, 'manual-node-task:s1:a');
          final detail = find.text('손 씻기 상세 매뉴얼');
          expect(detail, findsOneWidget);
          expect(
            ModalRoute.of(tester.element(detail))!.transitionDuration,
            Duration.zero,
          );
          await tester.tap(find.byKey(ValueKey('manual-path-$destination')));
          await tester.pumpAndSettle();
          expect(detail, findsNothing);
          if (width >= 760 || destination == 'folder') {
            final path = tester.widget<ManualHierarchyPath>(
              find.byType(ManualHierarchyPath).first,
            );
            expect(path.folder, '오픈');
            expect(path.tap, destination == 'folder' ? null : '위생 TAP');
          }
          expect(writes, 0);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  test('common market separates menu procedures and has pre-opening packs', () {
    final release =
        jsonDecode(File('../docs/market/current.json').readAsStringSync())
            as Json;
    final catalog = ManualMarketCatalog(release);
    final common = catalog.search();
    final recipes = catalog.search(useCase: 'recipe');
    expect(common.every((e) => catalog.useCaseOf(e) != 'recipe'), isTrue);
    for (final collection in ['bbq', 'snack', 'chicken', 'pizza']) {
      final entries = catalog.entries.where(
        (e) => e['collectionId'] == collection,
      );
      expect(entries, isNotEmpty);
      expect(entries.every((e) => recipes.contains(e)), isTrue);
      expect(common.any((e) => e['collectionId'] == collection), isFalse);
    }
    final startup = catalog
        .search(useCase: 'startup', industry: 'food')
        .where((e) => '${e['sourceId']}'.startsWith('startup/'))
        .toList();
    expect(startup.length, 6);
    expect(startup.expand((e) => e['steps'] as List).length, 24);
    expect(common.any((e) => e['sourceId'] == 'food/shift'), isTrue);
    expect(common.any((e) => e['sourceId'] == 'food/cleaning'), isTrue);
  });

  for (final destination in ['folder', 'tap']) {
    testWidgets('work breadcrumb opens the actual $destination without writes', (
      tester,
    ) async {
      final data = fixture();
      data['tasks'][1]['folderId'] = 'close';
      var writes = 0;
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') writes++;
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await mountBoard(tester, ops, width: 390);
      await openCard(tester, 'tap-daily-prep');
      await openCard(tester, 'small-s1');
      await tester.tap(find.byKey(ValueKey('manual-path-$destination')));
      await tester.pumpAndSettle();
      expect(find.byType(ManualActionSlides), findsNothing);
      expect(
        find.byKey(
          ValueKey(
            'tap-body/general/${destination == 'folder' ? 'null' : 'daily-prep'}',
          ),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('tap-daily-broth')), findsNothing);
      expect(
        find.byKey(
          ValueKey(destination == 'folder' ? 'tap-daily-prep' : 'small-s1'),
        ),
        findsOneWidget,
      );
      expect(writes, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('work manual enters horizontally from the right', (tester) async {
    final ops = OperationsController(
      client: MockClient((_) async => response(fixture())),
    );
    addTearDown(ops.dispose);
    await mountBoard(tester, ops, width: 390);
    await openCard(tester, 'tap-daily-prep');
    tester.widget<TapCard>(find.byKey(const ValueKey('small-s1'))).onOpen();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final during = tester.getTopLeft(find.byType(ManualActionSlides));
    expect(during.dx, greaterThan(0));
    expect(during.dy, 0);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(ManualActionSlides)), Offset.zero);
  });

  for (final crew in [false, true]) {
    testWidgets(
      'recipe body uses Chinese step translations for ${crew ? 'crew' : 'owner'}',
      (tester) async {
        final data = directoryData();
        data['taskTemplates'][0]['knowledge'] = {'useCase': 'recipe'};
        for (final row in data['manualSearch'] as List) {
          if (row['templateId'] == 'a') row['manualCategory'] = 'recipe';
        }
        data['manualContentTranslations'] = {
          'manuals': {
            'a': {
              'zh-Hans': {
                'title': {'sourceText': '위생 TAP', 'text': '食谱示例'},
                'steps': {
                  for (final id in ['s1', 's2'])
                    id: {
                      'title': {
                        'sourceText': id == 's1' ? '손 씻기' : '소독',
                        'text': id == 's1' ? '第一步' : '第二步',
                      },
                      'manual': {
                        'sourceText': '${id == 's1' ? '손 씻기' : '소독'} 상세 매뉴얼',
                        'text': id == 's1' ? '第一步的详细方法' : '第二步的详细方法',
                      },
                      'tip': {'sourceText': '안전 확인', 'text': '检查安全'},
                    },
                },
              },
            },
          },
        };
        if (crew) {
          data.remove('taskTemplates');
          data['actor'] = {'id': 'crew', 'role': 'crew'};
          data['canEditTasks'] = false;
        }
        var writes = 0;
        final ops = OperationsController(
          client: MockClient((r) async {
            if (r.method == 'POST') writes++;
            return response(data);
          }),
        );
        addTearDown(ops.dispose);
        await ops.refresh();
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale.fromSubtags(
              languageCode: 'zh',
              scriptCode: 'Hans',
            ),
            supportedLocales: appSupportedLocales,
            localizationsDelegates: const [
              AppStrings.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: ManualWorkspace(ops: ops, query: ''),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('manual-node-tap:a')), findsNothing);
        await tester.tap(find.byKey(const ValueKey('manual-category-recipe')));
        await tester.pumpAndSettle();
        if (!crew) {
          await tester.tap(find.byKey(const ValueKey('manual-market-button')));
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<ManualMarketScreen>(find.byType(ManualMarketScreen))
                .initialCategory,
            'recipe',
          );
          Navigator.of(tester.element(find.byType(ManualMarketScreen))).pop();
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byKey(const ValueKey('store-recipe-a')));
        await tester.pumpAndSettle();
        expect(find.text('第一步的详细方法'), findsOneWidget);
        expect(find.text('第二步的详细方法'), findsOneWidget);
        expect(find.text('손 씻기 상세 매뉴얼'), findsNothing);
        expect(find.text('检查安全'), findsNWidgets(2));
        expect(writes, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
