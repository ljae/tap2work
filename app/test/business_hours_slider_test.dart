import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tap2work/ui/business_hours_slider.dart';
import 'time_band_editor_test.dart' show fixture, mount;

void main() {
  test('day periods adapt to short and overnight opening windows', () {
    expect(shiftBoundaries(360, 1320, 1), [360, 1320]);
    expect(shiftBoundaries(360, 1320, 2), [360, 900, 1320]);
    expect(shiftBoundaries(360, 1320, 3), [360, 720, 1080, 1320]);
    expect(shiftBoundaries(600, 690, 3), [600, 630, 660, 690]);
    expect(shiftBoundaries(1320, 1740, 3), [1320, 1470, 1590, 1740]);
  });
  testWidgets(
    'all/individual hours and breaks preserve closed days and IDs in saved payload',
    (tester) async {
      final data = fixture();
      data['workplace']['days']['7'] = <Map<String, dynamic>>[];
      Map<String, dynamic>? written;
      await mount(tester, initialData: data, write: (v) => written = v);
      await tester.scrollUntilVisible(
        find.byType(BusinessHoursSlider),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      tester
          .widget<BusinessHoursSlider>(find.byType(BusinessHoursSlider))
          .onHours(360, 1320);
      await tester.pumpAndSettle();
      tester
          .widget<BusinessHoursSlider>(find.byType(BusinessHoursSlider))
          .onBreak({'start': '15:00', 'end': '17:00'});
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('개별'),
        -160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('개별'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(BusinessHoursSlider),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      tester
          .widget<BusinessHoursSlider>(find.byType(BusinessHoursSlider))
          .onHours(420, 1260);
      await tester.pumpAndSettle();
      await tester.tap(find.text('일주일 설정 저장'));
      await tester.pumpAndSettle();
      expect(written!['days']['1'][0]['start'], '07:00');
      expect(written!['days']['2'][0]['start'], '06:00');
      expect(written!['days']['1'][0]['id'], 'legacy-band-1-0');
      expect(written!['days']['7'], isEmpty);
      expect(written!['breaks']['1'], {'start': '15:00', 'end': '17:00'});
      expect(written!['breaks']['6'], {'start': '15:00', 'end': '17:00'});
      expect(written!['breaks'].containsKey('7'), false);
      expect(written!['revision'], 12);
    },
  );
  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets('vertical hours, default break, and enlarged text at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await (FontLoader('Pretendard')
            ..addFont(rootBundle.load('assets/fonts/PretendardVariable.ttf')))
          .load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      Map<String, dynamic>? pause;
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            textTheme: ThemeData.dark().textTheme.apply(
              fontFamily: 'Pretendard',
            ),
          ),
          home: Scaffold(
            body: RepaintBoundary(
              key: key,
              child: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 1200),
                  textScaler: const TextScaler.linear(1.5),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: StatefulBuilder(
                      builder: (context, refresh) => BusinessHoursSlider(
                        bands: const [
                          {'name': '오전', 'start': '06:00', 'end': '12:00'},
                          {'name': '오후', 'start': '12:00', 'end': '18:00'},
                          {'name': '저녁', 'start': '18:00', 'end': '22:00'},
                        ],
                        breakTime: pause,
                        enabled: true,
                        onHours: (_, _) {},
                        onBoundary: (_, _) {},
                        onBreak: (v) => refresh(() => pause = v),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('브레이크 타임'));
      await tester.pumpAndSettle();
      expect(pause, {'start': '15:00', 'end': '17:00'});
      expect(find.byType(RangeSlider), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '/tmp/tap-hours-${width.toInt()}.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    });
  }
}
