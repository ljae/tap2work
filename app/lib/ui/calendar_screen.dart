import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';

const _dutyOrder = ['조리', '서빙1', '서빙2', 'cashier'];

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.operations});
  final OperationsController operations;
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime day = DateTime.now();
  bool initialized = false;
  String get date =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  OperationsController get ops => widget.operations;
  String name(String id) =>
      ops
          .rows('tappers')
          .where((t) => t['id'] == id)
          .firstOrNull?['nickname'] ??
      '미배정';
  int minute(String clock) {
    final parts = clock.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  Future<void> schedule(Json task) async {
    final people = ops
        .rows('tappers')
        .where((t) => t['active'] == true)
        .toList();
    if (people.isEmpty) return;
    var tapper = people.first;
    var duty = (tapper['duties'] as List).first as String;
    var start = const TimeOfDay(hour: 12, minute: 0);
    var duration = 15;
    final result = await showDialog<Json>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text('Tap 배정 · ${task['title']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: tapper['id'],
                decoration: const InputDecoration(labelText: 'Tapper'),
                items: people
                    .map(
                      (p) => DropdownMenuItem<String>(
                        value: p['id'],
                        child: Text(p['nickname']),
                      ),
                    )
                    .toList(),
                onChanged: (id) => update(() {
                  tapper = people.firstWhere((p) => p['id'] == id);
                  duty = (tapper['duties'] as List).first;
                }),
              ),
              DropdownButtonFormField<String>(
                key: ValueKey(tapper['id']),
                initialValue: duty,
                decoration: const InputDecoration(labelText: 'R&R'),
                items: (tapper['duties'] as List)
                    .map(
                      (v) => DropdownMenuItem<String>(value: v, child: Text(v)),
                    )
                    .toList(),
                onChanged: (v) => update(() => duty = v!),
              ),
              TextButton(
                onPressed: () async {
                  final next = await showTimePicker(
                    context: context,
                    initialTime: start,
                  );
                  if (next != null) update(() => start = next);
                },
                child: Text('시작 ${start.format(context)}'),
              ),
              DropdownButtonFormField<int>(
                initialValue: duration,
                decoration: const InputDecoration(labelText: '예상 시간'),
                items: [5, 10, 15, 20, 30, 45, 60, 90, 120]
                    .map((v) => DropdownMenuItem(value: v, child: Text('$v분')))
                    .toList(),
                onChanged: (v) => update(() => duration = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, {
                'taskId': task['id'],
                'tapperId': tapper['id'],
                'duty': duty,
                'start':
                    '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
                'durationMinutes': duration,
              }),
              child: const Text('배정'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    final ok = await ops.act('schedule_tap', result);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Tap 시간을 배정했어요.' : ops.error ?? '배정하지 못했어요.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ops,
    builder: (context, _) {
      if (!initialized && ops.data?['day'] is String) {
        day = DateTime.tryParse(ops.data!['day']) ?? day;
        initialized = true;
      }
      final shifts = ops
          .rows('staffShifts')
          .where((s) => s['date'] == date)
          .toList();
      final tasks = ops
          .rows('tasks')
          .where((t) => t['kind'] == 'routine' && t['date'] == date)
          .toList();
      final scheduled = tasks.where((t) => t['schedule'] is Map).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeading(
            'CALENDAR',
            '일하는 흐름',
            'Tap의 예정 시각과 R&R별 근무 슬롯을 함께 봐요.',
          ),
          Row(
            children: [
              IconButton(
                tooltip: '전날',
                onPressed: () =>
                    setState(() => day = day.subtract(const Duration(days: 1))),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    final next = await showDatePicker(
                      context: context,
                      initialDate: day,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (next != null) setState(() => day = next);
                  },
                  child: Text(date),
                ),
              ),
              IconButton(
                tooltip: '다음날',
                onPressed: () =>
                    setState(() => day = day.add(const Duration(days: 1))),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const Information(
            '근무는 계획 시간, Tap은 배정된 예상 시간이에요. 출퇴근 실적과 급여는 Team에서 별도로 기록해요.',
          ),
          const SizedBox(height: 14),
          for (final duty in _dutyOrder) ...[
            Text(
              duty,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            if (!shifts.any((s) => s['duty'] == duty))
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('배정된 근무가 없어요.'),
              ),
            for (final shift in shifts.where((s) => s['duty'] == duty))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Surface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${shift['start']}–${shift['end']} · ${name(shift['tapperId'])}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      for (final task in scheduled.where(
                        (t) =>
                            t['schedule']['tapperId'] == shift['tapperId'] &&
                            t['schedule']['duty'] == duty,
                      ))
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${task['schedule']['start']}  ${task['title']} · ${task['schedule']['durationMinutes']}분 예상${minute(task['schedule']['start']) < minute(shift['start']) || minute(task['schedule']['start']) + (task['schedule']['durationMinutes'] as int) > minute(shift['end']) ? ' · 근무 시간 확인 필요' : ''}',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
          const SizedBox(height: 12),
          const Text(
            '시간 미배정 Tap',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          if (tasks.isEmpty) const Information('이 날짜의 Tap 실행 기록은 아직 없어요.'),
          for (final task in tasks.where((t) => t['schedule'] == null).take(20))
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(task['title']),
              subtitle: Text('${task['slot']} · 예상 시간 미설정'),
              trailing: ops.isLeader && !ops.readOnly
                  ? IconButton(
                      tooltip: '시간 배정',
                      onPressed: () => schedule(task),
                      icon: const Icon(Icons.add_circle_outline),
                    )
                  : null,
            ),
        ],
      );
    },
  );
}
