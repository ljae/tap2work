import 'package:flutter/material.dart';
import 'components.dart';
import 'time_wheel.dart';

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
  });
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
    // A continuous 24-hour axis also supports overnight opening windows.
    final origin = end > 1440 ? start : 0;
    int absolute(String value) {
      final minute = hoursMinute(value);
      return minute < start ? minute + 1440 : minute;
    }

    String display(int value) =>
        '${value >= 1440 ? '다음 날 ' : ''}${hoursTime(value)}';
    final cuts = [
      start,
      for (final b in bands.take(bands.length - 1)) absolute(b['end']),
      end,
    ];
    void change(int i, int minute) {
      if (!enabled) return;
      if (i == 0) {
        if (minute >= 0 &&
            minute < end &&
            end - minute < 1440 &&
            end - minute >= bands.length * 30) {
          onHours(minute, end);
        }
      } else if (i == cuts.length - 1) {
        if (minute > start &&
            minute - start < 1440 &&
            minute - start >= bands.length * 30) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < cuts.length; i++)
              TextButton(
                onPressed: enabled ? () => choose(i) : null,
                child: Text(
                  '${i == 0
                      ? '시작'
                      : i == cuts.length - 1
                      ? '종료'
                      : '교대'} ${display(cuts[i])}',
                ),
              ),
          ],
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth - 48;
            double x(int value) => (value - origin) / 1440 * width + 24;
            return SizedBox(
              height: 112,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 24,
                    right: 24,
                    top: 24,
                    height: 40,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  for (var i = 0; i < cuts.length - 1; i++)
                    Positioned(
                      left: x(cuts[i]),
                      width: (cuts[i + 1] - cuts[i]) / 1440 * width,
                      top: 24,
                      height: 40,
                      child: ColoredBox(
                        color: AppColors.green.withValues(
                          alpha: i.isEven ? .35 : .6,
                        ),
                      ),
                    ),
                  if (breakTime != null &&
                      absolute(breakTime!['start']) >= start &&
                      absolute(breakTime!['end']) <= end)
                    Positioned(
                      left: x(absolute(breakTime!['start'])),
                      width:
                          (absolute(breakTime!['end']) -
                                  absolute(breakTime!['start']))
                              .clamp(0, 1440) /
                          1440 *
                          width,
                      top: 56,
                      height: 8,
                      child: const ColoredBox(color: AppColors.accent),
                    ),
                  for (var i = 0; i < cuts.length; i++)
                    Positioned(
                      left: x(cuts[i]) - 24,
                      top: 20,
                      width: 48,
                      height: 48,
                      child: Semantics(
                        label: i == 0
                            ? '영업 시작'
                            : i == cuts.length - 1
                            ? '영업 종료'
                            : '교대 $i',
                        value: display(cuts[i]),
                        increasedValue: display(cuts[i] + 30),
                        decreasedValue: display(cuts[i] - 30),
                        onIncrease: enabled
                            ? () => change(i, cuts[i] + 30)
                            : null,
                        onDecrease: enabled
                            ? () => change(i, cuts[i] - 30)
                            : null,
                        child: GestureDetector(
                          key: ValueKey('hours-thumb-$i'),
                          behavior: HitTestBehavior.opaque,
                          onHorizontalDragUpdate: enabled
                              ? (details) {
                                  final box =
                                      context.findRenderObject() as RenderBox;
                                  final local = box
                                      .globalToLocal(details.globalPosition)
                                      .dx;
                                  final minute =
                                      (origin +
                                      ((local - 24) / width * 1440) / 30 * 30);
                                  change(i, (minute / 30).round() * 30);
                                }
                              : null,
                          child: IconButton(
                            tooltip: display(cuts[i]),
                            onPressed: enabled ? () => choose(i) : null,
                            icon: Container(
                              width: 6,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.green,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  for (var h = 0; h <= 24; h += 6)
                    Positioned(
                      left: x(origin + h * 60) - 24,
                      top: 80,
                      width: 48,
                      child: Text(
                        origin == 0 && h == 24
                            ? '24:00'
                            : hoursTime(origin + h * 60),
                        textAlign: TextAlign.center,
                        style: AppText.caption,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            for (final band in bands)
              Text('${band['name']}', style: AppText.caption),
          ],
        ),
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
        if (breakTime != null) ...[
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              AppTimeField(
                label: '휴식 시작',
                value: breakTime!['start'],
                onChanged: enabled
                    ? (v) => onBreak({...breakTime!, 'start': v})
                    : null,
              ),
              AppTimeField(
                label: '휴식 종료',
                value: breakTime!['end'],
                onChanged: enabled
                    ? (v) => onBreak({...breakTime!, 'end': v})
                    : null,
              ),
            ],
          ),
        ],
      ],
    );
  }
}
