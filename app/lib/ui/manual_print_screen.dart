import '../l10n/app_localizations.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../state/operations_controller.dart';
import '../domain/manual_print.dart';
import '../data/manual_pdf_repository.dart';
import 'components.dart';

class ManualPrintScreen extends StatefulWidget {
  const ManualPrintScreen({
    super.key,
    required this.ops,
    this.templateId,
    this.folderId,
    this.recipes = false,
    this.repository,
  });
  final OperationsController ops;
  final String? templateId, folderId;
  final bool recipes;
  final ManualPdfRepository? repository;
  @override
  State<ManualPrintScreen> createState() => _ManualPrintScreenState();
}

class _ManualPrintScreenState extends State<ManualPrintScreen> {
  late final repository = widget.repository ?? ManualPdfRepository();
  late final String actor;
  late final Object? workspace;
  late Json snapshot;
  late List<Json> sources;
  late final Set<String> selected;

  @override
  void initState() {
    super.initState();
    actor = widget.ops.actorId;
    workspace = widget.ops.data?['workspaceId'];
    snapshot = jsonDecode(jsonEncode(widget.ops.data ?? {})) as Json;
    sources = manualPrintSources(snapshot)
        .where(
          (s) => widget.recipes
              ? (s['menuManualId'] != null)
              : (s['menuManualId'] == null),
        )
        .toList();
    selected = sources
        .where(
          (s) => widget.templateId != null
              ? s['id'] == widget.templateId
              : widget.folderId != null
              ? s['folderId'] == widget.folderId
              : true,
        )
        .map((s) => s['id'] as String)
        .toSet();
  }

