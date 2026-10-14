import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/main.dart';
import 'package:tap2work/l10n/app_localizations.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/state/work_controller.dart';
import 'package:tap2work/ui/service_workflow_screen.dart';
import '../test/service_workflow_test.dart' show fixture;
import '../test/operations_test.dart' show response;
import '../test/work_controller_test.dart' show MemoryStore;

void main() {
  testWidgets(
    'review service workflow with production theme and bundled fonts',
    (tester) async {
      for (final font in {
        'Pretendard': 'assets/fonts/PretendardVariable.ttf',
        'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
        'NotoSansSC': 'assets/fonts/print/NotoSansSC-Regular.ttf',
        'NotoSansJP': 'assets/fonts/print/NotoSansJP-Regular.ttf',
        'NotoSansThai': 'assets/fonts/app/NotoSansThai-Variable.ttf',
        'NotoSansDevanagari':
            'assets/fonts/app/NotoSansDevanagari-Variable.ttf',
      }.entries) {
        await (FontLoader(
          font.key,
        )..addFont(rootBundle.load(font.value))).load();
      }
      final data = fixture();
      data['serviceWorkflow']['ownShifts'] = [
        {
          'date': '2026-10-14',
          'start': '10:00',
          'end': '16:00',
          'partId': 'hall',
          'partName': '홀',
        },
      ];
      data['serviceWorkflow']['records'] = [
        {
          'kind': 'handoff',
          'day': '2026-10-14',
          'actor': {'id': 'crew', 'name': '가상 크루'},
          'note': '점심 영업 후 컵이 부족해요.',
          'nextAction': '다음 영업 전 깨끗한 컵을 채워 주세요.',
          'assignee': '가상 담당',
          'canResolve': true,
        },
        {
          'kind': 'handoff',
          'day': '2026-10-13',
          'actor': {'name': '가상 크루'},
          'note': '처리한 인계',
          'nextAction': '테이블 보충',
          'resolution': {'note': '보충 완료'},
        },
        {
          'kind': 'practice',
          'day': '2026-10-14',
          'actor': {'name': '가상 크루'},
          'note': '고객에게 대기 시간을 안내해 봤어요.',
          'buddyCrewId': 'review-buddy',
          'manual': {'id': 'a', 'title': '고객 맞이', 'version': 1},
        },
      ];
      data['tappers'].add({
        'id': 'review-buddy',
        'actorId': 'owner',
        'active': true,
        'nickname': '가상 버디',
      });
      final ops = OperationsController(
        client: MockClient((_) async => response(data)),
      );
      final work = WorkController(MemoryStore());
      addTearDown(ops.dispose);
      addTearDown(work.dispose);
      await ops.refresh();
      await tester.pumpWidget(Tap2workApp(controller: work, operations: ops));
      await tester.pumpAndSettle();
      final theme = tester.widget<MaterialApp>(find.byType(MaterialApp)).theme;
      final captureKey = GlobalKey();
      Directory(
        '../.local/service-ux-20261014/images',
      ).createSync(recursive: true);
      Future<void> capture(String name) async {
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final boundary =
              captureKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            '../.local/service-ux-20261014/images/$name.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetViewInsets);
      for (final width in [320.0, 390.0, 1200.0]) {
        tester.view.physicalSize = Size(width, 900);
        await tester.pumpWidget(
          RepaintBoundary(
            key: captureKey,
            child: MaterialApp(
              theme: theme,
              debugShowCheckedModeBanner: false,
              locale: const Locale('ko'),
              supportedLocales: appSupportedLocales,
              localizationsDelegates: const [
                AppStrings.delegate,
                ...GlobalMaterialLocalizations.delegates,
              ],
              home: ServiceWorkflowScreen(key: ValueKey(width), ops: ops),
            ),
          ),
        );
        await capture('start-${width.toInt()}');
        await tester.tap(find.text('교대·마감'));
        await capture('handover-${width.toInt()}');
        await tester.tap(find.text('인계 남기기'));
        await capture('form-${width.toInt()}');
        await tester.tap(find.byType(CloseButton).last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('CS·개선'));
        await capture('cs-${width.toInt()}');
      }
      for (final locale in appSupportedLocales) {
        tester.view.physicalSize = const Size(320, 740);
        await tester.pumpWidget(
          RepaintBoundary(
            key: captureKey,
            child: MaterialApp(
              theme: theme,
              debugShowCheckedModeBanner: false,
              locale: locale,
              supportedLocales: appSupportedLocales,
              localizationsDelegates: const [
                AppStrings.delegate,
                ...GlobalMaterialLocalizations.delegates,
              ],
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(1.5)),
                child: child!,
              ),
              home: ServiceWorkflowScreen(
                key: ValueKey(locale.toLanguageTag()),
                ops: ops,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final strings = AppStrings(locale.toLanguageTag());
        await tester.tap(find.text(strings.text('service.handover')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(strings.text('service.handoff')));
        await tester.pumpAndSettle();
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        await capture('keyboard-${locale.toLanguageTag()}');
        tester.view.resetViewInsets();
        await tester.tap(find.byType(CloseButton).last);
        await tester.pumpAndSettle();
        await tester.tap(find.text(strings.text('service.cs')));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text(strings.text('service.feedback')),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text(strings.text('service.feedback')));
        await tester.pumpAndSettle();
        await capture('feedback-${locale.toLanguageTag()}');
        await tester.tap(find.byType(CloseButton).last);
        await tester.pumpAndSettle();
      }
    },
  );
}
