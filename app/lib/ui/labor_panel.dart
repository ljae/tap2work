import 'payroll_settings_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';
import 'team_screen.dart';

String laborMoney(dynamic value) => value == null
    ? '확인 필요'
    : '${(value as num).round().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원';
String laborDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class LaborPanel extends StatefulWidget {
  const LaborPanel({super.key, required this.ops});
  final OperationsController ops;
  @override
  State<LaborPanel> createState() => _LaborPanelState();
}

class _LaborPanelState extends State<LaborPanel> {
  String? selectedWeek;
  bool planned = true;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.ops,
    builder: (context, _) {
      if (!widget.ops.isOwner) return const Information('인건비는 사장님만 볼 수 있어요.');
      final report = widget.ops.data?['labor'] as Json? ?? {};
      final weeks = (report['weeks'] as List? ?? []).cast<Json>();
      final now =
          DateTime.tryParse(widget.ops.data?['day'] ?? '') ?? DateTime.now();
      final current = laborDate(now.subtract(Duration(days: now.weekday - 1)));
      final week =
          weeks
              .where((w) => w['week'] == (selectedWeek ?? current))
              .firstOrNull ??
          weeks.lastOrNull;
      final people = (week?['people'] as List? ?? []).cast<Json>();
      final key = planned ? 'planned' : 'actual';
      final pending = people.where((p) => p[key]['totalWon'] == null).length;
      final total = people.fold<num>(
        0,
        (n, p) => n + (p[key]['totalWon'] as num? ?? 0),
      );
      final alerts = people.fold<int>(
        0,
        (n, p) => n + (p[key]['alerts'] as List).length,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('주간 인건비', style: AppText.title)),
              Icon(
                Icons.notifications_none,
                color: alerts > 0 ? AppColors.accent : AppColors.green,
              ),
              Text('$alerts', style: AppText.body),
            ],
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => showAppSheet(
              context,
              builder: (_) => Scaffold(
                appBar: AppBar(
                  title: const Text('시급·지급 기록'),
                  leading: const CloseButton(),
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: TeamScreen(operations: widget.ops, payOnly: true),
                ),
              ),
            ),
            child: const Text('시급·지급 기록'),
          ),
          TextButton.icon(
            onPressed: () => showAppSheet(
              context,
              builder: (_) => PayrollSettingsScreen(ops: widget.ops),
            ),
            icon: const Icon(Icons.tune),
            label: const Text('정산 설정'),
          ),
          if (weeks.isNotEmpty)
            AppPicker<String>(
              label: '주 시작일 · 월요일',
              value: week!['week'],
              items: [
                for (final w in weeks)
                  DropdownMenuItem(
                    value: w['week'] as String,
                    child: Text('${w['week']} 주'),
                  ),
              ],
              onChanged: (v) => setState(() => selectedWeek = v),
            ),
          const SizedBox(height: 16),
          AppSegmented<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('배정 예상')),
              ButtonSegment(value: false, label: Text('근태 기준')),
            ],
            selected: {planned},
            onSelectionChanged: (v) => setState(() => planned = v.first),
          ),
          const SizedBox(height: 24),
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pending > 0 ? '계산 조건 $pending명 확인 필요' : laborMoney(total),
                  style: AppText.title,
                ),
                const SizedBox(height: 8),
                Text(
                  pending > 0
                      ? '확인된 직원 합계 ${laborMoney(total)}'
                      : '세전 예상 · 지급 확정 전',
                  style: AppText.caption,
                ),
                Text(
                  planned
                      ? '휴게 차감 전 · 주휴는 확인한 조건 기준'
                      : '퇴근 완료·휴게 제외 · 주휴는 확인한 조건 기준',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          if (people.isEmpty) const Information('계산할 직원이 없어요.'),
          for (final person in people)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AppCard(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(24),
                  title: Text(person['nickname'], style: AppText.body),
                  subtitle: Text(
                    '시급 ${laborMoney(person['hourlyWon'])}\n${laborMoney(person[key]['totalWon'])} · 확인 ${(person[key]['alerts'] as List).length}건',
                    style: AppText.caption,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showAppSheet(
                    context,
                    builder: (_) => LaborDetail(
                      ops: widget.ops,
                      week: week!['week'],
                      tapperId: person['tapperId'],
                      planned: planned,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class LaborDetail extends StatelessWidget {
  const LaborDetail({
    super.key,
    required this.ops,
    required this.week,
    required this.tapperId,
    required this.planned,
  });
  final OperationsController ops;
  final String week, tapperId;
  final bool planned;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ops,
    builder: (context, _) {
      final weeks = (ops.data?['labor']?['weeks'] as List? ?? []).cast<Json>();
      final w = weeks.where((r) => r['week'] == week).firstOrNull;
      final person = (w?['people'] as List? ?? [])
          .cast<Json>()
          .where((r) => r['tapperId'] == tapperId)
          .firstOrNull;
      if (person == null) {
        return Scaffold(
          appBar: AppBar(leading: const CloseButton()),
          body: const Information('직원 정보를 다시 확인해 주세요.'),
        );
      }
      final result = person[planned ? 'planned' : 'actual'] as Json;
      return Scaffold(
        appBar: AppBar(
          title: Text('${person['nickname']} 인건비'),
          leading: const CloseButton(),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(laborMoney(result['totalWon']), style: AppText.title),
            Text(
              '$week 주 · ${planned ? '배정 예상' : '근태 기준'} · 세전',
              style: AppText.caption,
            ),
            const SizedBox(height: 24),
            for (final entry in {
              'baseWon': '근로 기본급',
              'weeklyRestWon': '주휴수당',
              'extensionWon': '연장 가산',
              'nightWon': '야간 가산',
              'holidayWon': '휴일근로 가산',
              'paidHolidayWon': '기타 유급휴일',
            }.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(entry.value)),
                    Text(laborMoney(result[entry.key])),
                  ],
                ),
              ),
            if (result['weeklyRestIncluded'] == false)
              Text(
                '주휴수당 합계 제외 · 발생 ${result['weeklyRestWeeks'] ?? '확인 필요'}주 · 발생액 ${laborMoney(result['weeklyRestAccruedWon'])}',
                style: AppText.caption,
              ),
            const SizedBox(height: 16),
            Text(
              '근로 ${((result['workedMinutes'] as num) / 60).toStringAsFixed(1)}시간 · 연장 ${((result['overtimeMinutes'] as num) / 60).toStringAsFixed(1)}시간 · 야간 ${((result['nightMinutes'] as num) / 60).toStringAsFixed(1)}시간',
              style: AppText.caption,
            ),
            const SizedBox(height: 32),
            const Text('주간 확인 목록', style: AppText.body),
            for (final alert in result['alerts'] as List)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.error_outline,
                  color: AppColors.accent,
                ),
                title: Text('$alert', style: AppText.caption),
              ),
            const SizedBox(height: 24),
            PressBounce(
              child: FilledButton(
                onPressed: ops.readOnly || ops.busy
                    ? null
                    : () => showAppSheet(
                        context,
                        builder: (_) => LaborReviewEditor(
                          ops: ops,
                          person: person,
                          week: week,
                        ),
                      ),
                child: const Text('계산 조건 확인·변경'),
              ),
            ),
            if (ops.readOnly)
              const Text('공개 미리보기에서는 저장하지 않아요.', style: AppText.caption),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => launchUrl(
                Uri.parse('https://1350.moel.go.kr/rtmview.do?id=1000263464'),
                mode: LaunchMode.externalApplication,
              ),
              child: const Text('주휴·사업장 규모 · 공식 기준'),
            ),
            const Text(
              '시급제 성인·고정 근로시간 기준 추정치예요. 월급 계약, 포괄임금, 탄력근로, 미성년자 등 별도 기준은 급여 담당자와 확인해 주세요. 추가보수·지급기록·세금·보험 공제는 이 합계에 포함하지 않아요.',
              style: AppText.caption,
            ),
          ],
        ),
      );
    },
  );
}

