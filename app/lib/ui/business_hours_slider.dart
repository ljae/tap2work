import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'components.dart';
import 'time_wheel.dart';

String shiftLabel(int index, int count) => count == 1
    ? '오픈'
    : index == 0
    ? '오픈'
    : index == count - 1
    ? '마감'
    : '미들';

int hoursMinute(String value) {
  final pieces = value.split(':').map(int.parse).toList();
  return pieces[0] * 60 + pieces[1];
}

String hoursTime(int value) =>
    '${(value ~/ 60 % 24).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}';

/// Prefer midday / evening boundaries; short and overnight days stay usable.
List<int> shiftBoundaries(int start, int end, int count) {
  final preferred = count == 2 ? [15 * 60] : [12 * 60, 18 * 60];
  final result = <int>[start];
  for (var i = 1; i < count; i++) {
    final candidate = preferred[i - 1];
    final fallback = start + ((end - start) * i / count / 30).round() * 30;
    result.add(
      (candidate > result.last && candidate < end ? candidate : fallback).clamp(
        result.last + 30,
        end - (count - i) * 30,
      ),
    );
  }
  return [...result, end];
}

class BusinessHoursSlider extends StatelessWidget {
  const BusinessHoursSlider({
    super.key,
    required this.bands,
    required this.breakTime,
    required this.enabled,
    required this.onHours,
    required this.onBreak,
    required this.onBoundary,
    this.shiftControls,
  });
  final Widget? shiftControls;
  final List<Map<String, dynamic>> bands;
  final Map<String, dynamic>? breakTime;
  final bool enabled;
  final void Function(int, int) onHours;
  final void Function(Map<String, dynamic>?) onBreak;
  final void Function(int, int) onBoundary;

  @override
  Widget build(BuildContext context) {
    final start = hoursMinute(bands.first['start']);
    var end = hoursMinute(bands.last['end']);
    if (end <= start) end += 1440;
    final origin = end > 1440 ? start : 0;
    int absolute(String value) {
      final minute = hoursMinute(value);
      return minute < start ? minute + 1440 : minute;
    }

    final cuts = [
      start,
      for (final b in bands.take(bands.length - 1)) absolute(b['end']),
      end,
    ];
    void change(int i, int minute) {
      if (!enabled) return;
      if (i == 0) {
        if (minute >= 0 &&
            minute < 1440 &&
            end - minute < 1440 &&
            end - minute >= bands.length * 30) {
          onHours(minute, end);
        }
      } else if (i == cuts.length - 1) {
        if (minute - start < 1440 && minute - start >= bands.length * 30) {
          onHours(start, minute);
        }
      } else if (minute >= cuts[i - 1] + 30 && minute <= cuts[i + 1] - 30) {
        onBoundary(i - 1, minute);
      }
    }

    Future<void> choose(int i) async {
      final value = await showTimeWheel(
        context,
        title: i == 0
            ? '영업 시작'
            : i == cuts.length - 1
            ? '영업 종료'
            : '교대 시간',
        value: hoursTime(cuts[i]),
      );
      if (value == null) return;
      var minute = hoursMinute(value);
      if (i > 0 && minute <= start) minute += 1440;
      change(i, minute);
    }

    final pause = breakTime == null
        ? null
        : [absolute(breakTime!['start']), absolute(breakTime!['end'])];
    void changeBreak(int i, int minute) {
      if (!enabled || pause == null) return;
      final next = [...pause];
      next[i] = minute.clamp(
        i == 0 ? start : next[0] + 30,
        i == 0 ? next[1] - 30 : end,
      );
      onBreak({'start': hoursTime(next[0]), 'end': hoursTime(next[1])});
    }

    Future<void> chooseBreak(int i) async {
      final value = await showTimeWheel(
        context,
        title: i == 0 ? '브레이크 시작' : '브레이크 종료',
        value: hoursTime(pause![i]),
      );
      if (value != null) changeBreak(i, absolute(value));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HoursTrack(
          origin: origin,
          values: cuts,
          color: AppColors.green,
          enabled: enabled,
          names: [
            for (var i = 0; i < bands.length; i++) shiftLabel(i, bands.length),
          ],
          onChange: change,
          onChoose: choose,
          id: 'hours',
          reference: pause,
        ),
        ?shiftControls,
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('브레이크 타임'),
          value: breakTime != null,
          onChanged: enabled
              ? (value) {
                  if (!value) {
                    onBreak(null);
                    return;
                  }
                  final s = 900 >= start && 1020 <= end ? 900 : start;
                  onBreak({
                    'start': hoursTime(s),
                    'end': hoursTime((s + 120).clamp(s + 30, end)),
                  });
                }
              : null,
        ),
        if (pause != null)
          _HoursTrack(
            origin: origin,
            values: pause,
            color: AppColors.amber,
            enabled: enabled,
            names: const [],
            sizingNames: [
              for (var i = 0; i < bands.length; i++)
                shiftLabel(i, bands.length),
            ],
            sizingValues: cuts,
            onChange: changeBreak,
            onChoose: chooseBreak,
            id: 'break',
            below: true,
          ),
      ],
    );
  }
}

