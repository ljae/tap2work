import 'dart:convert';
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
            decoration: InputDecoration(labelText: e.value),
            items: const [
              DropdownMenuItem(value: 'unknown', child: Text('나중에 설정')),
              DropdownMenuItem(value: 'yes', child: Text('사용해요')),
              DropdownMenuItem(value: 'no', child: Text('없어요')),
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
  late final Json conditions = {
        ...(widget.ops.data?['store']?['manualSetup']?['conditions'] as Json? ??
            {}),
      },
      places = {
        ...(widget.ops.data?['store']?['manualSetup']?['places'] as Json? ??
            {}),
      };
  late int revision = widget.ops.data?['revision'] ?? 0;
  late final actor = widget.ops.actorId,
      workspace = widget.ops.data?['workspaceId'];
  late final original = jsonEncode(widget.ops.data?['store']?['manualSetup']);
  Future<void> leave() async {
    if (busy) return;
    final discard =
        !changed ||
        await showAppDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('변경을 버릴까요?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('계속 수정'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('변경 버리기'),
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
      setState(() => error = '매장이 바뀌었어요. 다시 열어 주세요.');
      return;
    }
    setState(() => busy = true);
    final ok = await widget.ops.act('save_manual_setup', {
      'revision': revision,
      'setup': {'conditions': conditions, 'places': places},
    });
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
      title: '매뉴얼 구성',
      onClose: leave,
      footer: AppSheetFooter(
        children: [
          FilledButton(
            onPressed: busy ? null : save,
            child: Text(busy ? '저장 중…' : '변경 적용'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('외식업 공통 업무에 매장 특성을 반영해요.', style: AppText.body),
          const SizedBox(height: 24),
          ManualConditions(
            values: conditions,
            onChanged: (k, v) => setState(() {
              conditions[k] = v;
              changed = true;
            }),
          ),
          const Text('여러 업무에서 함께 쓰는 장소', style: AppText.section),
          const SizedBox(height: 16),
          for (final e in {
            'waste': '폐기물 배출 장소',
            'supplies': '비품 보관 장소',
          }.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DropdownButtonFormField<String>(
                key: ValueKey('${e.key}-${places[e.key]}'),
                initialValue: places[e.key],
                isExpanded: true,
                decoration: InputDecoration(labelText: e.value),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('나중에 연결'),
                  ),
                  for (final p in widget.ops.rows('zones'))
                    DropdownMenuItem<String>(
                      value: p['id'],
                      child: Text(
                        '${p['name']} ${placeAddress(p)}',
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
                          error = '매뉴얼 구성이 다른 곳에서 변경됐어요. 입력을 확인하고 다시 열어 주세요.';
                        }
                      });
                    }
                  },
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('장소 등록'),
          ),
          const Information(
            '영업시간·브레이크·파트는 기존 매장 설정을 사용해요. 연결한 장소의 이름과 설명은 한 곳에서 수정해요.',
          ),
          if (changed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Information(
                '${conditions['selfbar'] == false
                    ? '홀 오픈·마감에서 셀프바 절차가 제외돼요.'
                    : conditions['selfbar'] == true
                    ? '홀 오픈·마감에 셀프바 절차를 포함해요.'
                    : '미설정 조건은 기존 절차를 유지해요.'}\n매장 수정과 입력값을 보존해요. 시작한 업무는 그대로 유지해요.',
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
                  added ? '직접 추가' : '우리 매장 수정',
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
          label: const Text('작업 장소 보기'),
        ),
      for (final p in (row['sharedPlaces'] as List? ?? []).cast<Json>())
        TextButton.icon(
          onPressed: () => openPlace(context, ops, p['zoneId']),
          icon: const Icon(Icons.link),
          label: Text('${p['label']} · ${p['name']}'),
        ),
    ],
  );
}
