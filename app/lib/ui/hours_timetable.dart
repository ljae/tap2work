import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import '../domain/part_schedule.dart';
import 'components.dart';
import 'time_wheel.dart';

class HoursTimetable extends StatefulWidget {
  const HoursTimetable({
    super.key,
    required this.days,
    required this.parts,
    required this.partId,
    required this.boundary,
    required this.editable,
    required this.onChange,
  });
  final Json days;
  final List<Json> parts;
  final String? partId;
  final String boundary;
  final bool editable;
  final void Function(int day, String id, String start, String end) onChange;
  @override
  State<HoursTimetable> createState() => _HoursTimetableState();
}

class _HoursTimetableState extends State<HoursTimetable> {
  static const scale = 1.6;
  String? dragging;
  int? preview;
  double delta = 0;
  double get headerHeight => MediaQuery.textScalerOf(context).scale(16) * 3.5;
  int get boundary => rosterMinute(widget.boundary);
  int start(Json row) {
    final n = rosterMinute(row['start']);
    return n < boundary ? n + 1440 : n;
  }

  int end(Json row) {
    var n = rosterMinute(row['end']);
    while (n <= start(row)) {
      n += 1440;
    }
    return n;
  }

  List<Json> rows(int day) =>
      (widget.days['$day'] as List)
          .cast<Json>()
          .where(
            (r) =>
                widget.partId == null ||
                (r['headcounts']?[widget.partId] ??
                        (r['custom'] == true ? 0 : 1)) >
                    0,
          )
          .map(
            (r) => <String, dynamic>{
              ...r,
              if (widget.partId != null)
                ...?r['partTimes']?[widget.partId] as Map<String, dynamic>?,
            },
          )
          .toList()
        ..sort((a, b) => start(a).compareTo(start(b)));
  String clock(int minute) =>
      '${minute >= 1440 ? '다음날 ' : ''}${rosterClock(minute)}';
  Future<void> edit(int day, Json row) async {
    await showAppFormSheet<void>(
      context: context,
      builder: (c) => AppSheetPanel(
        title: Text('${row['name']} 시간'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTimeField(
              label: '시작',
              value: row['start'],
              onChanged: (v) {
                if (v != row['end']) {
                  widget.onChange(day, row['id'], v, row['end']);
                  Navigator.pop(c);
                }
              },
            ),
            AppTimeField(
              label: '종료',
              value: row['end'],
              onChanged: (v) {
                if (v != row['start']) {
                  widget.onChange(day, row['id'], row['start'], v);
                  Navigator.pop(c);
                }
              },
            ),
            const Text(
              '선택한 블록만 바뀌어요. 겹침과 빈 구간은 시간표에서 확인해 주세요.',
              style: AppText.caption,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget handle(int day, Json row, bool first, int a, int b) {
    final key = '$day/${row['id']}/${first ? 'start' : 'end'}';
    return Semantics(
      label: '${row['name']} ${first ? '시작' : '종료'} 시간 조정',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: widget.editable
            ? (_) => setState(() {
                dragging = key;
                preview = first ? a : b;
                delta = 0;
              })
            : null,
        onVerticalDragUpdate: widget.editable
            ? (d) => setState(() {
                delta += d.delta.dy;
                preview = ((first ? a : b) + (delta / scale / 30).round() * 30)
                    .clamp(
                      first ? boundary : a + 30,
                      first ? b - 30 : math.min(a + 1410, boundary + 1440),
                    );
              })
            : null,
        onVerticalDragEnd: widget.editable
            ? (_) {
                final value = preview;
                setState(() {
                  dragging = null;
                  preview = null;
                });
                if (value != null) {
                  widget.onChange(
                    day,
                    row['id'],
                    rosterClock(first ? value : a),
                    rosterClock(first ? b : value),
                  );
                }
              }
            : null,
        onVerticalDragCancel: () => setState(() {
          dragging = null;
          preview = null;
        }),
        child: SizedBox(
          height: math.min(24, (b - a) * scale / 4),
          width: double.infinity,
          child: Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = [for (var d = 1; d <= 7; d++) ...rows(d)];
    final minMinute = all.isEmpty
        ? boundary
        : math.max(boundary, (all.map(start).reduce(math.min) ~/ 60) * 60);
    final maxMinute = all.isEmpty
        ? boundary + 720
        : math.max(
            minMinute + 60,
            ((all.map(end).reduce(math.max) + 59) ~/ 60) * 60,
          );
    final height = (maxMinute - minMinute) * scale;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('요일별 시간표 · 좌우·위아래로 이동', style: AppText.caption),
          if (dragging != null && preview != null)
            Text('적용 예정 ${clock(preview!)}', style: AppText.body),
          SizedBox(
            height: 480,
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 64,
                    child: Column(
                      children: [
                        SizedBox(height: headerHeight),
                        SizedBox(
                          height: height,
                          child: Stack(
                            children: [
                              for (var m = minMinute; m < maxMinute; m += 60)
                                Positioned(
                                  top: (m - minMinute) * scale,
                                  left: 0,
                                  child: Text(
                                    clock(m).replaceFirst('다음날 ', '+1\n'),
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
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var day = 1; day <= 7; day++)
                            dayColumn(day, minMinute, height),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget dayColumn(int day, int minMinute, double height) {
    final list = rows(day);
    final lanes = <int>[];
    final laneEnds = <int>[];
    for (final row in list) {
      var lane = laneEnds.indexWhere((e) => e <= start(row));
      if (lane < 0) {
        lane = laneEnds.length;
        laneEnds.add(end(row));
      } else {
        laneEnds[lane] = end(row);
      }
      lanes.add(lane);
    }
    final gaps = <(int, int)>[];
    var coveredUntil = list.isEmpty ? 0 : start(list.first);
    for (final row in list) {
      if (start(row) > coveredUntil) gaps.add((coveredUntil, start(row)));
      coveredUntil = math.max(coveredUntil, end(row));
    }
    final width = math.max(1, laneEnds.length) * 132.0;
    return SizedBox(
      width: width,
      child: Column(
        children: [
          SizedBox(
            height: headerHeight,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ['월', '화', '수', '목', '금', '토', '일'][day - 1],
                    style: AppText.body,
                  ),
                  if (laneEnds.length > 1)
                    const Text('겹침 · 인원 합산', style: AppText.caption),
                ],
              ),
            ),
          ),
          SizedBox(
            height: height,
            child: Stack(
              children: [
                for (var m = 0.0; m < height; m += 60 * scale)
                  Positioned(
                    top: m,
                    left: 0,
                    right: 0,
                    child: const Divider(height: 1),
                  ),
                if (list.isEmpty)
                  const Positioned(
                    top: 8,
                    left: 12,
                    child: Text('휴무', style: AppText.caption),
                  ),
                for (final gap in gaps)
                  Positioned(
                    top: (gap.$1 - minMinute) * scale,
                    left: 4,
                    right: 4,
                    height: (gap.$2 - gap.$1) * scale,
                    child: Container(
                      color: AppColors.muted.withValues(alpha: .08),
                      child: SingleChildScrollView(
                        child: Text(
                          '빈 구간 ${clock(gap.$1)}–${clock(gap.$2)}',
                          style: AppText.caption,
                        ),
                      ),
                    ),
                  ),
                for (var i = 0; i < list.length; i++)
                  block(day, list[i], lanes[i], minMinute),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget block(int day, Json row, int lane, int minMinute) {
    final a = start(row), b = end(row);
    final key = '$day/${row['id']}';
    final shownA = dragging == '$key/start' ? preview ?? a : a,
        shownB = dragging == '$key/end' ? preview ?? b : b;
    final color = [AppColors.green, AppColors.blue, AppColors.accent][lane % 3];
    return Positioned(
      top: (shownA - minMinute) * scale,
      left: lane * 132.0 + 4,
      width: 124,
      height: (shownB - shownA) * scale,
      child: Material(
        color: color.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: widget.editable ? () => edit(day, row) : null,
          child: Column(
            children: [
              handle(day, row, true, a, b),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(row['name'], style: AppText.body),
                        Text(
                          '${clock(shownA)}\n${clock(shownB)}',
                          style: AppText.caption,
                        ),
                        if (widget.partId == null)
                          for (final p in widget.parts.where(
                            (p) =>
                                p['hidden'] != true &&
                                (row['headcounts']?[p['id']] ??
                                        (row['custom'] == true ? 0 : 1)) >
                                    0,
                          ))
                            Text(
                              '${p['name']} ${row['headcounts']?[p['id']] ?? 1}명${row['partTimes']?[p['id']] != null ? ' · 별도 시간' : ''}',
                              style: AppText.caption,
                            ),
                      ],
                    ),
                  ),
                ),
              ),
              handle(day, row, false, a, b),
            ],
          ),
        ),
      ),
    );
  }
}
