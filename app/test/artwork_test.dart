import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tap2work/ui/components.dart';
import 'package:tap2work/ui/menu_artwork.dart';

void main() {
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
        const AssetImage('assets/menu/menu_tap2.png'),
        context,
      );
    });
    await tester.pumpAndSettle();
    final painters = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
    expect(painters.where((paint) => paint.painter != null).length, 2);
    expect(find.bySemanticsLabel('tap2.work 로고'), findsOneWidget);
    expect(find.bySemanticsLabel('뼈곰탕 그림'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