  String locale = 'ko',
      groupBy = 'part',
      format = 'both',
      paper = 'a4',
      filter = '',
      query = '';
  bool bilingual = true, busy = false;
  String? error, message;
  Uint8List? bytes;
  bool get valid =>
      actor == widget.ops.actorId &&
      workspace == widget.ops.data?['workspaceId'];
  List<Json> get chosen => sources
      .where(
        (s) =>
            selected.contains(s['id']) &&
            (filter.isEmpty ||
                printGroupId(s, groupBy) ==
                    (filter == '__unassigned' ? '' : filter)),
      )
      .toList();
  List<Json> get visible => sources
      .where(
        (s) =>
            (filter.isEmpty ||
                printGroupId(s, groupBy) ==
                    (filter == '__unassigned' ? '' : filter)) &&
            (query.isEmpty ||
                '${s['title']} ${s['folderName']}'.toLowerCase().contains(
                  query.toLowerCase(),
                )),
      )
      .toList();
  void change(VoidCallback fn) => setState(() {
    fn();
    bytes = null;
    error = null;
    message = null;
  });
  Future<void> generate() async {
    if (!valid || busy || chosen.isEmpty) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await repository.generate(
        snapshot,
        chosen,
        ManualPrintOptions(
          locale: locale,
          groupBy: groupBy,
          format: format,
          paper: paper,
          bilingual: bilingual,
        ),
      );
      if (mounted && valid) setState(() => bytes = result);
    } catch (_) {
      if (mounted) {
        setState(() => error = context.t('ui.audit1265'));
      }
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> output(bool print) async {
    if (bytes == null || busy || !valid) return;
    setState(() {
      busy = true;
      error = null;
      message = null;
    });
    try {
      final name = 'tap2work-$format-$locale-R${snapshot['revision'] ?? 0}.pdf';
      final ok = print
          ? await repository.printPdf(bytes!, name)
          : await repository.save(bytes!, name);
      if (mounted && valid) {
        setState(
          () => message = ok
              ? (print ? context.t('ui.audit1556') : context.t('ui.audit1557'))
              : context.t('ui.audit1558'),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => error = context.t('ui.audit1266'));
      }
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> translate(Json source) async {
    final changed = await showAppSheet<bool>(
      context,
      builder: (_) => ManualPrintTranslationScreen(
        ops: widget.ops,
        source: source,
        locale: locale,
      ),
    );
    if (changed == true && mounted && valid) {
      change(() {
        snapshot = jsonDecode(jsonEncode(widget.ops.data)) as Json;
        sources = manualPrintSources(snapshot)
            .where(
              (s) => widget.recipes
                  ? s['menuManualId'] != null
                  : s['menuManualId'] == null,
            )
            .toList();
        selected.removeWhere((id) => !sources.any((s) => s['id'] == id));
      });
    }
  }

  String stateLabel(Json s) => switch (translationState(s, locale)) {
    'ready' => '번역 확인됨',
    'stale' => '원문 변경 · 재확인 필요',
    'missing' => '번역 없음 · 원문 출력',
    _ => '한국어 원문',
  };
  Widget picker(
    String label,
    String value,
    Map<String, String> items,
    ValueChanged<String> update,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: AppPicker<String>(
      label: label,
      value: value,
      items: [
        for (final e in items.entries)
          DropdownMenuItem(value: e.key, child: Text(e.value)),
      ],
      onChanged: busy
          ? null
          : (v) {
              if (v != null) change(() => update(v));
            },
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.ops,
    builder: (context, _) => AppEditorScaffold(
      title: context.t('ui.audit876'),
      subtitle: widget.recipes
          ? context.t('ui.audit877')
          : context.t('ui.audit878'),
      footer: AppSheetFooter(
        children: [
          if (!valid) Information(context.t('ui.audit327')),
          if (error != null) Information(context.t(error!)),
          if (message != null) Text(message!, style: AppText.caption),
          if (bytes == null)
            FilledButton.icon(
              key: const ValueKey('manual-print-generate'),
              onPressed: busy || !valid || chosen.isEmpty ? null : generate,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: Text(
                busy
                    ? context.t('ui.audit879')
                    : context.t('ui.audit880', args: {'p0': chosen.length}),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: busy || !valid ? null : () => output(false),
                  icon: const Icon(Icons.download_outlined),
                  label: Text(context.t('ui.audit328')),
                ),
                OutlinedButton.icon(
                  onPressed: busy || !valid ? null : () => output(true),
                  icon: const Icon(Icons.print_outlined),
                  label: Text(context.t('ui.audit329')),
                ),
                TextButton(
                  onPressed: busy || !valid
                      ? null
                      : () => showAppSheet(
                          context,
                          builder: (_) => Scaffold(
                            appBar: AppBar(
                              title: Text(context.t('ui.audit330')),
                            ),
                            body: ListenableBuilder(
                              listenable: widget.ops,
                              builder: (_, _) => !valid
                                  ? Center(
                                      child: Information(
                                        context.t('ui.audit881'),
                                      ),
                                    )
                                  : PdfPreview(
                                      build: (_) async => bytes!,
                                      allowPrinting: false,
                                      allowSharing: false,
                                      canChangePageFormat: false,
                                      canChangeOrientation: false,
                                      canDebug: false,
                                    ),
                            ),
                          ),
                        ),
                  child: Text(context.t('ui.audit331')),
                ),
              ],
            ),
        ],
      ),
      body: !valid
          ? Center(child: Information(context.t('ui.audit327')))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                picker(context.t('ui.audit1163'), format, {
                  'both': context.t('ui.audit1164'),
                  'checklist': context.t('ui.audit1165'),
                  'manual': context.t('ui.audit1166'),
                }, (v) => format = v),
                picker(
                  context.t('ui.audit1167'),
                  groupBy,
                  {
                    'part': context.t('ui.audit1168'),
                    'zone': context.t('ui.audit1169'),
                    'folder': context.t('ui.audit1170'),
                  },
                  (v) {
                    groupBy = v;
                    filter = '';
                  },
                ),
                picker(
                  context.t('ui.audit1171'),
                  locale,
                  printLanguages,
                  (v) => locale = v,
                ),
                if (locale != 'ko') ...[
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.t('ui.audit332')),
                    value: bilingual,
                    onChanged: busy ? null : (v) => change(() => bilingual = v),
                  ),
                  Information(context.t('ui.audit333')),
                  const SizedBox(height: 16),
                ],
                picker(context.t('ui.audit1172'), paper, {
                  'a4': context.t('ui.audit1173'),
                  'a5': context.t('ui.audit1174'),
                }, (v) => paper = v),
                Text(context.t('ui.audit334'), style: AppText.section),
                const SizedBox(height: 12),
                picker(context.t('ui.audit1175'), filter, {
                  '': context.t('ui.audit656'),
                  for (final s in sources)
                    (printGroupId(s, groupBy).isEmpty
                        ? '__unassigned'
                        : printGroupId(s, groupBy)): printGroupName(
                      s,
                      groupBy,
                      snapshot,
                      'ko',
                    ),
                }, (v) => filter = v),
                TextField(
                  key: const ValueKey('manual-print-search'),
                  decoration: InputDecoration(
                    labelText: context.t('ui.audit335'),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => query = v),
                ),
                Wrap(
                  children: [
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => change(
                              () => selected.addAll(
                                visible.map((s) => s['id'] as String),
                              ),
                            ),
                      child: Text(context.t('ui.audit336')),
                    ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => change(
                              () => selected.removeAll(
                                visible.map((s) => s['id']),
                              ),
                            ),
                      child: Text(context.t('ui.audit337')),
                    ),
                  ],
                ),
                Text(
                  context.t(
                    'ui.audit882',
                    args: {
                      'p0': chosen.length,
                      'p1': chosen.fold<int>(
                        0,
                        (n, s) => n + printRows(s['steps']).length,
                      ),
                    },
                  ),
                  style: AppText.caption,
                ),
                if (sources.isEmpty) Information(context.t('ui.audit338')),
                for (final s in visible)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CheckboxListTile(
                        key: ValueKey('print-select-${s['id']}'),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(s['title']),
                        subtitle: Text(
                          '${printGroupName(s, groupBy, snapshot, 'ko')} · ${printRows(s['steps']).length} Task\n${stateLabel(s)}',
                        ),
                        value: selected.contains(s['id']),
                        onChanged: busy
                            ? null
                            : (v) => change(
                                () => v == true
                                    ? selected.add(s['id'])
                                    : selected.remove(s['id']),
                              ),
                      ),
                      if (locale != 'ko' && widget.ops.canEditTasks)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: busy || !valid || widget.ops.readOnly
                                ? null
                                : () => translate(s),
                            child: Text(context.t('ui.audit339')),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 16),
                Text(context.t('ui.audit340'), style: AppText.caption),
              ],
            ),
    ),
  );
}

