import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';

class PayrollSettingsScreen extends StatefulWidget {
  const PayrollSettingsScreen({super.key, required this.ops});
  final OperationsController ops;
  @override
  State<PayrollSettingsScreen> createState() => _PayrollSettingsScreenState();
}

class _PayrollSettingsScreenState extends State<PayrollSettingsScreen> {
  late final int revision;
  late final String actorId;
  late String cycle, size;
  late int monthDay, weekDay, rounding;
  late bool includeRest;
  bool dirty = false, saving = false;
  String? error;
  static const roundingValues = [0, 1, 5, 10, 30];
  static const days = ['월', '화', '수', '목', '금', '토', '일'];
  @override
  void initState() {
    super.initState();
    final p = widget.ops.data?['payrollSettings'] as Json? ?? {};
    revision = widget.ops.data?['revision'] ?? 0;
    actorId = widget.ops.actorId;
    cycle = p['cycle'] ?? 'monthly';
    size = p['businessSize'] ?? 'unknown';
    monthDay = p['monthStartDay'] ?? 1;
    weekDay = p['weekStartDay'] ?? 1;
    rounding = p['roundingMinutes'] ?? 0;
    includeRest = p['includeWeeklyRest'] ?? true;
  }

  bool get editable =>
      widget.ops.isOwner && !widget.ops.readOnly && !saving && !widget.ops.busy;
  void change(VoidCallback fn) => setState(() {
    fn();
    dirty = true;
  });
  Future<void> close() async {
    if (saving) return;
    if (dirty) {
      final discard = await showAppDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(context.t('ui.audit178')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(context.t('ui.audit21')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(context.t('ui.audit22')),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    if (mounted) {
      setState(() => dirty = false);
      Navigator.pop(context);
    }
  }

  Future<void> save() async {
    if (!editable) return;
    if (widget.ops.actorId != actorId) {
      setState(() => error = context.t('ui.audit1278'));
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    final ok = await widget.ops.act('save_payroll_settings', {
      'revision': revision,
      'settings': {
        'cycle': cycle,
        'monthStartDay': monthDay,
        'weekStartDay': weekDay,
        'roundingMinutes': rounding,
        'businessSize': size,
        'includeWeeklyRest': includeRest,
      },
    });
    if (!mounted) return;
    setState(() {
      saving = false;
      error = ok ? null : widget.ops.error;
      dirty = !ok;
    });
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !dirty && !saving,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) close();
    },
    child: AppEditorScaffold(
      title: context.t('ui.audit3'),
      subtitle: context.t('ui.audit1000'),
      onClose: close,
      body: !widget.ops.isOwner
          ? Information(context.t('ui.audit427'))
          : AbsorbPointer(
              absorbing: saving,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: appEditorWidth),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    children: [
                      AppFormSection(
                        title: context.t('ui.audit1001'),
                        description: context.t('ui.audit1002'),
                        children: [
                          AppChoiceGroup<String>(
                            values: const ['monthly', 'weekly'],
                            selected: cycle,
                            labelOf: (v) => v == 'monthly'
                                ? context.t('ui.audit1206')
                                : context.t('ui.audit1207'),
                            onSelected: (v) => change(() => cycle = v),
                          ),
                        ],
                      ),
                      AppFormSection(
                        title: context.t('ui.audit1003'),
                        children: [
                          Text(
                            cycle == 'monthly'
                                ? context.t(
                                    'ui.audit1004',
                                    args: {'p0': monthDay},
                                  )
                                : context.t(
                                    'ui.audit1005',
                                    args: {'p0': context.t(days[weekDay - 1])},
                                  ),
                            style: AppText.title.copyWith(
                              color: AppColors.green,
                            ),
                          ),
                          AnimatedSize(
                            duration: AppMotion.duration(
                              context,
                              AppMotion.content,
                            ),
                            curve: AppMotion.enterCurve,
                            alignment: Alignment.topCenter,
                            child: cycle == 'monthly'
                                ? Slider(
                                    key: const ValueKey('payroll-start-day'),
                                    value: monthDay.toDouble(),
                                    min: 1,
                                    max: 31,
                                    divisions: 30,
                                    label: context.t(
                                      'ui.audit957',
                                      args: {'p0': monthDay},
                                    ),
                                    semanticFormatterCallback: (value) =>
                                        context.t(
                                          'ui.audit1004',
                                          args: {'p0': value.round()},
                                        ),
                                    onChanged: (v) =>
                                        change(() => monthDay = v.round()),
                                  )
                                : AppChoiceGroup<int>(
                                    values: const [1, 2, 3, 4, 5, 6, 7],
                                    selected: weekDay,
                                    labelOf: (v) => context.t(days[v - 1]),
                                    onSelected: (v) =>
                                        change(() => weekDay = v),
                                  ),
                          ),
                          Text(
                            cycle == 'monthly'
                                ? (monthDay == 1
                                      ? context.t('ui.audit1006')
                                      : context.t(
                                          'ui.audit1007',
                                          args: {'p0': monthDay},
                                        ))
                                : context.t(
                                    'ui.audit1008',
                                    args: {'p0': context.t(days[weekDay - 1])},
                                  ),
                            style: AppText.caption,
                          ),
                        ],
                      ),
                      AppFormSection(
                        title: context.t('ui.audit1009'),
                        description: context.t('ui.audit1010'),
                        children: [
                          AppChoiceGroup<int>(
                            key: const ValueKey('payroll-rounding'),
                            values: roundingValues,
                            selected: rounding,
                            labelOf: (v) => v == 0
                                ? context.t('ui.audit1115')
                                : context.t('ui.audit920', args: {'p0': v}),
                            onSelected: (v) => change(() => rounding = v),
                          ),
                          Text(
                            rounding == 0
                                ? context.t('ui.audit1011')
                                : context.t(
                                    'ui.audit1012',
                                    args: {'p0': rounding},
                                  ),
                            style: AppText.caption,
                          ),
                          Text(
                            context.t('ui.audit428'),
                            style: AppText.caption,
                          ),
                        ],
                      ),
                      AppFormSection(
                        title: context.t('ui.audit1013'),
                        children: [
                          AppChoiceGroup<String>(
                            values: const ['under5', 'fivePlus'],
                            selected: size,
                            labelOf: (v) => v == 'under5'
                                ? context.t('ui.audit1208')
                                : context.t('ui.audit1209'),
                            onSelected: (v) => change(() => size = v),
                          ),
                          Text(
                            size == 'unknown'
                                ? context.t('ui.audit1014')
                                : size == 'under5'
                                ? context.t('ui.audit1015')
                                : context.t('ui.audit1016'),
                            style: AppText.caption,
                          ),
                        ],
                      ),
                      AppFormSection(
                        title: context.t('ui.audit1017'),
                        children: [
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: Text(context.t('ui.audit429')),
                            subtitle: Text(
                              includeRest
                                  ? context.t('ui.audit1018')
                                  : context.t('ui.audit1019'),
                            ),
                            value: includeRest,
                            onChanged: (v) => change(() => includeRest = v),
                          ),
                        ],
                      ),
                      Text(context.t('ui.audit430'), style: AppText.caption),
                    ],
                  ),
                ),
              ),
            ),
      footer: !widget.ops.isOwner
          ? null
          : AppSheetFooter(
              children: [
                if (widget.ops.readOnly)
                  Text(context.t('ui.audit8'), style: AppText.caption),
                if (error != null)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      context.t('ui.audit1020', args: {'p0': error}),
                      style: AppText.caption.copyWith(color: AppColors.accent),
                    ),
                  ),
                FilledButton(
                  onPressed: editable && size != 'unknown' ? save : null,
                  child: Text(
                    saving
                        ? context.t('ui.audit532')
                        : context.t('ui.audit1021'),
                  ),
                ),
              ],
            ),
    ),
  );
}
