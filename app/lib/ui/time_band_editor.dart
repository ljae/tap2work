import '../l10n/entity_name_scope.dart';
import '../l10n/app_localizations.dart';
import 'time_wheel.dart';
import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';

/// Returns a draft; the parent saves all weekdays with its opening revision.
class TimeBandEditor extends StatefulWidget {
  const TimeBandEditor({
    super.key,
    required this.parts,
    required this.openDays,
    required this.initialDays,
    this.band,
  });
  final List<Json> parts;
  final Set<int> openDays, initialDays;
  final Json? band;
  @override
  State<TimeBandEditor> createState() => _TimeBandEditorState();
}

class _TimeBandEditorState extends State<TimeBandEditor> {
  late final name = TextEditingController(text: widget.band?['name'] ?? '');
  late String start = widget.band?['start'] ?? '09:00',
      end = widget.band?['end'] ?? '10:00';
  late final days = {...widget.initialDays};
  late final selected = <String>{
    for (final p in widget.parts)
      if (widget.band != null &&
          (widget.band?['headcounts']?[p['id']] ??
                  (widget.band?['custom'] == true ? 0 : 1)) >
              0)
        p['id'],
  };
  String? error;
  bool dirty = false, leaving = false;
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> close() async {
    if (dirty) {
      final discard = await showAppDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(context.t('ui.audit178')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(context.t('ui.audit179')),
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
    if (!mounted) return;
    setState(() => leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> time(bool first) async {
    final value = await showTimeWheel(
      context,
      title: first ? context.t('ui.audit755') : context.t('ui.audit756'),
      value: first ? start : end,
    );
    if (value == null || !mounted) return;
    setState(() {
      if (first) {
        start = value;
      } else {
        end = value;
      }
      dirty = true;
      error = null;
    });
  }

  void apply() {
    if (name.text.trim().isEmpty ||
        name.text.trim().length > 40 ||
        selected.isEmpty ||
        days.isEmpty ||
        start == end) {
      setState(() => error = context.t('ui.audit1264'));
      return;
    }
    final counts = <String, dynamic>{
      ...?(widget.band?['headcounts'] as Map?)?.cast<String, dynamic>(),
    };
    for (final p in widget.parts) {
      counts[p['id']] = selected.contains(p['id'])
          ? ((counts[p['id']] as int? ?? 0) > 0 ? counts[p['id']] : 1)
          : 0;
    }
    final result = <String, dynamic>{
      'days': days.toList(),
      'band': {
        ...?(widget.band),
        'custom': true,
        'name': name.text.trim(),
        'start': start,
        'end': end,
        'headcounts': counts,
      },
    };
    setState(() => leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context, result);
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: leaving,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) close();
    },
    child: AppEditorScaffold(
      title: widget.band == null
          ? context.t('ui.audit861')
          : context.t('ui.audit862'),
      onClose: close,
      footer: AppSheetFooter(
        children: [
          if (error != null)
            Text(
              error!,
              style: AppText.caption.copyWith(color: AppColors.accent),
            ),
          FilledButton(
            onPressed: leaving ? null : apply,
            child: Text(context.t('ui.audit315')),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          AppFormSection(
            title: context.t('ui.audit38'),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final v in ['오픈', '미들', '마감'])
                    ActionChip(
                      label: Text(v),
                      onPressed: () => setState(() {
                        name.text = v;
                        dirty = true;
                      }),
                    ),
                ],
              ),
              TextField(
                controller: name,
                maxLength: 40,
                decoration: InputDecoration(
                  labelText: context.t('ui.audit316'),
                ),
                onChanged: (_) => setState(() => dirty = true),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton(
                    onPressed: () => time(true),
                    child: Text(context.t('ui.audit842', args: {'p0': start})),
                  ),
                  OutlinedButton(
                    onPressed: () => time(false),
                    child: Text(context.t('ui.audit843', args: {'p0': end})),
                  ),
                ],
              ),
              if (end.compareTo(start) < 0) Text(context.t('ui.audit317')),
            ],
          ),
          AppFormSection(
            title: context.t('ui.audit160'),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in widget.parts)
                    FilterChip(
                      label: Text(
                        entityDisplayName(
                          context,
                          null,
                          'part',
                          p['id'],
                          p['name'],
                        ),
                      ),
                      selected: selected.contains(p['id']),
                      onSelected: (v) => setState(() {
                        v ? selected.add(p['id']) : selected.remove(p['id']);
                        dirty = true;
                      }),
                    ),
                ],
              ),
              Text(context.t('ui.audit318')),
            ],
          ),
          AppFormSection(
            title: context.t('ui.audit863'),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var d = 1; d <= 7; d++)
                    FilterChip(
                      label: Text(
                        '${['월', '화', '수', '목', '금', '토', '일'][d - 1]}${widget.openDays.contains(d) ? '' : ' · 휴무'}',
                      ),
                      selected: days.contains(d),
                      onSelected: widget.openDays.contains(d)
                          ? (v) => setState(() {
                              v ? days.add(d) : days.remove(d);
                              dirty = true;
                            })
                          : null,
                    ),
                ],
              ),
              Text(context.t('ui.audit319')),
            ],
          ),
          Text(context.t('ui.audit320')),
        ],
      ),
    ),
  );
}
