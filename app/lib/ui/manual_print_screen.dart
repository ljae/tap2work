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
        setState(() => error = 'PDF를 만들지 못했어요. 선택 항목을 줄이거나 다시 시도해 주세요.');
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
              ? (print ? '인쇄 대화상자를 열었어요.' : 'PDF 저장·공유 창을 열었어요.')
              : '취소됐어요. PDF는 다시 열 수 있어요.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => error = '파일을 열지 못했어요. PDF 저장으로 내려받아 인쇄해 주세요.');
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
      title: '매뉴얼 인쇄·PDF',
      subtitle: widget.recipes ? '메뉴·레시피 인쇄' : '장소·파트별 체크리스트와 매뉴얼',
      footer: AppSheetFooter(
        children: [
          if (!valid) const Information('매장 또는 계정이 변경됐어요. 닫고 다시 열어 주세요.'),
          if (error != null) Information(error!),
          if (message != null) Text(message!, style: AppText.caption),
          if (bytes == null)
            FilledButton.icon(
              key: const ValueKey('manual-print-generate'),
              onPressed: busy || !valid || chosen.isEmpty ? null : generate,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: Text(busy ? 'PDF 만드는 중…' : '선택 ${chosen.length}개 PDF 만들기'),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: busy || !valid ? null : () => output(false),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('PDF 저장'),
                ),
                OutlinedButton.icon(
                  onPressed: busy || !valid ? null : () => output(true),
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('인쇄'),
                ),
                TextButton(
                  onPressed: busy || !valid
                      ? null
                      : () => showAppSheet(
                          context,
                          builder: (_) => Scaffold(
                            appBar: AppBar(title: const Text('인쇄 미리보기')),
                            body: ListenableBuilder(
                              listenable: widget.ops,
                              builder: (_, _) => !valid
                                  ? const Center(
                                      child: Information('매장 또는 계정이 변경됐어요.'),
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
                  child: const Text('미리보기'),
                ),
              ],
            ),
        ],
      ),
      body: !valid
          ? const Center(child: Information('매장 또는 계정이 변경됐어요. 닫고 다시 열어 주세요.'))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                picker('출력 양식', format, {
                  'both': '체크리스트 + 상세 매뉴얼',
                  'checklist': '체크리스트 · 체크칸과 메모',
                  'manual': '상세 매뉴얼 · 방법과 주의사항',
                }, (v) => format = v),
                picker(
                  '묶는 기준',
                  groupBy,
                  {'part': '파트별', 'zone': '장소별', 'folder': '폴더별'},
                  (v) {
                    groupBy = v;
                    filter = '';
                  },
                ),
                picker('인쇄 언어', locale, printLanguages, (v) => locale = v),
                if (locale != 'ko') ...[
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('한국어 원문 함께 표시'),
                    value: bilingual,
                    onChanged: busy ? null : (v) => change(() => bilingual = v),
                  ),
                  const Information(
                    '번역이 없거나 원문이 바뀐 항목은 한국어 원문과 번역 필요 표시로 출력해요. 번역은 직접 등록·검토하며 자동 번역하지 않아요.',
                  ),
                  const SizedBox(height: 16),
                ],
                picker('용지', paper, {
                  'a4': 'A4 · 기본 인쇄',
                  'a5': 'A5 · 작은 안내서',
                }, (v) => paper = v),
                const Text('출력할 TAP', style: AppText.section),
                const SizedBox(height: 12),
                picker('대상 필터', filter, {
                  '': '전체',
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
                  decoration: const InputDecoration(
                    labelText: 'TAP 검색',
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
                      child: const Text('보이는 항목 선택'),
                    ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => change(
                              () => selected.removeAll(
                                visible.map((s) => s['id']),
                              ),
                            ),
                      child: const Text('보이는 항목 해제'),
                    ),
                  ],
                ),
                Text(
                  '선택 ${chosen.length}개 · Task ${chosen.fold<int>(0, (n, s) => n + printRows(s['steps']).length)}개',
                  style: AppText.caption,
                ),
                if (sources.isEmpty)
                  const Information('출력할 매뉴얼이 없어요. 매뉴얼을 먼저 추가해 주세요.'),
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
                            child: const Text('번역 등록·검토'),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 16),
                const Text(
                  '인쇄본의 체크는 앱의 업무 완료에 반영되지 않아요. PDF는 선택 시점의 저장된 내용으로 만들어요.',
                  style: AppText.caption,
                ),
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
      setState(() => error = '원문이 있는 제목·방법·주의사항의 번역을 모두 입력해 주세요.');
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
        error = widget.ops.error ?? '번역을 저장하지 못했어요.';
      });
    }
  }

  Future<void> close() async {
    if (saving) return;
    if (dirty) {
      final discard = await showAppDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('번역 수정을 버릴까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('계속 작성'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('버리기'),
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
            appBar: AppBar(title: const Text('번역')),
            body: const Center(
              child: Information('편집 권한 또는 매장이 변경됐어요. 닫고 다시 열어 주세요.'),
            ),
          )
        : PopScope(
            canPop: leaving || (!dirty && !saving),
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) close();
            },
            child: AppEditorScaffold(
              title: '${printLanguages[widget.locale]} 번역',
              onClose: close,
              footer: AppSheetFooter(
                children: [
                  if (error != null) Information(error!),
                  FilledButton(
                    onPressed: saving ? null : save,
                    child: Text(saving ? '저장 중…' : '검토한 번역 저장'),
                  ),
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Information(
                    '아래 원문과 뜻·수치·주의사항을 대조해 주세요. 저장한 번역은 매장 인쇄본에서 함께 사용하며 한국어 원문은 바꾸지 않아요.',
                  ),
                  const SizedBox(height: 20),
                  Text('원문 · ${widget.source['title']}', style: AppText.body),
                  const SizedBox(height: 8),
                  field('TAP 이름 번역', title, (v) => title = v),
                  for (final (index, source) in printRows(
                    widget.source['steps'],
                  ).indexed) ...[
                    Text(
                      '${index + 1}. ${source['title']}',
                      style: AppText.section,
                    ),
                    const SizedBox(height: 8),
                    field(
                      'Task 이름 번역',
                      steps[index]['title'],
                      (v) => steps[index]['title'] = v,
                    ),
                    Text(source['manual'] ?? '', style: AppText.body),
                    const SizedBox(height: 8),
                    field(
                      '진행 방법 번역',
                      steps[index]['manual'],
                      (v) => steps[index]['manual'] = v,
                      lines: 3,
                      max: 3000,
                    ),
                    if ((source['tip'] ?? '').toString().isNotEmpty) ...[
                      Text('주의 · ${source['tip']}', style: AppText.caption),
                      const SizedBox(height: 8),
                      field(
                        '주의사항 번역',
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
