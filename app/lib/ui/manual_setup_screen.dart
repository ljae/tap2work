import 'dart:convert';
import '../domain/edit_conflict.dart';
import 'edit_conflict_dialog.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';
import 'place_guide.dart';

class ManualConditions extends StatelessWidget {
  const ManualConditions({
    super.key,
    required this.values,
    required this.onChanged,
  });
  final Json values;
  final void Function(String, bool?) onChanged;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final e in {'selfbar': '셀프바 운영', 'tableBurner': '테이블 화구 사용'}.entries)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DropdownButtonFormField<String>(
            key: ValueKey('${e.key}-${values[e.key]}'),
            initialValue: values[e.key] == null
                ? 'unknown'
                : values[e.key] == true
                ? 'yes'
                : 'no',
            decoration: InputDecoration(labelText: context.t(e.value)),
            items: [
              DropdownMenuItem(
                value: 'unknown',
                child: Text(context.t('ui.audit739')),
              ),
              DropdownMenuItem(
                value: 'yes',
                child: Text(context.t('ui.audit740')),
              ),
              DropdownMenuItem(
                value: 'no',
                child: Text(context.t('ui.audit741')),
              ),
            ],
            onChanged: (v) =>
                onChanged(e.key, v == 'unknown' ? null : v == 'yes'),
          ),
        ),
    ],
  );
}

Future<void> openManualSetup(BuildContext context, OperationsController ops) =>
    showAppFormSheet<void>(
      context: context,
      builder: (_) => ManualSetupScreen(ops: ops),
    );

class ManualSetupScreen extends StatefulWidget {
  const ManualSetupScreen({super.key, required this.ops});
  final OperationsController ops;
  @override
  State<ManualSetupScreen> createState() => _ManualSetupScreenState();
}

class _ManualSetupScreenState extends State<ManualSetupScreen> {
  late final Json conditions, places, openingSnapshot;
  late final String actor, original;
  late final Object? workspace;
  late int revision;
  @override
  void initState() {
    super.initState();
    openingSnapshot = copyEditSnapshot(widget.ops.data!);
    actor = widget.ops.actorId;
    workspace = widget.ops.workspaceId;
    revision = openingSnapshot['revision'] ?? 0;
    conditions = {
      ...(openingSnapshot['store']?['manualSetup']?['conditions'] as Json? ??
          {}),
    };
    places = {
      ...(openingSnapshot['store']?['manualSetup']?['places'] as Json? ?? {}),
    };
    original = jsonEncode(openingSnapshot['store']?['manualSetup']);
  }