/// One 24-hour track for both shifts and breaks. Times belong to their handles;
/// staggered labels keep short/overnight intervals readable without duplicate fields.
class _HoursTrack extends StatelessWidget {
  const _HoursTrack({
    required this.origin,
    required this.values,
    required this.color,
    required this.enabled,
    required this.names,
    required this.onChange,
    required this.onChoose,
    required this.id,
    this.below = false,
    this.sizingNames,
    this.sizingValues,
    this.reference,
  });
  final List<int>? reference;
  final int origin;
  final List<int> values;
  final Color color;
  final bool enabled, below;
  final List<String> names;
  final List<String>? sizingNames;
  final List<int>? sizingValues;
  final void Function(int, int) onChange;
  final void Function(int) onChoose;
  final String id;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scaler = MediaQuery.textScalerOf(context);
      final style = AppText.caption.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      );
      double measure(String text) => (TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout()).width;
      // Only exceptionally short shifts or enlarged labels need horizontal scrolling.
      var width = constraints.maxWidth;
      final sizeNames = sizingNames ?? names;
      final sizeValues = sizingValues ?? values;
      for (var i = 0; i < sizeNames.length; i++) {
        final duration = sizeValues[i + 1] - sizeValues[i];
        if (duration > 0) {
          width = math.max(
            width,
            (measure(sizeNames[i]) + 8) * 1440 / duration,
          );
        }
      }
      final textWidth = math.max(
        measure('00:00'),
        values.any((v) => v >= 1440) ? measure('다음 날') : 0.0,
      );
      final labelWidth = math.max(48.0, textWidth + 8);
      final textInset = (labelWidth - textWidth) / 2;
      final labelHeight = math.max(48.0, scaler.scale(13) * 3.2);
      double x(int minute) => (minute - origin) / 1440 * width;
      final lanes = <double>[];
      final placements = <({double left, int lane})>[];
      for (final minute in values) {
        final left = (x(minute) - labelWidth / 2).clamp(
          0.0,
          width - labelWidth,
        );
        var lane = 0;
        while (lane < lanes.length &&
            lanes[lane] - textInset + 4 > left + textInset) {
          lane++;
        }
        if (lane == lanes.length) {
          lanes.add(0);
        }
        lanes[lane] = left + labelWidth;
        placements.add((left: left, lane: lane));
      }
      final labelArea = lanes.length * labelHeight;
      final barTop = below ? 12.0 : labelArea + 8;
      final barHeight = below ? 8.0 : math.max(48.0, scaler.scale(13) * 2);
      final height = barHeight + labelArea + 28;
      String label(int i) => below
          ? (i == 0 ? '브레이크 시작' : '브레이크 종료')
          : i == 0
          ? '영업 시작'
          : i == values.length - 1
          ? '영업 종료'
          : '교대 $i';
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: barTop,
                height: barHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.elevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              for (var h = 0; h <= 24; h += 6)
                Positioned(
                  left: (h / 24 * width).clamp(0, width - 1),
                  top: barTop,
                  height: barHeight,
                  width: 1,
                  child: const ColoredBox(color: AppColors.controlLine),
                ),
              for (var i = 0; i < values.length - 1; i++)
                Positioned(
                  left: x(values[i]),
                  top: barTop,
                  width: math.max(0, x(values[i + 1]) - x(values[i])),
                  height: barHeight,
                  child: Container(
                    alignment: Alignment.center,
                    color: below
                        ? color
                        : color.withValues(alpha: i.isEven ? .25 : .4),
                    child: names.isEmpty
                        ? null
                        : Text(
                            names[i],
                            style: style.copyWith(color: AppColors.ink),
                            textAlign: TextAlign.center,
                          ),
                  ),
                ),
              if (reference != null)
                Positioned(
                  key: const ValueKey('hours-break-reference'),
                  left: x(reference![0]),
                  top: barTop + barHeight - 8,
                  width: math.max(0, x(reference![1]) - x(reference![0])),
                  height: 8,
                  child: const IgnorePointer(
                    child: Tooltip(
                      message: '브레이크 타임 · 교대와 별도',
                      child: ColoredBox(color: AppColors.amber),
                    ),
                  ),
                ),
              for (var i = 0; i < values.length; i++) ...[
                Positioned(
                  left: (x(values[i]) - 1).clamp(0, width - 2),
                  top: below
                      ? barTop
                      : labelArea -
                            (placements[i].lane + 1) * labelHeight +
                            labelHeight -
                            6,
                  width: 2,
                  height: below
                      ? barHeight + 8 + placements[i].lane * labelHeight
                      : barHeight + 14 + placements[i].lane * labelHeight,
                  child: ColoredBox(color: color),
                ),
                Positioned(
                  left: placements[i].left,
                  top: below
                      ? barTop +
                            barHeight +
                            8 +
                            placements[i].lane * labelHeight
                      : labelArea - (placements[i].lane + 1) * labelHeight,
                  width: labelWidth,
                  height: labelHeight,
                  child: _TimeHandle(
                    key: ValueKey('$id-label-$i'),
                    value: values[i],
                    width: width,
                    enabled: enabled,
                    label: label(i),
                    onChange: (value) => onChange(i, value),
                    onChoose: () => onChoose(i),
                    child: Center(
                      child: Text(
                        '${values[i] >= 1440 ? '다음 날\n' : ''}${hoursTime(values[i])}',
                        style: style,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: (x(values[i]) - 24).clamp(0, width - 48),
                  top: barTop + barHeight / 2 - 24,
                  width: 48,
                  height: 48,
                  child: ExcludeSemantics(
                    child: _TimeHandle(
                      key: ValueKey('$id-thumb-$i'),
                      value: values[i],
                      width: width,
                      enabled: enabled,
                      label: label(i),
                      onChange: (value) => onChange(i, value),
                      onChoose: () => onChoose(i),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class _TimeHandle extends StatefulWidget {
  const _TimeHandle({
    super.key,
    required this.value,
    required this.width,
    required this.enabled,
    required this.label,
    required this.onChange,
    required this.onChoose,
    required this.child,
  });
  final int value;
  final double width;
  final bool enabled;
  final String label;
  final ValueChanged<int> onChange;
  final VoidCallback onChoose;
  final Widget child;
  @override
  State<_TimeHandle> createState() => _TimeHandleState();
}

class _TimeHandleState extends State<_TimeHandle> {
  double dragX = 0;
  int dragValue = 0;
  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.label,
    value: hoursTime(widget.value),
    increasedValue: hoursTime(widget.value + 30),
    decreasedValue: hoursTime(widget.value - 30),
    onIncrease: widget.enabled
        ? () => widget.onChange(widget.value + 30)
        : null,
    onDecrease: widget.enabled
        ? () => widget.onChange(widget.value - 30)
        : null,
    child: GestureDetector(
      dragStartBehavior: DragStartBehavior.down,
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: widget.enabled
          ? (details) {
              dragX = details.globalPosition.dx;
              dragValue = widget.value;
            }
          : null,
      onHorizontalDragUpdate: widget.enabled
          ? (details) {
              final delta =
                  (details.globalPosition.dx - dragX) / widget.width * 1440;
              widget.onChange(((dragValue + delta) / 30).round() * 30);
            }
          : null,
      child: TextButton(
        onPressed: widget.enabled ? widget.onChoose : null,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(48, 48),
        ),
        child: widget.child,
      ),
    ),
  );
}
