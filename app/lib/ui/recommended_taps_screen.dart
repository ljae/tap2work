import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';

class RecommendedTapsScreen extends StatefulWidget {
  const RecommendedTapsScreen({super.key, required this.ops});
  final OperationsController ops;
  @override
  State<RecommendedTapsScreen> createState() => _RecommendedTapsScreenState();
}

class _RecommendedTapsScreenState extends State<RecommendedTapsScreen> {
  late final int revision = widget.ops.data?['revision'] as int? ?? 0;
  late final List<Json> rows = widget.ops.rows('recommendedTaps').map((row) => {...row}).toList();
  final selected = <String>{};
  String? error;
  bool saving = false;

  Future<void> save() async {
    setState(() { saving = true; error = null; });
    final ok = await widget.ops.act('import_recommended_taps', {'revision': revision, 'ids': selected.toList()});
    if (!mounted) return;
    setState(() { saving = false; error = ok ? null : widget.ops.error ?? '가져오지 못했어요.'; });
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('맞춤 업무 양식')),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 680),
      child: ListView(padding: const EdgeInsets.all(20), children: [
        const PageHeading('SUGGESTED TAPS', '우리매장에 맞는 업무', '내용을 살펴보고 필요한 업무만 가져오세요.'),
        const Information('양식은 시작점이에요. 매장의 실제 순서와 완료 기준을 편집해서 사용하세요.'),
        const SizedBox(height: 12),
        if (rows.isEmpty) const Information('POS나 배달 사용 정보를 저장하면 관련 업무를 추천해요.'),
        for (final row in rows) Padding(padding: const EdgeInsets.only(bottom: 10), child: Surface(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CheckboxListTile(contentPadding: EdgeInsets.zero, title: Text('${row['title']}'),
              subtitle: Text(row['alreadyAdded'] == true ? '이미 가져온 업무' : 'TAP · ${row['steps'].length} Small TAP'),
              value: row['alreadyAdded'] == true || selected.contains(row['id']),
              onChanged: row['alreadyAdded'] == true ? null : (v) => setState(() {
                v == true ? selected.add(row['id']) : selected.remove(row['id']);
              })),
            for (final step in (row['steps'] as List)) Padding(padding: const EdgeInsets.only(left: 10, bottom: 3), child: Text('· $step',
              style: const TextStyle(color: AppColors.muted))),
          ]))),
        if (error != null) Information('$error\n선택한 업무는 그대로 남아 있어요.'),
        const SizedBox(height: 10),
        FilledButton(onPressed: widget.ops.readOnly || selected.isEmpty || saving ? null : save,
          child: Text(saving ? '가져오는 중…' : '${selected.length}개 업무 가져오기')),
      ]))));
}