class LaborReviewEditor extends StatefulWidget {
  const LaborReviewEditor({
    super.key,
    required this.ops,
    required this.person,
    required this.week,
  });
  final OperationsController ops;
  final Json person;
  final String week;
  @override
  State<LaborReviewEditor> createState() => _LaborReviewEditorState();
}

class _LaborReviewEditorState extends State<LaborReviewEditor> {
  late final Json draft = {...?widget.person['review'] as Json?};
  late final int revision = widget.ops.data?['revision'] ?? 0;
  final controllers = <String, TextEditingController>{};
  late String size = draft['size'] ?? 'unknown',
      scope = draft['scope'] ?? 'unknown',
      attendance = draft['attendance'] ?? 'unknown';
  late bool shortTime = draft['shortTime'] == true,
      holidaysConfirmed = draft['holidaysConfirmed'] == true;
  late final Set<String> holidays = {
    ...(draft['holidayDates'] as List? ?? []).cast<String>(),
  };
  late final List<int> daily = List<int>.from(
    draft['dailyContractMinutes'] ?? List.filled(7, 0),
  );
  bool saving = false;
  String? error;
  TextEditingController field(String key, dynamic initial) => controllers
      .putIfAbsent(key, () => TextEditingController(text: '$initial'));
  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget picker(
    String title,
    String value,
    Map<String, String> values,
    ValueChanged<String> changed,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: AppPicker<String>(
      label: title,
      value: value,
      items: [
        for (final e in values.entries)
          DropdownMenuItem(value: e.key, child: Text(e.value)),
      ],
      onChanged: (v) => setState(() => changed(v!)),
    ),
  );
  Widget number(String key, String title, num? initial) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextField(
      controller: field(key, initial ?? ''),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: title),
    ),
  );
  Future<void> save() async {
    final values = <String, int>{};
    for (final key in [
      'hourlyWon',
      'ordinaryHourlyWon',
      'averageWeeklyMinutes',
      'restMinutes',
      'otherPaidHolidayMinutes',
    ]) {
      final n = num.tryParse(controllers[key]?.text ?? '');
      if (n == null ||
          !n.isFinite ||
          n < 0 ||
          (key.endsWith('Won') && n != n.round())) {
        setState(() => error = '금액과 시간을 확인해 주세요.');
        return;
      }
      values[key] = key.endsWith('Won') ? n.round() : (n * 60).round();
    }
    setState(() {
      saving = true;
      error = null;
    });
    final ok = await widget.ops.act('save_labor_review', {
      'revision': revision,
      'review': {
        ...values,
        'tapperId': widget.person['tapperId'],
        'week': widget.week,
        'size': widget.ops.data?['payrollSettings']?['businessSize'] ?? size,
        'scope': scope,
        'attendance': attendance,
        'shortTime': shortTime,
        'dailyContractMinutes': daily,
        'holidaysConfirmed': holidaysConfirmed,
        'holidayDates': holidays.toList(),
      },
    });
    if (!mounted) return;
    setState(() {
      saving = false;
      error = ok ? null : widget.ops.error ?? '저장하지 못했어요.';
    });
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: Scaffold(
      appBar: AppBar(title: const Text('계산 조건'), leading: const CloseButton()),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            '${widget.person['nickname']} · ${widget.week} 주',
            style: AppText.body,
          ),
          const SizedBox(height: 24),
          picker('근로계약 기준', scope, {
            'unknown': '미확인 · 계산 보류',
            'standard': '시급제 성인 · 고정 근로시간',
          }, (v) => scope = v),
          TextButton(
            onPressed: () => showAppSheet(
              context,
              builder: (_) => PayrollSettingsScreen(ops: widget.ops),
            ),
            child: const Text('사업장 규모·주휴 포함은 매장 정산 설정에서 변경'),
          ),
          number(
            'hourlyWon',
            '기본 시급 · 원',
            draft['hourlyWon'] ?? widget.person['hourlyWon'],
          ),
          number(
            'ordinaryHourlyWon',
            '통상시급 · 원',
            draft['ordinaryHourlyWon'] ?? widget.person['hourlyWon'],
          ),
          number(
            'averageWeeklyMinutes',
            '4주 평균 주 소정근로시간 · 시간',
            draft['averageWeeklyMinutes'] == null
                ? null
                : draft['averageWeeklyMinutes'] / 60,
          ),
          number(
            'restMinutes',
            '유급 주휴시간 · 시간 (최대 8)',
            (draft['restMinutes'] ?? 0) / 60,
          ),
          const Text(
            '단시간 근로자의 주휴시간은 4주 소정근로시간 ÷ 같은 기간 통상근로자의 소정근로일수로 확인해 입력하세요. 일반 주 5일·40시간제는 8시간이에요.',
            style: AppText.caption,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              final average = num.tryParse(
                controllers['averageWeeklyMinutes']?.text ?? '',
              );
              if (average != null && average >= 0 && average <= 40) {
                field('restMinutes', 0).text = (average / 5).toStringAsFixed(2);
                setState(() {});
              }
            },
            child: const Text('주 5일·40시간제 기준으로 계산'),
          ),
          picker('이번 주 주휴 요건', attendance, {
            'unknown': '미확인',
            'met': '개근·주휴 요건 충족',
            'unmet': '요건 미충족',
          }, (v) => attendance = v),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('단시간 근로 계약'),
            value: shortTime,
            onChanged: (v) => setState(() => shortTime = v),
          ),
          if (shortTime) ...[
            const Text('요일별 소정근로시간', style: AppText.body),
            for (var i = 0; i < 7; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppPicker<int>(
                  label: const ['월', '화', '수', '목', '금', '토', '일'][i],
                  value: daily[i],
                  items: [
                    for (var m = 0; m <= 480; m += 30)
                      DropdownMenuItem(value: m, child: Text('${m / 60}시간')),
                  ],
                  onChanged: (v) => setState(() => daily[i] = v!),
                ),
              ),
          ],
          const SizedBox(height: 24),
          const Text('휴일근로 날짜', style: AppText.body),
          Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < 7; i++)
                Builder(
                  builder: (context) {
                    final d = laborDate(
                      DateTime.parse(widget.week).add(Duration(days: i)),
                    );
                    return FilterChip(
                      chipAnimationStyle: AppMotion.chipStyle(context),
                      label: Text(
                        '${const ['월', '화', '수', '목', '금', '토', '일'][i]} ${d.substring(5)}',
                      ),
                      selected: holidays.contains(d),
                      onSelected: (v) => setState(
                        () => v ? holidays.add(d) : holidays.remove(d),
                      ),
                    );
                  },
                ),
            ],
          ),
          const Text(
            '주휴일·근로자의 날·사업장에 적용되는 공휴일 등을 선택하세요. 일요일로 자동 지정하지 않아요.',
            style: AppText.caption,
          ),
          const SizedBox(height: 16),
          number(
            'otherPaidHolidayMinutes',
            '주휴 외 유급휴일 지급시간 · 시간',
            (draft['otherPaidHolidayMinutes'] ?? 0) / 60,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('휴일 날짜·유급 지급시간 확인'),
            value: holidaysConfirmed,
            onChanged: (v) => setState(() => holidaysConfirmed = v),
          ),
          if (error != null) Information(error!),
          const SizedBox(height: 24),
          PressBounce(
            child: FilledButton(
              onPressed: saving ? null : save,
              child: Text(saving ? '저장 중…' : '이번 주 조건 저장'),
            ),
          ),
        ],
      ),
    ),
  );
}
