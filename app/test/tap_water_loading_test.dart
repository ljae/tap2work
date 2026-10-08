import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tap2work/ui/tap_water_loading.dart';

void main() {
  testWidgets(
    'water moves, pauses for reduced motion and disposes its ticker',
    (tester) async {
      Future<void> show(bool reduce) => tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduce),
            child: const Center(child: TapWaterLoading()),
          ),
        ),
      );
      double phase() =>
          (tester
                      .widget<CustomPaint>(
                        find.descendant(
                          of: find.byType(TapWaterLoading),
                          matching: find.byType(CustomPaint),
                        ),
                      )
                      .painter!
                  as TapWaterPainter)
              .phase
              .value;
      await show(false);
      await tester.pump(const Duration(milliseconds: 400));
      final before = phase();
      await tester.pump(const Duration(milliseconds: 400));
      expect(phase(), isNot(before));
      await show(true);
      final still = phase();
      await tester.pump(const Duration(seconds: 2));
      expect(phase(), still);
      await show(false);
      await tester.pump(const Duration(milliseconds: 400));
      expect(phase(), isNot(still));
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );
}
