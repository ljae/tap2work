import 'payroll_settings_screen.dart';
import 'workplace_screens.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state/operations_controller.dart';
import 'components.dart';

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
  String? selectedPart;
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

  Future<void> editCrew([Json? current]) async {
    final nickname = TextEditingController(text: current?['nickname'] ?? '');
    final rate = TextEditingController(
      text: '${current?['hourlyWon'] ?? 10320}',
    );
    final kakao = TextEditingController(text: current?['kakaoUrl'] ?? '');
    final phone = TextEditingController(text: current?['phone'] ?? '');
    var rank = current?['rank'] as String? ?? 'crew';
    final period = current?['payPeriod'] as String? ?? 'monthly';
    var employment = current?['employmentType'] as String? ?? '시간알바';
    final duties = <String>{
      ...(current?['workProfile']?['partIds'] as List? ??
              [storeParts(ops).first['id']])
          .cast<String>(),
    };
    final saved = await showAppFormSheet<Json>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AppSheetPanel(
          title: Text(
            widget.payOnly
                ? '인건비 설정'
                : current == null
                ? '크루 등록'
                : '크루 수정',
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
                        for (final part in storeParts(
                          ops,
                        ).where((p) => p['hidden'] != true))
                          FilterChip(
                            label: Text(part['name']),
                            selected: duties.contains(part['id']),
                            onSelected: (v) => update(() {
                              if (v) {
                                duties.add(part['id']);
                              } else {
                                duties.remove(part['id']);
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
                    TextButton(
                      onPressed: () => showAppSheet(
                        context,
                        builder: (_) => PayrollSettingsScreen(ops: ops),
                      ),
                      child: const Text('매장 정산 설정'),
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
            PressBounce(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
            ),
            PressBounce(
              child: FilledButton(
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
                        'partIds': duties.toList(),
                        'hourlyWon': int.parse(rate.text),
                        'payPeriod': period,
                        'kakaoUrl': kakao.text.trim(),
                        'phone': phone.text.trim(),
                        'active': true,
                      }),
                child: const Text('저장'),
              ),
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
    final availableParts = storeParts(ops)
        .where(
          (p) =>
              p['hidden'] != true &&
              ((tapper['workProfile']?['partIds'] as List? ?? []).isEmpty ||
                  (tapper['workProfile']['partIds'] as List).contains(p['id'])),
        )
        .toList();
    if (availableParts.isEmpty) return;
    var duty = availableParts.first['id'] as String;
    final result = await showAppFormSheet<Json>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AppSheetPanel(
          title: Text('${tapper['nickname']} 근무 배정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PressBounce(
                child: OutlinedButton(
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
              ),
              AppPicker<String>(
                label: '담당',
                value: duty,
                items: availableParts
                    .map(
                      (p) => DropdownMenuItem(
                        value: p['id'] as String,
                        child: Text(p['name']),
                      ),
                    )
                    .toList(),
                onChanged: (v) => update(() => duty = v!),
              ),
              PressBounce(
                child: OutlinedButton(
                  onPressed: () async {
                    final next = await showTimePicker(
                      context: context,
                      initialTime: start,
                    );
                    if (next != null) update(() => start = next);
                  },
                  child: Text('시작 ${start.format(context)}'),
                ),
              ),
              PressBounce(
                child: OutlinedButton(
                  onPressed: () async {
                    final next = await showTimePicker(
                      context: context,
                      initialTime: end,
                    );
                    if (next != null) update(() => end = next);
                  },
                  child: Text('종료 ${end.format(context)}'),
                ),
              ),
            ],
          ),
          actions: [
            PressBounce(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
            ),
            PressBounce(
              child: FilledButton(
                onPressed: () => Navigator.pop(context, {
                  'tapperId': tapper['id'],
                  'partId': duty,
                  'date':
                      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                  'start':
                      '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
                  'end':
                      '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
                }),
                child: const Text('배정'),
              ),
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
    final result = await showAppFormSheet<Json>(
      context: context,
      builder: (context) => AppSheetPanel(
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
          PressBounce(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
          ),
          PressBounce(
            child: FilledButton(
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

  Widget staffCard(Json person) {
    final labels = storeParts(ops)
        .where(
          (p) => (person['workProfile']?['partIds'] as List? ?? []).contains(
            p['id'],
          ),
        )
        .map((p) => p['name'])
        .join(' · ');
    return Surface(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () => openPerson(person['id']),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: AppColors.lime,
              foregroundColor: AppColors.green,
              child: Text(
                '${person['nickname']}'.characters.take(2).toString(),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${person['nickname']}${person['actorId'] == ops.actorId ? ' · 나' : ''}',
                    style: AppText.body.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 19,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_ranks[person['rank']] ?? '크루'} · ${labels.isEmpty ? '전체 파트' : labels}',
                    style: AppText.caption,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => openPerson(person['id']),
              tooltip: '직원 정보',
              icon: const Icon(
                CupertinoIcons.ellipsis_vertical,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> openPerson(String id) => showAppSheet<void>(
    context,
    builder: (sheetContext) => ListenableBuilder(
      listenable: ops,
      builder: (context, _) {
        final person = ops.rows('tappers').where((p) => p['id'] == id).first;
        final shifts =
            ops.rows('staffShifts').where((s) => s['tapperId'] == id).toList()
              ..sort(
                (a, b) => '${a['date']} ${a['start']}'.compareTo(
                  '${b['date']} ${b['start']}',
                ),
              );
        final records = ops
            .rows('attendance')
            .where((e) => e['tapperId'] == id && e['voidedAt'] == null)
            .toList()
            .reversed;
        final partNames = storeParts(ops)
            .where(
              (p) => (person['workProfile']?['partIds'] as List? ?? [])
                  .contains(p['id']),
            )
            .map((p) => p['name'])
            .join(' · ');
        final bands = (person['workProfile']?['bands'] as List? ?? []).join(
          ' · ',
        );
        return Scaffold(
          appBar: AppBar(
            title: const Text('직원 정보'),
            centerTitle: true,
            leading: const CloseButton(),
          ),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              staffCardHeader(person),
              if (ops.isOwner) ...[
                const SizedBox(height: 16),
                Surface(
                  child: SettingRow(
                    title: '시급·정산',
                    subtitle:
                        '시급 ${money(person['hourlyWon'] ?? 0)}원 · 배정 ${hours(person['plannedMinutes'])}',
                    icon: CupertinoIcons.money_dollar_circle,
                    onTap: () => showAppSheet(
                      context,
                      builder: (_) => Scaffold(
                        appBar: AppBar(
                          title: const Text('시급·정산'),
                          leading: const CloseButton(),
                        ),
                        body: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: TeamScreen(operations: ops, payOnly: true),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Surface(
                child: Column(
                  children: [
                    SettingRow(
                      title: '파트',
                      subtitle: partNames.isEmpty ? '전체' : partNames,
                    ),
                    SettingRow(
                      title: '시간대',
                      subtitle: bands.isEmpty ? '전체 시간대' : bands,
                    ),
                    if (ops.isOwner)
                      SettingRow(
                        title: '파트·시간대 수정',
                        icon: CupertinoIcons.slider_horizontal_3,
                        onTap: () => showAppSheet(
                          context,
                          builder: (_) => WorkplaceSettings(
                            ops: ops,
                            section: 'person',
                            person: person,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Surface(
                child: SettingRow(
                  title: '보건증',
                  subtitle: '문서 보관 연결 전',
                  icon: CupertinoIcons.doc_text,
                  onTap: () => showAppSheet(
                    context,
                    builder: (_) => WorkplaceSettings(
                      ops: ops,
                      section: 'certificate',
                      person: person,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('근태', style: AppText.caption),
                    const SizedBox(height: 12),
                    Text(
                      '이번 주 실근무 ${hours(person['weeklyActualMinutes'])}',
                      style: AppText.body,
                    ),
                    if (records.isEmpty)
                      const Text('열람 가능한 근무 기록이 없어요.', style: AppText.caption),
                    for (final record in records.take(12))
                      SettingRow(
                        title:
                            const {
                              'clock_in': '출근',
                              'clock_out': '퇴근',
                              'break_start': '휴게 시작',
                              'break_end': '휴게 종료',
                            }[record['type']] ??
                            '기록',
                        subtitle: _recordTime(record['at']),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('근무 일정', style: AppText.caption),
                    if (shifts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text('배정된 근무가 없어요.'),
                      ),
                    for (final shift in shifts.take(14))
                      SettingRow(
                        title:
                            '${shift['date']} · ${shift['start']}–${shift['end']}',
                        subtitle: partLabel(ops, shift['partId']),
                      ),
                    if (ops.isLeader)
                      TextButton(
                        onPressed: ops.readOnly
                            ? null
                            : () => editShift(person),
                        child: const Text('근무 배정'),
                      ),
                  ],
                ),
              ),
              if (ops.isOwner) ...[
                const SizedBox(height: 16),
                Surface(
                  child: SettingRow(
                    title: '직원 기본 정보 수정',
                    icon: CupertinoIcons.pencil,
                    onTap: ops.readOnly ? null : () => editCrew(person),
                  ),
                ),
              ],
              if ((person['phone'] ?? '').toString().isNotEmpty)
                TextButton(
                  onPressed: () => openContact(person['phone'], phone: true),
                  child: const Text('전화 연결'),
                ),
              if ((person['kakaoUrl'] ?? '').toString().isNotEmpty)
                TextButton(
                  onPressed: () =>
                      openContact(person['kakaoUrl'], phone: false),
                  child: const Text('카카오톡 링크'),
                ),
            ],
          ),
        );
      },
    ),
  );
  String _recordTime(dynamic value) {
    final date = DateTime.tryParse(
      '$value',
    )?.toUtc().add(const Duration(hours: 9));
    return date == null
        ? ''
        : '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget staffCardHeader(Json person) => Surface(
    child: Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.lime,
          foregroundColor: AppColors.green,
          child: Text('${person['nickname']}'.characters.take(2).toString()),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${person['nickname']}', style: AppText.title),
              Text(_ranks[person['rank']] ?? '크루', style: AppText.caption),
            ],
          ),
        ),
      ],
    ),
  );

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
          if (widget.payOnly)
            const Information(
              '시급·지급 주기 설정 및 지급 기록이에요. 아래 누적액은 법정 수당을 제외해요. 수당 포함 예상은 주간 인건비에서 확인하세요.',
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
                        PressBounce(
                          child: FilledButton(
                            onPressed: ops.readOnly || ops.busy
                                ? null
                                : () => action('clock_in', {}),
                            child: const Text('출근'),
                          ),
                        ),
                      if (state == 'clock_in' || state == 'break_end')
                        PressBounce(
                          child: OutlinedButton(
                            onPressed: ops.readOnly || ops.busy
                                ? null
                                : () => action('break_start', {}),
                            child: const Text('휴게 시작'),
                          ),
                        ),
                      if (state == 'break_start')
                        PressBounce(
                          child: OutlinedButton(
                            onPressed: ops.readOnly || ops.busy
                                ? null
                                : () => action('break_end', {}),
                            child: const Text('휴게 종료'),
                          ),
                        ),
                      if (state == 'clock_in' || state == 'break_end')
                        PressBounce(
                          child: FilledButton(
                            onPressed: ops.readOnly || ops.busy
                                ? null
                                : () => action('clock_out', {}),
                            child: const Text('퇴근'),
                          ),
                        ),
                    ],
                  ),
                  if (ops.readOnly) const Text('공개 미리보기에서는 근태가 저장되지 않아요.'),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (!widget.payOnly && ops.isOwner)
            PressBounce(
              child: FilledButton.icon(
                onPressed: ops.busy || ops.readOnly ? null : () => editCrew(),
                icon: const Icon(Icons.person_add_alt),
                label: const Text('크루 등록'),
              ),
            ),
          if (!widget.payOnly && ops.isOwner)
            TextButton.icon(
              onPressed: () => showAppSheet(
                context,
                builder: (_) => WorkplaceSettings(ops: ops, section: 'invite'),
              ),
              icon: const Icon(CupertinoIcons.qrcode),
              label: const Text('코드·QR로 초대'),
            ),
          const SizedBox(height: 12),
          if (!widget.payOnly)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('전체 파트'),
                    selected: selectedPart == null,
                    onSelected: (_) => setState(() => selectedPart = null),
                  ),
                  for (final part in storeParts(
                    ops,
                  ).where((p) => p['hidden'] != true))
                    ChoiceChip(
                      label: Text(part['name']),
                      selected: selectedPart == part['id'],
                      onSelected: (_) =>
                          setState(() => selectedPart = part['id']),
                    ),
                ],
              ),
            ),
          for (final tapper in tappers.where(
            (t) =>
                t['active'] == true &&
                (widget.payOnly ||
                    selectedPart == null ||
                    (t['workProfile']?['partIds'] as List? ?? []).contains(
                      selectedPart,
                    ) ||
                    (t['workProfile']?['partIds'] as List? ?? []).isEmpty),
          ))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: !widget.payOnly
                  ? staffCard(tapper)
                  : Surface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${tapper['nickname']} · ${_ranks[tapper['rank']] ?? '크루'}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(crewPartsLabel(ops, tapper)),
                          Text(
                            '이번 주 계획 ${hours(tapper['plannedMinutes'])} · 실적 ${hours(tapper['weeklyActualMinutes'])}',
                          ),
                          if (widget.payOnly && tapper['gross'] != null) ...[
                            Text(
                              '${tapper['payPeriodStart']} ~ ${tapper['payPeriodEnd'] ?? ops.data?['day']}',
                              style: AppText.caption,
                            ),
                            Text(
                              '시급 ${money(tapper['hourlyWon'])}원 · ${_periods[tapper['payPeriod']]}',
                            ),
                            Text(
                              '기본급·추가보수 ${money(tapper['gross'])}원 · 가산수당 별도 확인',
                            ),
                            Text(
                              '지급 ${money(tapper['paid'])}원 · 잔여 ${money(tapper['remaining'])}원 · 추가보수 ${money(tapper['adjustments'])}원',
                            ),
                          ],
                          Wrap(
                            spacing: 6,
                            children: [
                              if (widget.payOnly && ops.isOwner)
                                PressBounce(
                                  child: TextButton(
                                    onPressed: ops.readOnly
                                        ? null
                                        : () => editCrew(tapper),
                                    child: const Text('인건비 설정'),
                                  ),
                                ),
                              if (!widget.payOnly && ops.isOwner)
                                PressBounce(
                                  child: TextButton(
                                    onPressed: ops.readOnly
                                        ? null
                                        : () => editCrew(tapper),
                                    child: const Text('수정'),
                                  ),
                                ),
                              if (!widget.payOnly && ops.isLeader)
                                PressBounce(
                                  child: TextButton(
                                    onPressed: ops.readOnly
                                        ? null
                                        : () => editShift(tapper),
                                    child: const Text('근무 배정'),
                                  ),
                                ),
                              if (widget.payOnly && ops.isOwner)
                                PressBounce(
                                  child: TextButton(
                                    onPressed: ops.readOnly
                                        ? null
                                        : () => addAmount(
                                            tapper,
                                            'add_pay_adjustment',
                                          ),
                                    child: const Text('추가보수'),
                                  ),
                                ),
                              if (widget.payOnly && ops.isOwner)
                                PressBounce(
                                  child: TextButton(
                                    onPressed: ops.readOnly
                                        ? null
                                        : () => addAmount(
                                            tapper,
                                            'record_payment',
                                          ),
                                    child: const Text('지급 기록'),
                                  ),
                                ),
                              if ((tapper['phone'] ?? '').toString().isNotEmpty)
                                PressBounce(
                                  child: TextButton(
                                    onPressed: () => openContact(
                                      tapper['phone'],
                                      phone: true,
                                    ),
                                    child: const Text('전화 연결'),
                                  ),
                                ),
                              if ((tapper['kakaoUrl'] ?? '')
                                  .toString()
                                  .isNotEmpty)
                                PressBounce(
                                  child: TextButton(
                                    onPressed: () => openContact(
                                      tapper['kakaoUrl'],
                                      phone: false,
                                    ),
                                    child: const Text('카카오톡 링크'),
                                  ),
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