class ManualPrintTranslationScreen extends StatefulWidget {
  const ManualPrintTranslationScreen({
    super.key,
    required this.ops,
    required this.source,
    required this.locale,
  });
  final OperationsController ops;
  final Json source;
  final String locale;
  @override
  State<ManualPrintTranslationScreen> createState() =>
      _ManualPrintTranslationScreenState();
}

class _ManualPrintTranslationScreenState
    extends State<ManualPrintTranslationScreen> {
  late final int? revision;
  late final String actor;
  late final Object? workspace;
  @override
  void initState() {
    super.initState();
    revision = widget.ops.data?['revision'];
    actor = widget.ops.actorId;
    workspace = widget.ops.data?['workspaceId'];
  }

  late final old = widget.source['translations']?[widget.locale] as Json?;
  late String title = old?['title'] ?? '';
  late final steps = printRows(widget.source['steps']).map((s) {
    final t = printRows(
      old?['steps'],
    ).where((t) => t['id'] == s['id']).firstOrNull;
    return <String, dynamic>{
      'id': s['id'],
      'title': t?['title'] ?? '',
      'manual': t?['manual'] ?? '',
      'tip': t?['tip'] ?? '',
    };
  }).toList();
  bool saving = false, dirty = false, leaving = false;
  bool get valid =>
      widget.ops.canEditTasks &&
      !widget.ops.readOnly &&
      actor == widget.ops.actorId &&
      workspace == widget.ops.data?['workspaceId'];
  String? error;
  Future<void> save() async {
    if (saving ||
        widget.ops.readOnly ||
        !widget.ops.canEditTasks ||
        actor != widget.ops.actorId ||
        workspace != widget.ops.data?['workspaceId']) {
      return;
    }
    if (title.trim().isEmpty ||
        steps.any(
          (s) =>
              s['title'].toString().trim().isEmpty ||
              (['manual', 'tip'].any(
                (k) =>
                    printRows(widget.source['steps'])
                        .firstWhere((r) => r['id'] == s['id'])[k]
                        .toString()
                        .trim()
                        .isNotEmpty &&
                    s[k].toString().trim().isEmpty,
              )),
        )) {
      setState(() => error = context.t('ui.audit1267'));
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    final ok = await widget.ops.act('save_manual_print_translation', {
      'revision': revision,
      'templateId': widget.source['id'],
      'sourceHash': widget.source['sourceHash'],
      'locale': widget.locale,
      'title': title,
      'steps': steps,
    });
    if (!mounted) return;
    if (ok) {
      setState(() {
        leaving = true;
        saving = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context, true);
      });
    } else {
      setState(() {
        saving = false;
        error = widget.ops.error ?? context.t('ui.audit1268');
      });
    }
  }

  Future<void> close() async {
    if (saving) return;
    if (dirty) {
      final discard = await showAppDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(context.t('ui.audit341')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(context.t('ui.audit342')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(context.t('ui.audit289')),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    setState(() => leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Widget field(
    String label,
    String initial,
    ValueChanged<String> change, {
    int lines = 1,
    int max = 100,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: TextFormField(
      initialValue: initial,
      maxLength: max,
      minLines: lines,
      maxLines: lines == 1 ? 2 : 8,
      enabled: !saving,
      style: TextStyle(
        fontFamily: widget.locale == 'zh-Hans'
            ? 'NotoSansSC'
            : widget.locale == 'ja'
            ? 'NotoSansJP'
            : 'Pretendard',
        fontFamilyFallback: const ['Pretendard', 'NotoSansSC', 'NotoSansJP'],
      ),
      decoration: InputDecoration(labelText: label, alignLabelWithHint: true),
      onChanged: (v) => setState(() {
        change(v);
        dirty = true;
      }),
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.ops,
    builder: (_, _) => !valid
        ? Scaffold(
            appBar: AppBar(title: Text(context.t('ui.audit343'))),
            body: Center(child: Information(context.t('ui.audit883'))),
          )
        : PopScope(
            canPop: leaving || (!dirty && !saving),
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) close();
            },
            child: AppEditorScaffold(
              title: context.t(
                'ui.audit884',
                args: {'p0': printLanguages[widget.locale]},
              ),
              onClose: close,
              footer: AppSheetFooter(
                children: [
                  if (error != null) Information(context.t(error!)),
                  FilledButton(
                    onPressed: saving ? null : save,
                    child: Text(
                      saving
                          ? context.t('ui.audit532')
                          : context.t('ui.audit885'),
                    ),
                  ),
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Information(context.t('ui.audit344')),
                  const SizedBox(height: 20),
                  Text(
                    context.t(
                      'ui.audit886',
                      args: {'p0': widget.source['title']},
                    ),
                    style: AppText.body,
                  ),
                  const SizedBox(height: 8),
                  field(context.t('ui.audit1563'), title, (v) => title = v),
                  for (final (index, source) in printRows(
                    widget.source['steps'],
                  ).indexed) ...[
                    Text(
                      '${index + 1}. ${source['title']}',
                      style: AppText.section,
                    ),
                    const SizedBox(height: 8),
                    field(
                      context.t('ui.audit1564'),
                      steps[index]['title'],
                      (v) => steps[index]['title'] = v,
                    ),
                    Text(source['manual'] ?? '', style: AppText.body),
                    const SizedBox(height: 8),
                    field(
                      context.t('ui.audit1565'),
                      steps[index]['manual'],
                      (v) => steps[index]['manual'] = v,
                      lines: 3,
                      max: 3000,
                    ),
                    if ((source['tip'] ?? '').toString().isNotEmpty) ...[
                      Text(
                        context.t('ui.audit887', args: {'p0': source['tip']}),
                        style: AppText.caption,
                      ),
                      const SizedBox(height: 8),
                      field(
                        context.t('ui.audit1566'),
                        steps[index]['tip'],
                        (v) => steps[index]['tip'] = v,
                        lines: 2,
                        max: 1200,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
  );
}
