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
    final max = start + 1410;
    final pauseStart = breakTime == null
        ? 900
        : hoursMinute(breakTime!['start']);
    final bs = pauseStart < start ? pauseStart + 1440 : pauseStart;
    var be = breakTime == null ? 1020 : hoursMinute(breakTime!['end']);
    if (be <= bs) be += 1440;
    final validBreak = breakTime != null && bs >= start && be <= end;
    String time(int minute) =>
        '${minute >= 1440 ? '다음 날 ' : ''}${hoursTime(minute)}';
    Widget vertical(
      String label,
      RangeValues values,
      double min,
      double max,
      ValueChanged<RangeValues>? change,
    ) => Semantics(
      label: label,
      child: SizedBox(
        height: 304,
        width: 56,
        child: RotatedBox(
          quarterTurns: 1,
          child: RangeSlider(
            activeColor: label.startsWith('브레이크')
                ? AppColors.accent
                : AppColors.green,
            values: values,
            min: min,
            max: max,
            divisions: ((max - min) / 30).round(),
            labels: RangeLabels(
              time(values.start.round()),
              time(values.end.round()),
            ),
            semanticFormatterCallback: (v) => time(v.round()),
            onChanged: change,
          ),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            AppTimeField(
              label: '영업 시작',
              value: hoursTime(start),
              onChanged: enabled
                  ? (value) {
                      final nextStart = hoursMinute(value);
                      var nextEnd = hoursMinute(bands.last['end']);
                      if (nextEnd <= nextStart) nextEnd += 1440;
                      if (nextEnd - nextStart < 1440) {
                        onHours(nextStart, nextEnd);
                      }
                    }
                  : null,
            ),
            AppTimeField(
              label: '영업 종료',
              value: hoursTime(end),
              onChanged: enabled
                  ? (value) {
                      var nextEnd = hoursMinute(value);
                      if (nextEnd <= start) nextEnd += 1440;
                      if (nextEnd - start < 1440) onHours(start, nextEnd);
                    }
                  : null,
            ),
          ],
        ),
        if (end >= 1440) Text('종료 ${time(end)}', style: AppText.caption),
        const SizedBox(height: 8),
        const Text('위·아래 손잡이로 시작과 종료를 조정해요. 30분 단위예요.', style: AppText.caption),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            vertical(
              '영업시간 슬라이더',
              RangeValues(start.toDouble(), end.toDouble()),
              0,
              max.toDouble(),
              enabled
                  ? (v) {
                      if (v.end - v.start >= bands.length * 30 &&
                          v.end - v.start < 1440 &&
                          v.start < 1440) {
                        onHours(v.start.round(), v.end.round());
                      }
                    }
                  : null,
            ),
            Expanded(
              child: SizedBox(
                height: 304,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Stack(
                    children: [
                      for (var i = 0; i < bands.length; i++)
                        Builder(
                          builder: (_) {
                            var s = hoursMinute(bands[i]['start']);
                            if (s < start) s += 1440;
                            var e = hoursMinute(bands[i]['end']);
                            if (e <= s) e += 1440;
                            return Positioned(
                              top: s / max * 256,
                              height: (e - s) / max * 256,
                              left: 0,
                              right: 0,
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.green.withValues(
                                    alpha: i.isEven ? .25 : .45,
                                  ),
                                  border: const Border(
                                    bottom: BorderSide(
                                      color: AppColors.paper,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child:
                                    (e - s) / max * 256 >=
                                        28 *
                                            MediaQuery.textScalerOf(
                                              context,
                                            ).scale(1)
                                    ? Text(
                                        '${bands[i]['name']}',
                                        style: AppText.caption,
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                      if (validBreak)
                        Positioned(
                          top: bs / max * 256,
                          height: ((be - bs) / max * 256).toDouble(),
                          left: 0,
                          right: 0,
                          child: Container(
                            alignment: Alignment.center,
                            color: AppColors.accent.withValues(alpha: .9),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (validBreak)
              vertical(
                '브레이크 타임 슬라이더',
                RangeValues(bs.toDouble(), be.toDouble()),
                0,
                max.toDouble(),
                enabled
                    ? (v) {
                        if (v.end - v.start >= 30 &&
                            v.start >= start &&
                            v.end <= end) {
                          onBreak({
                            'start': hoursTime(v.start.round()),
                            'end': hoursTime(v.end.round()),
                          });
                        }
                      }
                    : null,
              ),
          ],
        ),
        for (final band in bands)
          Text(
            '${band['name']} · ${band['start']}–${band['end']}',
            style: AppText.caption,
          ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('브레이크 타임'),
          value: breakTime != null,
          subtitle: Text(
            breakTime == null
                ? '기본 오후 3시–5시 · 영업시간 안에서 적용'
                : '${breakTime!['start']}–${breakTime!['end']} · 필요 인원에서 제외',
          ),
          onChanged: enabled
              ? (v) {
                  if (v != true) {
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
        for (
          var i = 0;
          i < bands.length - 1 &&
              bands.length <= 3 &&
              end - start >= bands.length * 30;
          i++
        ) ...[
          Text(
            '${bands[i]['name']} / ${bands[i + 1]['name']} 교대',
            style: AppText.caption,
          ),
          Builder(
            builder: (_) {
              var v = hoursMinute(bands[i]['end']);
              if (v <= start) v += 1440;
              final low = start + (i + 1) * 30;
              final high = end - (bands.length - i - 1) * 30;
              return Slider(
                min: low.toDouble(),
                max: high.toDouble(),
                divisions: high > low ? (high - low) ~/ 30 : null,
                value: v.clamp(low, high).toDouble(),
                label: time(v),
                onChanged: enabled && high > low
                    ? (v) => onBoundary(i, v.round())
                    : null,
              );
            },
          ),
        ],
      ],
    );
  }
}
