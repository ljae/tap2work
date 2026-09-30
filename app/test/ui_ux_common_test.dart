import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tap2work/ui/components.dart';

void main() {
  testWidgets('long status remains readable in a narrow card', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              child: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
                child: AppStatusPill(
                  label: '승인 대기 중인 근무 변경 신청',
                  icon: Icons.schedule,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final paragraph = tester.renderObject<RenderParagraph>(
      find.text('승인 대기 중인 근무 변경 신청'),
    );
    expect(paragraph.didExceedMaxLines, isFalse);
  });
  testWidgets('navigation labels stay complete at 320 with double text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 840);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    var selected = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: FloatingMenu(
            selectedIndex: 3,
            onSelected: (value) => selected = value,
            items: const [
              FloatingMenuItem('업무', Icons.check),
              FloatingMenuItem('매뉴얼', Icons.book),
              FloatingMenuItem('근무표', Icons.calendar_month),
              FloatingMenuItem('우리매장', Icons.store),
            ],
          ),
        ),
      ),
    );
    for (final label in ['업무', '매뉴얼', '근무표', '우리매장']) {
      expect(
        tester
            .renderObject<RenderParagraph>(find.text(label))
            .didExceedMaxLines,
        isFalse,
        reason: label,
      );
    }
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('floating-menu-3')));
    expect(selected, 3);
  });
  testWidgets(
    'account target is at least 48 and rich sheet heading is retained',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HeaderAccountButton())),
      );
      expect(
        tester.getSize(find.byType(HeaderAccountButton)).width,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSize(find.byType(HeaderAccountButton)).height,
        greaterThanOrEqualTo(48),
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: AppSheetPanel(
            title: Text.rich(TextSpan(text: '변경 내역')),
            content: Text('내용'),
          ),
        ),
      );
      expect(find.text('변경 내역'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'picker preserves selection and disables interaction while saving',
    (tester) async {
      String? selection = 'a';
      Widget picker(bool saving) => MaterialApp(
        home: Scaffold(
          body: AppPicker<String>(
            label: '크루',
            value: selection,
            items: const [
              DropdownMenuItem(value: 'a', child: Text('크루 A')),
              DropdownMenuItem(value: 'b', child: Text('크루 B')),
            ],
            onChanged: saving ? null : (value) => selection = value,
          ),
        ),
      );
      await tester.pumpWidget(picker(true));
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '크루 A'))
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '크루 B'))
            .onSelected,
        isNull,
      );
      await tester.tap(find.text('크루 B'));
      expect(selection, 'a');
      await tester.pumpWidget(picker(false));
      await tester.tap(find.text('크루 B'));
      expect(selection, 'b');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('common choice families wrap long labels at large text', (
    tester,
  ) async {
    const label = '시간대·파트 자동 배정';
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          chipTheme: const ChipThemeData(
            showCheckmark: false,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              child: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
                child: Column(
                  children: [
                    AppPillField<String>(
                      initialValue: 'a',
                      items: const [
                        DropdownMenuItem(value: 'a', child: Text(label)),
                      ],
                      onChanged: (_) {},
                    ),
                    AppSegmented<String>(
                      segments: const [
                        ButtonSegment(value: 'a', label: Text(label)),
                      ],
                      selected: const {'a'},
                      onSelectionChanged: (_) {},
                    ),
                    AppChoiceGroup<String>(
                      values: const ['a'],
                      selected: 'a',
                      labelOf: (_) => label,
                      onSelected: (_) {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    for (final element in find.text(label).evaluate()) {
      final paragraph = element.renderObject! as RenderParagraph;
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(paragraph.size.width, lessThanOrEqualTo(180));
      final measured = TextPainter(
        text: paragraph.text,
        textDirection: TextDirection.ltr,
        textScaler: paragraph.textScaler,
      )..layout(maxWidth: paragraph.size.width);
      expect(
        paragraph.size.height,
        greaterThanOrEqualTo(measured.height),
        reason: 'Chip must not clip wrapped lines vertically',
      );
      measured.dispose();
    }
    expect(tester.takeException(), isNull);
  });
}
