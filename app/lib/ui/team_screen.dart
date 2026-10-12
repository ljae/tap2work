import '../l10n/app_localizations.dart';
import 'dart:math';
import '../domain/edit_conflict.dart';
import 'edit_conflict_dialog.dart';
import 'crew_invitation_screen.dart';
import 'time_wheel.dart';
import 'payroll_settings_screen.dart';
import 'workplace_screens.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state/operations_controller.dart';
import 'components.dart';
import 'country_flag.dart';

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
  String hours(dynamic minutes) => context.t(
    'ui.audit530',
    args: {'p0': ((minutes as num? ?? 0) / 60).toStringAsFixed(1)},
  );
  Future<void> action(String type, Json data) async {
    final ok = await ops.act(type, data);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? context.t('ui.audit888')
                : ops.error ?? context.t('ui.audit781'),
          ),
        ),
      );
    }
  }

  Future<String?> pickNationality(List<Json> countries, String? selected) {
    var query = '';
    return showAppSheet<String>(
      context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AppEditorScaffold(
          title: context.t('crew.nationality'),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: context.t('common.search'),
                  ),
                  onChanged: (value) =>
                      update(() => query = value.trim().toLowerCase()),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final country in countries.where(
                      (c) => '${c['name']} ${c['code']}'.toLowerCase().contains(
                        query,
                      ),
                    ))
                      ListTile(
                        leading: CountryFlag(
                          countryCode: country['code'] as String?,
                        ),
                        title: Text('${country['name']}'),
                        subtitle: Text('${country['code']}'),
                        selected: country['code'] == selected,
                        onTap: () =>
                            Navigator.pop(context, country['code'] as String),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> editCrew([Json? current]) async {
    final openingSnapshot = copyEditSnapshot(ops.data ?? {});
    final openingActor = ops.actorId;
    final openingWorkspace = ops.workspaceId;
    final creationRequestId = List.generate(
      24,
      (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final nickname = TextEditingController(text: current?['nickname'] ?? '');
    final rate = TextEditingController(
      text: '${current?['hourlyWon'] ?? 10320}',
    );
    final kakao = TextEditingController(text: current?['kakaoUrl'] ?? '');
    final phone = TextEditingController(text: current?['phone'] ?? '');
    var rank = current?['rank'] as String? ?? 'crew';
    String? nationality = current?['nationality'] as String?;
    String? guideLocale = current?['guideLocale'] as String?;
    final nationalityOptions = ops.rows('nationalityOptions');
    final period = current?['payPeriod'] as String? ?? 'monthly';
    var employment = current?['employmentType'] as String? ?? '시간알바';
    var saving = false;
    var leaving = false;
    String? saveError;
    String signature() =>
        '${nickname.text}|${rate.text}|${kakao.text}|${phone.text}|$rank|$nationality|$guideLocale|$employment';
    final initialSignature = signature();
    Future<dynamic>? sheetClosed;
    await showAppFormSheet<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) {
          sheetClosed =
              (ModalRoute.of(context) as TransitionRoute<dynamic>?)?.completed;
          Future<void> cancel() async {
            if (saving) return;
            if (signature() != initialSignature) {
              final discard = await showAppDialog<bool>(
                context: context,
                builder: (dialog) => AlertDialog(
                  title: Text(context.t('ui.audit345')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialog, false),
                      child: Text(context.t('ui.audit21')),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(dialog, true),
                      child: Text(context.t('ui.audit346')),
                    ),
                  ],
                ),
              );
              if (discard != true || !context.mounted) return;
            }
            update(() => leaving = true);
            Navigator.pop(context);
          }

          return PopScope(
            canPop: leaving,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) cancel();
            },
            child: AppSheetPanel(
              title: Text(
                widget.payOnly
                    ? context.t('ui.audit371')
                    : current == null
                    ? context.t('ui.audit369')
                    : context.t('ui.audit889'),
              ),
              content: AbsorbPointer(
                absorbing: saving,
                child: SizedBox(
                  width: 430,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 20,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (saveError != null)
                          Information(
                            context.t('ui.audit890', args: {'p0': saveError}),
                          ),
                        if (!widget.payOnly)
                          TextField(
                            controller: nickname,
                            onChanged: (_) => update(() {}),
                            decoration: InputDecoration(
                              labelText: context.t('ui.audit347'),
                            ),
                          ),
                        if (!widget.payOnly) ...[
                          InputDecorator(
                            decoration: InputDecoration(
                              labelText: context.t('crew.nationality'),
                            ),
                            child: TextButton.icon(
                              key: const ValueKey('crew-nationality'),
                              onPressed: () async {
                                final selected = await pickNationality(
                                  nationalityOptions,
                                  nationality,
                                );
                                if (selected != null && context.mounted) {
                                  update(() => nationality = selected);
                                }
                              },
                              icon: CountryFlag(countryCode: nationality),
                              label: Text(
                                '${nationalityOptions.where((c) => c['code'] == nationality).firstOrNull?['name'] ?? context.t('crew.select')}',
                              ),
                            ),
                          ),
                          AppPicker<String>(
                            key: const ValueKey('crew-guide-language'),
                            label: context.t('crew.guideLanguage'),
                            value: guideLocale,
                            items: appLanguageNames.entries
                                .map(
                                  (language) => DropdownMenuItem<String>(
                                    value: language.key,
                                    child: LanguageLabel(
                                      languageTag: language.key,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                update(() => guideLocale = value),
                          ),
                          Text(
                            context.t('crew.languageIndependent'),
                            style: AppText.caption,
                          ),
                        ],
                        if (!widget.payOnly)
                          AppPicker<String>(
                            label: context.t('ui.audit891'),
                            value: rank,
                            items: _ranks.entries
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(context.t(e.value)),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => update(() => rank = v!),
                          ),
                        if (!widget.payOnly)
                          AppPicker<String>(
                            label: context.t('ui.audit162'),
                            value: employment,
                            items: ['정규직', '시간알바', '정규알바']
                                .map(
                                  (v) => DropdownMenuItem(
                                    value: v,
                                    child: Text(v),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => update(() => employment = v!),
                          ),
                        if (!widget.payOnly)
                          Text(
                            context.t('ui.audit348'),
                            style: AppText.caption,
                          ),
                        if (widget.payOnly)
                          TextField(
                            controller: rate,
                            onChanged: (_) => update(() {}),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: context.t('ui.audit349'),
                            ),
                          ),
                        if (widget.payOnly)
                          TextButton(
                            onPressed: () => showAppSheet(
                              context,
                              builder: (_) => PayrollSettingsScreen(ops: ops),
                            ),
                            child: Text(context.t('ui.audit350')),
                          ),
                        if (!widget.payOnly)
                          TextField(
                            controller: kakao,
                            decoration: InputDecoration(
                              labelText: context.t('ui.audit351'),
                            ),
                          ),
                        if (!widget.payOnly)
                          TextField(
                            controller: phone,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: context.t('ui.audit352'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                PressBounce(
                  child: TextButton(
                    onPressed: saving ? null : cancel,
                    child: Text(context.t('ui.audit33')),
                  ),
                ),
                PressBounce(
                  child: FilledButton(
                    onPressed:
                        saving ||
                            nickname.text.trim().isEmpty ||
                            (!widget.payOnly &&
                                (nationality == null || guideLocale == null)) ||
                            int.tryParse(rate.text) == null
                        ? null
                        : () async {
                            if (saving) return;
                            update(() {
                              saving = true;
                              saveError = null;
                            });
                            final ok = await ops.saveDraft(
                              'save_tapper',
                              {
                                if (current != null) 'id': current['id'],
                                if (current == null)
                                  'creationRequestId': creationRequestId,
                                'nickname': nickname.text.trim(),
                                if (!widget.payOnly) 'nationality': nationality,
                                if (!widget.payOnly) 'guideLocale': guideLocale,
                                'rank': rank,
                                'employmentType': employment,
                                'hourlyWon': int.parse(rate.text),
                                'payPeriod': period,
                                'kakaoUrl': kakao.text.trim(),
                                'phone': phone.text.trim(),
                                'active': current?['active'] ?? true,
                              },
                              baseSnapshot: openingSnapshot,
                              openingActor: openingActor,
                              openingWorkspace: openingWorkspace,
                              resolve: (conflicts) => context.mounted
                                  ? showEditConflictDialog(
                                      context,
                                      conflicts,
                                      ops: ops,
                                    )
                                  : Future.value(
                                      EditConflictChoice.keepEditing,
                                    ),
                            );
                            if (!context.mounted) return;
                            update(() {
                              saving = false;
                              saveError = ok ? null : ops.error;
                              leaving = ok;
                            });
                            if (ok) Navigator.pop(context);
                          },
                    child: Text(
                      saving
                          ? context.t('ui.audit532')
                          : context.t('ui.audit51'),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    await sheetClosed;
    nickname.dispose();
    rate.dispose();
    kakao.dispose();
    phone.dispose();
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
          title: Text(
            context.t('ui.audit892', args: {'p0': tapper['nickname']}),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 20,
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
                label: context.t('ui.audit893'),
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
                    final next = await showTimeWheel(
                      context,
                      title: context.t('ui.audit755'),
                      value:
                          '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
                    );
                    if (next != null) {
                      update(
                        () => start = TimeOfDay(
                          hour: int.parse(next.split(':')[0]),
                          minute: int.parse(next.split(':')[1]),
                        ),
                      );
                    }
                  },
                  child: Text(
                    context.t(
                      'ui.audit842',
                      args: {'p0': start.format(context)},
                    ),
                  ),
                ),
              ),
              PressBounce(
                child: OutlinedButton(
                  onPressed: () async {
                    final next = await showTimeWheel(
                      context,
                      title: context.t('ui.audit756'),
                      value:
                          '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
                    );
                    if (next != null) {
                      update(
                        () => end = TimeOfDay(
                          hour: int.parse(next.split(':')[0]),
                          minute: int.parse(next.split(':')[1]),
                        ),
                      );
                    }
                  },
                  child: Text(
                    context.t('ui.audit843', args: {'p0': end.format(context)}),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            PressBounce(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.t('ui.audit33')),
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
                child: Text(context.t('ui.audit353')),
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
        title: Text(
          type == 'record_payment'
              ? context.t('ui.audit894')
              : context.t('ui.audit895'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: context.t('ui.audit354')),
            ),
            if (type == 'add_pay_adjustment')
              TextField(
                controller: note,
                decoration: InputDecoration(
                  labelText: context.t('ui.audit355'),
                ),
              ),
          ],
        ),
        actions: [
          PressBounce(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.t('ui.audit33')),
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
              child: Text(context.t('ui.audit356')),
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
          content: Text(
            phone ? context.t('ui.audit896') : context.t('ui.audit897'),
          ),
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
                  if (person['nationality'] is String) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CountryFlag(
                          countryCode: person['nationality'] as String,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${ops.rows('nationalityOptions').where((c) => c['code'] == person['nationality']).firstOrNull?['name'] ?? person['nationality']}',
                            style: AppText.caption,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: () => openPerson(person['id']),
              tooltip: context.t('ui.audit898'),
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
        return AppEditorScaffold(
          title: context.t('ui.audit899'),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              staffCardHeader(person),
              if (ops.isOwner) ...[
                const SizedBox(height: 16),
                Surface(
                  child: SettingRow(
                    title: context.t('ui.audit900'),
                    subtitle: context.t(
                      'ui.audit901',
                      args: {
                        'p0': money(person['hourlyWon'] ?? 0),
                        'p1': hours(person['plannedMinutes']),
                      },
                    ),
                    icon: CupertinoIcons.money_dollar_circle,
                    onTap: () => showAppSheet(
                      context,
                      builder: (_) => AppEditorScaffold(
                        title: context.t('ui.audit900'),
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
                      title: context.t('ui.audit902'),
                      subtitle: context.t('ui.audit903'),
                      icon: CupertinoIcons.slider_horizontal_3,
                      onTap: ops.isOwner
                          ? () =>
                                openWorkplaceHours(context, ops, staffing: true)
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Surface(
                child: SettingRow(
                  title: context.t('ui.audit904'),
                  subtitle: context.t('ui.audit905'),
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
                    Text(context.t('ui.audit357'), style: AppText.caption),
                    const SizedBox(height: 12),
                    Text(
                      context.t(
                        'ui.audit906',
                        args: {'p0': hours(person['weeklyActualMinutes'])},
                      ),
                      style: AppText.body,
                    ),
                    if (records.isEmpty)
                      Text(context.t('ui.audit358'), style: AppText.caption),
                    for (final record in records.take(12))
                      SettingRow(
                        title:
                            {
                              'clock_in': context.t('ui.audit364'),
                              'clock_out': context.t('ui.audit367'),
                              'break_start': context.t('ui.audit365'),
                              'break_end': context.t('ui.audit366'),
                            }[record['type']] ??
                            context.t('ui.audit356'),
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
                    Text(context.t('ui.audit359'), style: AppText.caption),
                    if (shifts.isEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(context.t('ui.audit907')),
                      ),
                    for (final shift in shifts.take(14))
                      SettingRow(
                        title:
                            '${shift['date']} · ${shift['start']}–${shift['end']}',
                        subtitle:
                            '${partLabel(ops, shift['partId'])}${shift['status'] == 'leave'
                                ? ' · 승인된 휴무'
                                : shift['approvedRequestId'] != null
                                ? ' · 승인 반영'
                                : ''}',
                      ),
                    if (ops.isLeader)
                      TextButton(
                        onPressed: ops.readOnly
                            ? null
                            : () => editShift(person),
                        child: Text(context.t('ui.audit360')),
                      ),
                  ],
                ),
              ),
              if (ops.isOwner) ...[
                const SizedBox(height: 16),
                Surface(
                  child: SettingRow(
                    title: context.t('ui.audit908'),
                    icon: CupertinoIcons.pencil,
                    onTap: ops.readOnly ? null : () => editCrew(person),
                  ),
                ),
              ],
              if ((person['phone'] ?? '').toString().isNotEmpty)
                TextButton(
                  onPressed: () => openContact(person['phone'], phone: true),
                  child: Text(context.t('ui.audit361')),
                ),
              if ((person['kakaoUrl'] ?? '').toString().isNotEmpty)
                TextButton(
                  onPressed: () =>
                      openContact(person['kakaoUrl'], phone: false),
                  child: Text(context.t('ui.audit362')),
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
              Text(
                _ranks[person['rank']] ?? context.t('ui.audit765'),
                style: AppText.caption,
              ),
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
          if (widget.payOnly) Information(context.t('ui.audit363')),
          if (!widget.payOnly && own != null)
            Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t(
                      'ui.audit909',
                      args: {
                        'p0': own['nickname'],
                        'p1': state == 'clock_in' || state == 'break_end'
                            ? context.t('ui.audit1176')
                            : state == 'break_start'
                            ? context.t('ui.audit1177')
                            : context.t('ui.audit1178'),
                      },
                    ),
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
                            child: Text(context.t('ui.audit364')),
                          ),
                        ),
                      if (state == 'clock_in' || state == 'break_end')
                        PressBounce(
                          child: OutlinedButton(
                            onPressed: ops.readOnly || ops.busy
                                ? null
                                : () => action('break_start', {}),
                            child: Text(context.t('ui.audit365')),
                          ),
                        ),
                      if (state == 'break_start')
                        PressBounce(
                          child: OutlinedButton(
                            onPressed: ops.readOnly || ops.busy
                                ? null
                                : () => action('break_end', {}),
                            child: Text(context.t('ui.audit366')),
                          ),
                        ),
                      if (state == 'clock_in' || state == 'break_end')
                        PressBounce(
                          child: FilledButton(
                            onPressed: ops.readOnly || ops.busy
                                ? null
                                : () => action('clock_out', {}),
                            child: Text(context.t('ui.audit367')),
                          ),
                        ),
                    ],
                  ),
                  if (ops.readOnly) Text(context.t('ui.audit368')),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (!widget.payOnly && ops.isOwner)
            PressBounce(
              child: FilledButton.icon(
                onPressed: ops.busy || ops.readOnly ? null : () => editCrew(),
                icon: const Icon(Icons.person_add_alt),
                label: Text(context.t('ui.audit369')),
              ),
            ),
          if (!widget.payOnly && ops.canManageCrewInvites)
            TextButton.icon(
              onPressed: () => showAppSheet(
                context,
                builder: (_) => ops.cloud
                    ? CrewInvitationScreen(ops: ops, management: true)
                    : WorkplaceSettings(ops: ops, section: 'invite'),
              ),
              icon: const Icon(CupertinoIcons.qrcode),
              label: Text(
                context.t(
                  ops.cloud ? 'invite.managementEntry' : 'invite.demoEntry',
                ),
              ),
            ),
          if (!widget.payOnly && ops.cloud)
            TextButton(
              onPressed: () => showAppSheet(
                context,
                builder: (_) => CrewInvitationScreen(ops: ops),
              ),
              child: Text(context.t('invite.joinOther')),
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
                    chipAnimationStyle: AppMotion.chipStyle(context),
                    label: Text(context.t('ui.audit370')),
                    selected: selectedPart == null,
                    onSelected: (_) => setState(() => selectedPart = null),
                  ),
                  for (final part in storeParts(
                    ops,
                  ).where((p) => p['hidden'] != true))
                    ChoiceChip(
                      chipAnimationStyle: AppMotion.chipStyle(context),
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
                            context.t(
                              'ui.audit910',
                              args: {
                                'p0': hours(tapper['plannedMinutes']),
                                'p1': hours(tapper['weeklyActualMinutes']),
                              },
                            ),
                          ),
                          if (widget.payOnly && tapper['gross'] != null) ...[
                            Text(
                              '${tapper['payPeriodStart']} ~ ${tapper['payPeriodEnd'] ?? ops.data?['day']}',
                              style: AppText.caption,
                            ),
                            Text(
                              context.t(
                                'ui.audit911',
                                args: {
                                  'p0': money(tapper['hourlyWon']),
                                  'p1': _periods[tapper['payPeriod']],
                                },
                              ),
                            ),
                            Text(
                              context.t(
                                'ui.audit912',
                                args: {'p0': money(tapper['gross'])},
                              ),
                            ),
                            Text(
                              context.t(
                                'ui.audit913',
                                args: {
                                  'p0': money(tapper['paid']),
                                  'p1': money(tapper['remaining']),
                                  'p2': money(tapper['adjustments']),
                                },
                              ),
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
                                    child: Text(context.t('ui.audit371')),
                                  ),
                                ),
                              if (!widget.payOnly && ops.isOwner)
                                PressBounce(
                                  child: TextButton(
                                    onPressed: ops.readOnly
                                        ? null
                                        : () => editCrew(tapper),
                                    child: Text(context.t('ui.audit155')),
                                  ),
                                ),
                              if (!widget.payOnly && ops.isLeader)
                                PressBounce(
                                  child: TextButton(
                                    onPressed: ops.readOnly
                                        ? null
                                        : () => editShift(tapper),
                                    child: Text(context.t('ui.audit360')),
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
                                    child: Text(context.t('ui.audit372')),
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
                                    child: Text(context.t('ui.audit373')),
                                  ),
                                ),
                              if ((tapper['phone'] ?? '').toString().isNotEmpty)
                                PressBounce(
                                  child: TextButton(
                                    onPressed: () => openContact(
                                      tapper['phone'],
                                      phone: true,
                                    ),
                                    child: Text(context.t('ui.audit361')),
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
                                    child: Text(context.t('ui.audit362')),
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
