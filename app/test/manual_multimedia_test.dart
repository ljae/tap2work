import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/domain/manual_media_assets.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/manual_market_screen.dart';
import 'package:tap2work/ui/manual_media_view.dart';
import 'manual_market_test.dart' show fixture, mount;
import 'manual_media_editor_test.dart'
    show MediaEditorRepository, mountMediaEditor, saveMediaEditor, mediaFixture;
import 'operations_test.dart' show response;

void main() {
  const custom = '${manualMediaRoot}player.html#p=eyJmb3JtYXQiOiJ0YXAifQ';
  test(
    'media attribution and iframe classification require the exact trusted origin',
    () {
      expect(
        manualMediaAsset('${manualMediaRoot}kitchen.jpg')?.license,
        'CC0 1.0',
      );
      expect(isManualMotionProject(custom), isTrue);
      expect(manualMediaAsset(custom)?.kind, 'motion');
      expect(isManualMediaKit('${manualMediaRoot}index.html#sources'), isTrue);
      for (final invalid in [
        custom.replaceFirst('https:', 'http:'),
        custom.replaceFirst('tap2.work', 'tap2.work.evil.test'),
        custom.replaceFirst('tap2.work', 'user@tap2.work'),
        custom.replaceFirst('tap2.work', 'tap2.work:444'),
        custom.replaceFirst('#', '?x=1#'),
        custom.replaceFirst('player.html', 'studio.html'),
        '${manualMediaRoot}player.html#p=${'a' * 2000}',
        '${manualMediaRoot}player.html#p=<script>',
      ]) {
        expect(isManualMotionProject(invalid), isFalse, reason: invalid);
        expect(manualMediaAsset(invalid), isNull, reason: invalid);
      }
      expect(
        isManualMediaKit('https://user@tap2.work/manual-media/v1/'),
        isFalse,
      );
      expect(manualMediaAsset('https://example.com/kitchen.jpg'), isNull);
    },
  );

  testWidgets(
    'credits, source kit and motion editing fit a small phone with large text; replaced media loses old attribution',
    (t) async {
      t.view.physicalSize = const Size(320, 1000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      Future<void> show(Map<String, dynamic> step) => t.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ManualMediaView(step: step, showPhoto: false),
            ),
          ),
        ),
      );
      await show({
        'imageUrl': '${manualMediaRoot}kitchen.jpg',
        'videoUrl': custom,
        'sourceUrl': manualMediaRoot,
      });
      await t.pumpAndSettle();
      expect(find.textContaining('CC0 1.0'), findsOneWidget);
      expect(find.text('모션 문구·시간 수정'), findsOneWidget);
      expect(find.text('원본·출처와 수정 도구'), findsOneWidget);
      expect(t.takeException(), isNull);
      await show({
        'imageUrl': 'https://example.com/own.jpg',
        'videoUrl': 'https://example.com/own.mp4',
      });
      await t.pumpAndSettle();
      expect(find.textContaining('CC0 1.0'), findsNothing);
      expect(find.text('모션 문구·시간 수정'), findsNothing);
      expect(find.text('새 창에서 영상 열기'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'media filter imports only the chosen existing source through the pinned catalog',
    (t) async {
      final data = fixture();
      final entries = data['manualCatalog']['entries'] as List;
      entries[0]['steps'][0]['videoUrl'] = custom;
      Json? sent;
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') sent = jsonDecode(r.body);
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await mount(t, ops, ManualMarketScreen(ops: ops));
      await t.tap(find.byKey(const ValueKey('market-media-examples')));
      await t.pumpAndSettle();
      expect(find.byType(Checkbox), findsOneWidget);
      await t.tap(find.byType(Checkbox));
      await t.pumpAndSettle();
      await t.tap(find.text('담은 1개 확인'));
      await t.pumpAndSettle();
      await t.tap(find.text('선택한 1개 가져오기'));
      await t.pumpAndSettle();
      expect(sent?['sourceIds'], ['common/0']);
      expect(sent?['releaseId'], 'release-one');
      expect(sent?['revision'], 2);
    },
  );

  testWidgets(
    'editing the selected video preserves its photo and surrounding steps',
    (t) async {
      final repository = MediaEditorRepository();
      await mountMediaEditor(t, repository);
      final field = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == '영상 HTTPS 링크 (선택)',
      );
      await t.scrollUntilVisible(
        field,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await t.enterText(field, custom);
      await t.pumpAndSettle();
      await saveMediaEditor(t);
      final saved = repository.writes.single;
      final steps = saved['steps'] as List;
      expect(saved['revision'], 23);
      expect(steps[1]['videoUrl'], custom);
      expect(steps[1]['imageUrl'], 'https://example.com/old.jpg');
      expect(steps.first, mediaFixture()['taskTemplates'][0]['steps'][0]);
      expect(steps.last, mediaFixture()['taskTemplates'][0]['steps'][2]);
      expect(repository.uploads, 0);
    },
  );
}
