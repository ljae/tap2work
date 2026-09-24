import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tap2work/ui/components.dart';
import 'package:tap2work/ui/menu_artwork.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets('shared header holds one action and both logos at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: const BrandHeader(action: HeaderAccountButton()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('tap2.work'), findsNothing);
      expect(find.bySemanticsLabel('Tap2.work 워드마크'), findsOneWidget);
      expect(find.bySemanticsLabel('tap2.work 로고'), findsOneWidget);
      expect(find.byType(HeaderAccountButton), findsOneWidget);
      expect(tester.getSize(find.byType(AppBar)).height, 80);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('supplied logo and menu sheet resolve into cropped images', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              BrandLogo(),
              MenuArtwork(menuId: 'soup', menuName: '뼈곰탕'),
            ],
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      final context = tester.element(find.byType(BrandLogo));
      await precacheImage(
        const AssetImage('assets/branding/tap2work.png'),
        context,
      );
      await precacheImage(
        const AssetImage('assets/branding/tap2work_wordmark.png'),
        context,
      );
      await precacheImage(
        const AssetImage('assets/menu/menu_tap2.png'),
        context,
      );
    });
    await tester.pumpAndSettle();
    final painters = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
    expect(painters.where((paint) => paint.painter != null).length, 1);
    expect(find.bySemanticsLabel('tap2.work 로고'), findsOneWidget);
    expect(find.bySemanticsLabel('Tap2.work 워드마크'), findsOneWidget);
    expect(find.bySemanticsLabel('뼈곰탕 그림'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
