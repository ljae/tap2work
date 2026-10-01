import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../domain/part_schedule.dart';
import '../state/operations_controller.dart';
import 'components.dart';
import 'crew_colors.dart';

/// Weekly draft editor. It never writes operations until the parent saves.
class CrewWeekGrid extends StatelessWidget {
  const CrewWeekGrid({
    super.key,
    required this.entries,
    required this.crewId,
    required this.boundary,
    required this.editable,
    required this.partName,
    required this.onAdd,
    required this.onEdit,
  });
  final List<Json> entries;
  final String crewId, boundary;
  final bool editable;
  final String Function(String) partName;
  final void Function(int day, int minute) onAdd;
  final void Function(int day, Json entry) onEdit;
  int start(Json e) {
    final m = rosterMinute(e['start']);
    return m < rosterMinute(boundary) ? m + 1440 : m;
  }

  int end(Json e) {
    var m = rosterMinute(e['end']);
    while (m <= start(e)) {
      m += 1440;
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final from =
        entries.fold<int>(
          math.max(540, rosterMinute(boundary)),
          (m, e) => math.min(m, start(e)),
        ) ~/
        60 *
        60;
    final until =
        ((entries.fold<int>(
                  math.max(1320, from + 60),
                  (m, e) => math.max(m, end(e)),
                ) +
                59) ~/
            60) *
        60;
    const scale = 1.6;
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final header = 56.0 * textScale;
    final height = (until - from) * scale;
    return SizedBox(
      key: const ValueKey('crew-week-grid'),
      height: 520,
      child: SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 64,
              child: Column(
                children: [
                  SizedBox(
                    height: header,
                    child: const Center(
                      child: Text('시간', style: AppText.caption),
                    ),
                  ),
                  SizedBox(
                    height: height + 24,
                    child: Stack(
                      children: [
                        for (var m = from; m <= until; m += 60)
                          Positioned(
                            top: (m - from) * scale,
                            left: 0,
                            child: Text(
                              '${m >= 1440 ? '+' : ''}${rosterClock(m)}',
                              style: AppText.caption,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final baseWidth = math.max(
                    144.0 * textScale,
                    constraints.maxWidth / 7,
                  );
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var day = 1; day <= 7; day++)
                          dayColumn(
                            day,
                            from,
                            until,
                            scale,
                            baseWidth,
                            header,
                            height,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget dayColumn(
    int day,
    int from,
    int until,
    double scale,
    double width,
    double header,
    double height,
  ) {
    final rows = entries.where((e) => e['weekday'] == day).toList()
      ..sort((a, b) => start(a).compareTo(start(b)));
    final ends = <int>[];
    final lanes = <int>[];
    for (final row in rows) {
      var lane = ends.indexWhere((m) => m <= start(row));
      if (lane < 0) {
        lane = ends.length;
        ends.add(end(row));
      } else {
        ends[lane] = end(row);
      }
      lanes.add(lane);
    }
    final count = math.max(1, ends.length);
    final color = crewColor(crewId);
    return SizedBox(
      width: width * count,
      child: Column(
        children: [
          Container(
            height: header,
            alignment: Alignment.center,
            color: AppColors.surface,
            child: Text(
              '${const ['월', '화', '수', '목', '금', '토', '일'][day - 1]}요일',
              style: AppText.body,
            ),
          ),
          SizedBox(
            height: height + 24,
            child: Stack(
              children: [
                for (var m = from; m < until; m += 30)
                  Positioned(
                    top: (m - from) * scale,
                    left: 0,
                    right: 0,
                    height: 48,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: ValueKey('crew-cell-$day-$m'),
                        onTap: editable ? () => onAdd(day, m) : null,
                        child: Semantics(
                          button: editable,
                          label:
                              '${const ['월', '화', '수', '목', '금', '토', '일'][day - 1]}요일 ${rosterClock(m)} 배정 추가',
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: AppColors.line),
                                right: BorderSide(color: AppColors.line),
                              ),
                            ),
                            child: m == from && rows.isEmpty
                                ? const Center(
                                    child: Text('+ 배정', style: AppText.caption),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                for (var i = 0; i < rows.length; i++)
                  Positioned(
                    top: (start(rows[i]) - from) * scale + 2,
                    left: lanes[i] * width + 3,
                    width: width - 6,
                    height: (end(rows[i]) - start(rows[i])) * scale - 4,
                    child: Material(
                      color: color.withValues(alpha: .16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: color),
                      ),
                      child: InkWell(
                        onTap: editable ? () => onEdit(day, rows[i]) : null,
                        borderRadius: BorderRadius.circular(12),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                partName(rows[i]['partId']),
                                style: AppText.body,
                              ),
                              Text(
                                '${rows[i]['start']}–${end(rows[i]) >= 1440 ? '다음날 ' : ''}${rows[i]['end']}',
                                style: AppText.caption,
                              ),
                              Text(
                                '배정',
                                style: AppText.caption.copyWith(color: color),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
