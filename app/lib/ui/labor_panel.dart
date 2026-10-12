import '../l10n/app_localizations.dart';
import 'payroll_settings_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';
import 'team_screen.dart';

String laborMoney(dynamic value, {AppStrings? strings}) {
  if (value == null) return strings?.text('ui.audit1092') ?? '확인 필요';
  final amount = (value as num).round().toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  return strings?.text('ui.audit959', {'p0': amount}) ?? '$amount원';
}

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
      if (!widget.ops.isOwner) return Information(context.t('ui.audit1'));
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
              Expanded(
                child: Text(context.t('ui.audit504'), style: AppText.title),
              ),
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
                  title: Text(context.t('ui.audit2')),
                  leading: const CloseButton(),
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: TeamScreen(operations: widget.ops, payOnly: true),
                ),
              ),
            ),
            child: Text(context.t('ui.audit2')),
          ),
          TextButton.icon(
            onPressed: () => showAppSheet(
              context,
              builder: (_) => PayrollSettingsScreen(ops: widget.ops),
            ),
            icon: const Icon(Icons.tune),
            label: Text(context.t('ui.audit3')),
          ),
          if (weeks.isNotEmpty)
            AppPicker<String>(
              label: context.t('ui.audit505'),
              value: week!['week'],
              items: [
                for (final w in weeks)
                  DropdownMenuItem(
                    value: w['week'] as String,
                    child: Text(
                      context.t('ui.audit506', args: {'p0': w['week']}),
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => selectedWeek = v),
            ),
          const SizedBox(height: 16),
          AppSegmented<bool>(
            segments: [
              ButtonSegment(value: true, label: Text(context.t('ui.audit507'))),
              ButtonSegment(
                value: false,
                label: Text(context.t('ui.audit508')),
              ),
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
                  pending > 0
                      ? context.t('ui.audit509', args: {'p0': pending})
                      : laborMoney(total, strings: AppStrings.of(context)),
                  style: AppText.title,
                ),
                const SizedBox(height: 8),
                Text(
                  pending > 0
                      ? context.t(
                          'ui.audit510',
                          args: {
                            'p0': laborMoney(
                              total,
                              strings: AppStrings.of(context),
                            ),
                          },
                        )
                      : context.t('ui.audit511'),
                  style: AppText.caption,
                ),
                Text(
                  planned ? context.t('ui.audit512') : context.t('ui.audit513'),
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          if (people.isEmpty) Information(context.t('ui.audit4')),
          for (final person in people)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AppCard(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(24),
                  title: Text(person['nickname'], style: AppText.body),
                  subtitle: Text(
                    context.t(
                      'ui.audit514',
                      args: {
                        'p0': laborMoney(
                          person['hourlyWon'],
                          strings: AppStrings.of(context),
                        ),
                        'p1': laborMoney(
                          person[key]['totalWon'],
                          strings: AppStrings.of(context),
                        ),
                        'p2': (person[key]['alerts'] as List).length,
                      },
                    ),
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
          body: Information(context.t('ui.audit5')),
        );
      }
      final result = person[planned ? 'planned' : 'actual'] as Json;
      return AppEditorScaffold(
        title: context.t('ui.audit515', args: {'p0': person['nickname']}),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              laborMoney(result['totalWon'], strings: AppStrings.of(context)),
              style: AppText.title,
            ),
            Text(
              context.t(
                'ui.audit516',
                args: {
                  'p0': week,
                  'p1': planned
                      ? context.t('ui.audit507')
                      : context.t('ui.audit508'),
                },
              ),
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
                    Expanded(
                      child: Text(
                        context.t(entry.value),
                        style: AppText.caption,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Text(
                        laborMoney(
                          result[entry.key],
                          strings: AppStrings.of(context),
                        ),
                        textAlign: TextAlign.end,
                        style: AppText.body,
                      ),
                    ),
                  ],
                ),
              ),
            if (result['weeklyRestIncluded'] == false)
              Text(
                context.t(
                  'ui.audit517',
                  args: {
                    'p0':
                        result['weeklyRestWeeks'] ?? context.t('ui.audit1092'),
                    'p1': laborMoney(
                      result['weeklyRestAccruedWon'],
                      strings: AppStrings.of(context),
                    ),
                  },
                ),
                style: AppText.caption,
              ),
            const SizedBox(height: 16),
            Text(
              context.t(
                'ui.audit518',
                args: {
                  'p0': ((result['workedMinutes'] as num) / 60).toStringAsFixed(
                    1,
                  ),
                  'p1': ((result['overtimeMinutes'] as num) / 60)
                      .toStringAsFixed(1),
                  'p2': ((result['nightMinutes'] as num) / 60).toStringAsFixed(
                    1,
                  ),
                },
              ),
              style: AppText.caption,
            ),
            const SizedBox(height: 32),
            Text(context.t('ui.audit6'), style: AppText.body),
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
                child: Text(context.t('ui.audit7')),
              ),
            ),
            if (ops.readOnly)
              Text(context.t('ui.audit8'), style: AppText.caption),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => launchUrl(
                Uri.parse('https://1350.moel.go.kr/rtmview.do?id=1000263464'),
                mode: LaunchMode.externalApplication,
              ),
              child: Text(context.t('ui.audit9')),
            ),
            Text(context.t('ui.audit10'), style: AppText.caption),
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
  late final int revision;
  late final String openingActor;
  @override
  void initState() {
    super.initState();
    revision = widget.ops.data?['revision'] as int? ?? 0;
    openingActor = widget.ops.actorId;
  }

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
          DropdownMenuItem(value: e.key, child: Text(context.t(e.value))),
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
        setState(() => error = context.t('ui.audit1234'));
        return;
      }
      values[key] = key.endsWith('Won') ? n.round() : (n * 60).round();
    }
    setState(() {
      saving = true;
      error = null;
    });
    if (openingActor != widget.ops.actorId) {
      setState(() {
        saving = false;
        error = context.t('ui.audit1235');
      });
      return;
    }
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
      error = ok ? null : widget.ops.error ?? context.t('ui.audit760');
    });
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: AppEditorScaffold(
      title: context.t('ui.audit519'),
      subtitle: context.t(
        'ui.audit520',
        args: {'p0': widget.person['nickname'], 'p1': widget.week},
      ),
      body: AbsorbPointer(
        absorbing: saving,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            AppFormSection(
              title: context.t('ui.audit521'),
              children: [
                picker(context.t('ui.audit1093'), scope, {
                  'unknown': context.t('ui.audit1094'),
                  'standard': context.t('ui.audit1095'),
                }, (v) => scope = v),
                TextButton(
                  onPressed: () => showAppSheet(
                    context,
                    builder: (_) => PayrollSettingsScreen(ops: widget.ops),
                  ),
                  child: Text(context.t('ui.audit11')),
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
                Text(context.t('ui.audit12'), style: AppText.caption),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    final average = num.tryParse(
                      controllers['averageWeeklyMinutes']?.text ?? '',
                    );
                    if (average != null && average >= 0 && average <= 40) {
                      field('restMinutes', 0).text = (average / 5)
                          .toStringAsFixed(2);
                      setState(() {});
                    }
                  },
                  child: Text(context.t('ui.audit13')),
                ),
              ],
            ),
            AppFormSection(
              title: context.t('ui.audit522'),
              children: [
                picker(context.t('ui.audit1096'), attendance, {
                  'unknown': context.t('ui.audit1097'),
                  'met': context.t('ui.audit1098'),
                  'unmet': context.t('ui.audit1099'),
                }, (v) => attendance = v),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.t('ui.audit14')),
                  value: shortTime,
                  onChanged: (v) => setState(() => shortTime = v),
                ),
                if (shortTime) ...[
                  Text(context.t('ui.audit15'), style: AppText.body),
                  for (var i = 0; i < 7; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppPicker<int>(
                        label: [
                          context.t('ui.audit523'),
                          context.t('ui.audit524'),
                          context.t('ui.audit525'),
                          context.t('ui.audit526'),
                          context.t('ui.audit527'),
                          context.t('ui.audit528'),
                          context.t('ui.audit529'),
                        ][i],
                        value: daily[i],
                        items: [
                          for (var m = 0; m <= 480; m += 30)
                            DropdownMenuItem(
                              value: m,
                              child: Text(
                                context.t('ui.audit530', args: {'p0': m / 60}),
                              ),
                            ),
                        ],
                        onChanged: (v) => setState(() => daily[i] = v!),
                      ),
                    ),
                ],
              ],
            ),
            AppFormSection(
              title: context.t('ui.audit531'),
              children: [
                const SizedBox(height: 24),
                Text(context.t('ui.audit16'), style: AppText.body),
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
                Text(context.t('ui.audit17'), style: AppText.caption),
                const SizedBox(height: 16),
                number(
                  'otherPaidHolidayMinutes',
                  '주휴 외 유급휴일 지급시간 · 시간',
                  (draft['otherPaidHolidayMinutes'] ?? 0) / 60,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.t('ui.audit18')),
                  value: holidaysConfirmed,
                  onChanged: (v) => setState(() => holidaysConfirmed = v),
                ),
              ],
            ),
          ],
        ),
      ),
      footer: AppSheetFooter(
        children: [
          if (error != null)
            Semantics(
              liveRegion: true,
              child: Text(
                error!,
                style: AppText.caption.copyWith(color: AppColors.accent),
              ),
            ),
          FilledButton(
            onPressed: saving || widget.ops.readOnly ? null : save,
            child: Text(
              saving ? context.t('ui.audit532') : context.t('ui.audit533'),
            ),
          ),
        ],
      ),
    ),
  );
}