  Future<void> leave() async {
    if (busy) return;
    final discard =
        !changed ||
        await showAppDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: Text(context.t('ui.audit178')),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: Text(context.t('ui.audit179')),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: Text(context.t('ui.audit22')),
                  ),
                ],
              ),
            ) ==
            true;
    if (discard && mounted) Navigator.pop(context);
  }

  bool busy = false, changed = false;
  String? error;
  Future<void> save() async {
    if (busy) return;
    if (actor != widget.ops.actorId ||
        workspace != widget.ops.data?['workspaceId']) {
      setState(() => error = context.t('ui.audit1246'));
      return;
    }
    setState(() => busy = true);
    final ok = await widget.ops.saveDraft(
      'save_manual_setup',
      {
        'setup': {'conditions': conditions, 'places': places},
      },
      baseSnapshot: openingSnapshot,
      openingActor: actor,
      openingWorkspace: workspace as String?,
      resolve: (conflicts) => mounted
          ? showEditConflictDialog(context, conflicts, ops: widget.ops)
          : Future.value(EditConflictChoice.keepEditing),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() {
        error = widget.ops.error;
        busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) leave();
    },
    child: AppEditorScaffold(
      title: context.t('ui.audit742'),
      onClose: leave,
      footer: AppSheetFooter(
        children: [
          FilledButton(
            onPressed: busy ? null : save,
            child: Text(
              busy ? context.t('ui.audit532') : context.t('ui.audit743'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(context.t('ui.audit231'), style: AppText.body),
          const SizedBox(height: 24),
          ManualConditions(
            values: conditions,
            onChanged: (k, v) => setState(() {
              conditions[k] = v;
              changed = true;
            }),
          ),
          Text(context.t('ui.audit232'), style: AppText.section),
          const SizedBox(height: 16),
          for (final e in {
            'return': context.t('setup.returnPlace'),
            'waste': context.t('setup.wastePlace'),
            'wash': context.t('setup.washPlace'),
            'dry': context.t('setup.dryPlace'),
            'supplies': context.t('setup.suppliesPlace'),
          }.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DropdownButtonFormField<String>(
                key: ValueKey('${e.key}-${places[e.key]}'),
                initialValue: places[e.key],
                isExpanded: true,
                decoration: InputDecoration(labelText: context.t(e.value)),
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text(context.t('setup.connectLater')),
                  ),
                  for (final p in widget.ops.rows('zones'))
                    DropdownMenuItem<String>(
                      value: p['id'],
                      child: Text(
                        '${displayedPlace(context, widget.ops, p)['name']} ${placeAddress(displayedPlace(context, widget.ops, p))}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) => setState(() {
                  places[e.key] = v;
                  changed = true;
                }),
              ),
            ),
          TextButton.icon(
            onPressed: busy
                ? null
                : () async {
                    await editPlace(context, widget.ops);
                    if (mounted &&
                        actor == widget.ops.actorId &&
                        workspace == widget.ops.data?['workspaceId']) {
                      setState(() {
                        if (original ==
                            jsonEncode(
                              widget.ops.data?['store']?['manualSetup'],
                            )) {
                          revision = widget.ops.data?['revision'] ?? revision;
                        } else {
                          error = context.t('ui.audit1250');
                        }
                      });
                    }
                  },
            icon: const Icon(Icons.add_location_alt_outlined),
            label: Text(context.t('ui.audit233')),
          ),
          if (widget.ops.data?['dishwashingExampleVersion'] != 1) ...[
            TextButton.icon(
              key: const ValueKey('add-dishwashing-example'),
              onPressed:
                  busy ||
                      changed ||
                      widget.ops.readOnly ||
                      !widget.ops.canEditTasks
                  ? null
                  : () async {
                      if (actor != widget.ops.actorId ||
                          workspace != widget.ops.workspaceId) {
                        setState(
                          () => error = context.t('welcome.scopeChanged'),
                        );
                        return;
                      }
                      setState(() => busy = true);
                      final ok = await widget.ops.act(
                        'add_dishwashing_example',
                        {'revision': widget.ops.data?['revision']},
                      );
                      if (!mounted) return;
                      setState(() {
                        busy = false;
                        revision = widget.ops.data?['revision'] ?? revision;
                        error = ok ? null : widget.ops.error;
                      });
                    },
              icon: const Icon(Icons.menu_book_outlined),
              label: Text(context.t('setup.dishwashingExample')),
            ),
            Information(
              context.t(changed ? 'setup.saveFirst' : 'setup.exampleHelp'),
            ),
          ] else
            Information(context.t('setup.exampleAdded')),
          Information(context.t('ui.audit234')),
          if (changed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Information(
                context.t(
                  'ui.audit744',
                  args: {
                    'p0': conditions['selfbar'] == false
                        ? context.t('ui.audit1133')
                        : conditions['selfbar'] == true
                        ? context.t('ui.audit1134')
                        : context.t('ui.audit1135'),
                  },
                ),
              ),
            ),
          if (error != null)
            Text(error!, style: const TextStyle(color: AppColors.accent)),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

class ManualCustomizationBadge extends StatelessWidget {
  const ManualCustomizationBadge({super.key, required this.value});
  final dynamic value;
  @override
  Widget build(BuildContext context) {
    if (value is! Map) return const SizedBox.shrink();
    final added = value['kind'] == 'created';
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                added ? Icons.note_add_outlined : Icons.edit_outlined,
                size: 14,
                color: AppColors.accent,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  added ? context.t('ui.audit745') : context.t('ui.audit746'),
                  style: const TextStyle(fontSize: 13, color: AppColors.accent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SharedPlaceLinks extends StatelessWidget {
  const SharedPlaceLinks({super.key, required this.ops, required this.row});
  final OperationsController ops;
  final Json row;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (row['zone'] != null)
        TextButton.icon(
          onPressed: () => openPlace(context, ops, row['zone']),
          icon: const Icon(Icons.place_outlined),
          label: Text(context.t('place.workLocation')),
        ),
      for (final p in (row['sharedPlaces'] as List? ?? []).cast<Json>())
        TextButton.icon(
          onPressed: () => openPlace(context, ops, p['zoneId']),
          icon: const Icon(Icons.link),
          label: Text(
            '${p['label']} · ${displayedPlace(context, ops, ops.rows('zones').where((z) => z['id'] == p['zoneId']).firstOrNull ?? p)['name']}',
          ),
        ),
    ],
  );
}
