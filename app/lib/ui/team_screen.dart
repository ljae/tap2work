import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state/operations_controller.dart';
import 'components.dart';

const _duties = ['조리', '서빙1', '서빙2', 'cashier'];
const _ranks = {'owner': '사장', 'manager': '매니저', 'crew': '크루'};
const _periods = {'monthly': '월급', 'weekly': '주급', 'daily': '일급'};

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key, required this.operations, this.payOnly = false});
  final OperationsController operations;
  final bool payOnly;
  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  OperationsController get ops => widget.operations;
  String money(num value) => value
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  String hours(dynamic minutes) =>
      '${((minutes as num? ?? 0) / 60).toStringAsFixed(1)}시간';
  Future<void> action(String type, Json data) async {
    final ok = await ops.act(type, data);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? '기록했어요.' : ops.error ?? '기록하지 못했어요.')),
      );
    }
  }

  Future<void> editTapper([Json? current]) async {
    final nickname = TextEditingController(text: current?['nickname'] ?? '');
    final rate = TextEditingController(
      text: '${current?['hourlyWon'] ?? 10000}',
    );
    final kakao = TextEditingController(text: current?['kakaoUrl'] ?? '');
    final phone = TextEditingController(text: current?['phone'] ?? '');
    var rank = current?['rank'] as String? ?? 'crew';
    var period = current?['payPeriod'] as String? ?? 'monthly';
    var employment = current?['employmentType'] as String? ?? '시간알바';
    final duties = <String>{
      ...(current?['duties'] as List? ?? ['서빙1']).cast<String>(),
    };
    final saved = await showDialog<Json>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(
            widget.payOnly
                ? '인건비 설정'
                : current == null
                ? 'Tapper 등록'
                : 'Tapper 수정',
          ),
          content: SizedBox(
            width: 430,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!widget.payOnly)
                    TextField(
                      controller: nickname,
                      onChanged: (_) => update(() {}),
                      decoration: const InputDecoration(labelText: '별칭(이름)'),
                    ),
                  if (!widget.payOnly)
                    AppPicker<String>(
                      label: '직급',
                      value: rank,
                      items: _ranks.entries
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => update(() => rank = v!),
                    ),
                  if (!widget.payOnly)
                    AppPicker<String>(
                      label: '고용형태',
                      value: employment,
                      items: ['정규직', '시간알바', '정규알바']
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                      onChanged: (v) => update(() => employment = v!),
                    ),
                  if (!widget.payOnly)
                    Wrap(
                      spacing: 6,
                      children: [
                        for (final duty in _duties)
                          FilterChip(
                            label: Text(duty),
                            selected: duties.contains(duty),
                            onSelected: (v) => update(() {
                              if (v) {
                                duties.add(duty);
                              } else {
                                duties.remove(duty);
                              }
                            }),
                          ),
                      ],
                    ),
                  if (widget.payOnly)
                    TextField(
                      controller: rate,
                      onChanged: (_) => update(() {}),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '시급 · 원'),
                    ),
                  if (widget.payOnly)
                    AppPicker<String>(
                      label: '급여방식',
                      value: period,
                      items: _periods.entries
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => update(() => period = v!),
                    ),
                  if (!widget.payOnly)
                    TextField(
                      controller: kakao,
                      decoration: const InputDecoration(
                        labelText: '카카오톡 HTTPS 링크 · 선택',
                      ),
                    ),
                  if (!widget.payOnly)
                    TextField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: '전화번호 · 선택'),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed:
                  nickname.text.trim().isEmpty ||
                      duties.isEmpty ||
                      int.tryParse(rate.text) == null
                  ? null
                  : () => Navigator.pop(context, {
                      if (current != null) 'id': current['id'],
                      'nickname': nickname.text.trim(),
                      'rank': rank,
                      'employmentType': employment,
                      'duties': duties.toList(),
                      'hourlyWon': int.parse(rate.text),
                      'payPeriod': period,
                      'kakaoUrl': kakao.text.trim(),
                      'phone': phone.text.trim(),
                      'active': true,
                    }),
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
    nickname.dispose();
    rate.dispose();
    kakao.dispose();
    phone.dispose();
    if (saved != null) await action('save_tapper', saved);
  }

  Future<void> editShift(Json tapper) async {
    var date = DateTime.now();
    var start = const TimeOfDay(hour: 9, minute: 0);
    var end = const TimeOfDay(hour: 18, minute: 0);
    var duty = (tapper['duties'] as List).first as String;
    final result = await showDialog<Json>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text('${tapper['nickname']} 근무 배정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: () async {
                  final next = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (next != null) update(() => date = next);
                },
                child: Text(
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                ),
              ),
              AppPicker<String>(
                label: '담당',
                value: duty,
                items: (tapper['duties'] as List)
                    .map(
                      (v) =>
                          DropdownMenuItem(value: v as String, child: Text(v)),
                    )
                    .toList(),
                onChanged: (v) => update(() => duty = v!),
              ),
              OutlinedButton(
                onPressed: () async {
                  final next = await showTimePicker(
                    context: context,
                    initialTime: start,
                  );
                  if (next != null) update(() => start = next);
                },
                child: Text('시작 ${start.format(context)}'),
              ),
              OutlinedButton(
                onPressed: () async {
                  final next = await showTimePicker(
                    context: context,
                    initialTime: end,
                  );
                  if (next != null) update(() => end = next);
                },
                child: Text('종료 ${end.format(context)}'),
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
                'tapperId': tapper['id'],
                'duty': duty,
                'date':
                    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                'start':
                    '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
                'end':
                    '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
              }),
              child: const Text('배정'),
            ),
          ],
        ),
      ),
    );
    if (result != null) await action('save_staff_shift', result);
  }

  Future<void> addAmount(Json tapper, String type) async {
    final amount = TextEditingController();
    final note = TextEditingController();
    final result = await showDialog<Json>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(type == 'record_payment' ? '지급액 기록' : '추가보수 기록'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '원 단위 금액'),
            ),
            if (type == 'add_pay_adjustment')
              TextField(
                controller: note,
                decoration: const InputDecoration(labelText: '설명'),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final won = int.tryParse(amount.text);
              if (won == null || won < 0) return;
              Navigator.pop(context, {
                'tapperId': tapper['id'],
                'amountWon': won,
                if (type == 'add_pay_adjustment') 'note': note.text.trim(),
              });
            },
            child: const Text('기록'),
          ),
        ],
      ),
    );
    amount.dispose();
    note.dispose();
    if (result != null) await action(type, result);
  }

  Future<void> openContact(String value, {required bool phone}) async {
    final uri = phone ? Uri(scheme: 'tel', path: value) : Uri.tryParse(value);
    try {
      if (uri != null &&
          await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {}
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(phone ? '전화 앱을 열지 못해 번호를 복사했어요.' : '링크를 열지 못해 복사했어요.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ops,
    builder: (context, _) {
      final tappers = ops.rows('tappers');
      final own = tappers.where((t) => t['actorId'] == ops.actorId).firstOrNull;
      final state = own?['attendanceState'] ?? 'off_duty';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeading(
            widget.payOnly ? 'LABOR' : 'CALENDAR',
            widget.payOnly ? '인건비 기록' : '크루 관리',
            widget.payOnly ? '사장님만 보는 근태·지급 기록' : 'Tapper 등록과 근무시간 관리',
          ),
          if (!widget.payOnly && own != null)
            Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${own['nickname']} · 현재 ${state == 'clock_in' || state == 'break_end'
                        ? '근무 중'
                        : state == 'break_start'
                        ? '휴게 중'
                        : '근무 전/퇴근'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (state == 'off_duty' || state == 'clock_out')
                        FilledButton(
                          onPressed: ops.readOnly || ops.busy
                              ? null
                              : () => action('clock_in', {}),
                          child: const Text('출근'),
                        ),
                      if (state == 'clock_in' || state == 'break_end')
                        OutlinedButton(
                          onPressed: ops.readOnly || ops.busy
                              ? null
                              : () => action('break_start', {}),
                          child: const Text('휴게 시작'),
                        ),
                      if (state == 'break_start')
                        OutlinedButton(
                          onPressed: ops.readOnly || ops.busy
                              ? null
                              : () => action('break_end', {}),
                          child: const Text('휴게 종료'),
                        ),
                      if (state == 'clock_in' || state == 'break_end')
                        FilledButton(
                          onPressed: ops.readOnly || ops.busy
                              ? null
                              : () => action('clock_out', {}),
                          child: const Text('퇴근'),
                        ),
                    ],
                  ),
                  if (ops.readOnly) const Text('공개 미리보기에서는 근태가 저장되지 않아요.'),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (!widget.payOnly && ops.isOwner)
            FilledButton.icon(
              onPressed: ops.busy || ops.readOnly ? null : () => editTapper(),
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Tapper 등록'),
            ),
          const SizedBox(height: 12),
          for (final tapper in tappers.where((t) => t['active'] == true))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tapper['nickname']} · ${_ranks[tapper['rank']] ?? '크루'}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text((tapper['duties'] as List).join(' · ')),
                    Text(
                      '이번 주 계획 ${hours(tapper['plannedMinutes'])} · 실적 ${hours(tapper['weeklyActualMinutes'])}',
                    ),
                    if (widget.payOnly && tapper['gross'] != null) ...[
                      Text(
                        '시급 ${money(tapper['hourlyWon'])}원 · ${_periods[tapper['payPeriod']]}',
                      ),
                      Text(
                        '이번 달 누적 ${money(tapper['monthlyGross'])}원 · 현재 지급 기간 ${money(tapper['gross'])}원',
                      ),
                      Text(
                        '지급 ${money(tapper['paid'])}원 · 잔여 ${money(tapper['remaining'])}원 · 추가보수 ${money(tapper['adjustments'])}원',
                      ),
                    ],
                    Wrap(
                      spacing: 6,
                      children: [
                        if (widget.payOnly && ops.isOwner)
                          TextButton(
                            onPressed: ops.readOnly
                                ? null
                                : () => editTapper(tapper),
                            child: const Text('인건비 설정'),
                          ),
                        if (!widget.payOnly && ops.isOwner)
                          TextButton(
                            onPressed: ops.readOnly
                                ? null
                                : () => editTapper(tapper),
                            child: const Text('수정'),
                          ),
                        if (!widget.payOnly && ops.isLeader)
                          TextButton(
                            onPressed: ops.readOnly
                                ? null
                                : () => editShift(tapper),
                            child: const Text('근무 배정'),
                          ),
                        if (widget.payOnly && ops.isOwner)
                          TextButton(
                            onPressed: ops.readOnly
                                ? null
                                : () => addAmount(tapper, 'add_pay_adjustment'),
                            child: const Text('추가보수'),
                          ),
                        if (widget.payOnly && ops.isOwner)
                          TextButton(
                            onPressed: ops.readOnly
                                ? null
                                : () => addAmount(tapper, 'record_payment'),
                            child: const Text('지급 기록'),
                          ),
                        if ((tapper['phone'] ?? '').toString().isNotEmpty)
                          TextButton(
                            onPressed: () =>
                                openContact(tapper['phone'], phone: true),
                            child: const Text('전화 연결'),
                          ),
                        if ((tapper['kakaoUrl'] ?? '').toString().isNotEmpty)
                          TextButton(
                            onPressed: () =>
                                openContact(tapper['kakaoUrl'], phone: false),
                            child: const Text('카카오톡 링크'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}
