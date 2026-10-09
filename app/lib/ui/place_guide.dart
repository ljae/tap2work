import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';

Widget placePhoto(String value) {
  Widget fallback(BuildContext context, Object error, StackTrace? stack) =>
      const Padding(
        padding: EdgeInsets.all(16),
        child: Text('사진을 불러오지 못했어요. 위치 설명을 확인해 주세요.'),
      );
  if (value.isEmpty) return const SizedBox.shrink();
  try {
    final image = value.startsWith('data:')
        ? Image.memory(
            base64Decode(value.split(',').last),
            fit: BoxFit.contain,
            errorBuilder: fallback,
          )
        : Image.network(value, fit: BoxFit.contain, errorBuilder: fallback);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 300),
        child: image,
      ),
    );
  } catch (_) {
    return const Text('사진을 확인해 주세요.');
  }
}

String placeAddress(Json p) => [
  p['floor'],
  p['area'],
].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
Future<void> openPlace(
  BuildContext context,
  OperationsController ops,
  String? id,
) async {
  final p = ops.rows('zones').where((p) => p['id'] == id).firstOrNull;
  if (p == null) return;
  await showAppSheet<void>(
    context,
    builder: (_) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p['name'], style: AppText.title),
            Text(placeAddress(p), style: AppText.caption),
            const SizedBox(height: 16),
            placePhoto(p['photo'] ?? ''),
            const SizedBox(height: 16),
            Text(p['description'] ?? ''),
            for (final i in ops.rows('items').where((i) => i['zone'] == id))
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(i['name']),
              ),
            if (ops.isLeader)
              TextButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await editPlace(context, ops, p);
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('장소 안내 수정'),
              ),
          ],
        ),
      ),
    ),
  );
}

Future<void> editPlace(
  BuildContext context,
  OperationsController ops, [
  Json? place,
]) => showAppFormSheet<void>(
  context: context,
  builder: (_) => PlaceEditor(ops: ops, place: place),
);

class PlaceGuide extends StatefulWidget {
  const PlaceGuide({super.key, required this.ops});
  final OperationsController ops;
  @override
  State<PlaceGuide> createState() => _PlaceGuideState();
}

class _PlaceGuideState extends State<PlaceGuide> {
  String query = '', floor = '전체';
  @override
  Widget build(BuildContext context) {
    final places = widget.ops.rows('zones');
    final floors = [
      '전체',
      ...places
          .map((p) => p['floor'] as String? ?? '')
          .where((s) => s.isNotEmpty)
          .toSet(),
    ];
    if (!floors.contains(floor)) floor = '전체';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('공간·장비', style: AppText.title),
        const SizedBox(height: 8),
        const Text('사진과 위치 설명으로 필요한 장소를 찾아요.', style: AppText.caption),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            labelText: '장소·물품 찾기',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => query = v.trim()),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final f in floors)
              ChoiceChip(
                label: Text(f),
                selected: floor == f,
                onSelected: (_) => setState(() => floor = f),
              ),
          ],
        ),
        if (widget.ops.isLeader)
          TextButton.icon(
            onPressed: () => editPlace(context, widget.ops),
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('장소 추가'),
          ),
        if (places.isEmpty)
          const Information('이름과 위치 설명만으로 장소를 등록할 수 있어요. 층과 사진은 나중에 추가해도 돼요.'),
        for (final p in places.where(
          (p) =>
              (floor == '전체' || p['floor'] == floor) &&
              ('${p['name']} ${p['description']} ${placeAddress(p)} ${widget.ops.rows('items').where((i) => i['zone'] == p['id']).map((i) => i['name']).join(' ')}')
                  .contains(query),
        ))
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              (p['photo'] ?? '').isNotEmpty
                  ? Icons.photo_outlined
                  : Icons.place_outlined,
            ),
            title: Text(p['name']),
            subtitle: Text(
              [
                placeAddress(p),
                p['description'] ?? '',
              ].where((s) => s.isNotEmpty).join('\n'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => openPlace(context, widget.ops, p['id']),
          ),
      ],
    );
  }
}

class PlaceEditor extends StatefulWidget {
  const PlaceEditor({super.key, required this.ops, this.place});
  final OperationsController ops;
  final Json? place;
  @override
  State<PlaceEditor> createState() => _PlaceEditorState();
}

class _PlaceEditorState extends State<PlaceEditor> {
  late final name = TextEditingController(text: widget.place?['name'] ?? ''),
      floor = TextEditingController(text: widget.place?['floor'] ?? ''),
      area = TextEditingController(text: widget.place?['area'] ?? ''),
      note = TextEditingController(text: widget.place?['description'] ?? '');
  late String kind = widget.place?['kind'] ?? 'storage',
      photo = widget.place?['photo'] ?? '';
  late final revision = widget.ops.data?['revision'],
      actor = widget.ops.actorId,
      workspace = widget.ops.data?['workspaceId'];
  late final id =
      widget.place?['id'] ?? 'place-${DateTime.now().microsecondsSinceEpoch}';
  String? error;
  bool busy = false;
  int seats = 4;
  bool get dirty =>
      name.text != (widget.place?['name'] ?? '') ||
      floor.text != (widget.place?['floor'] ?? '') ||
      area.text != (widget.place?['area'] ?? '') ||
      note.text != (widget.place?['description'] ?? '') ||
      photo != (widget.place?['photo'] ?? '') ||
      kind != (widget.place?['kind'] ?? 'storage');
  Future<void> leave() async {
    if (busy) return;
    final discard =
        !dirty ||
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

  @override
  void dispose() {
    name.dispose();
    floor.dispose();
    area.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> pick() async {
    final f = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (!mounted || f == null) return;
    final file = f.files.single;
    if (file.bytes == null || file.size > 350000) {
      setState(() => error = '350KB 이내 JPG·PNG·WebP 사진을 선택해 주세요.');
      return;
    }
    final ext = file.extension?.toLowerCase();
    setState(() {
      photo =
          'data:image/${ext == 'jpg' ? 'jpeg' : ext};base64,${base64Encode(file.bytes!)}';
      error = null;
    });
  }

  Future<void> save() async {
    if (busy) return;
    if (widget.ops.actorId != actor ||
        widget.ops.data?['workspaceId'] != workspace) {
      setState(() => error = '매장이 바뀌었어요. 다시 열어 주세요.');
      return;
    }
    setState(() => busy = true);
    final ok = await widget.ops.act('save_place', {
      'revision': revision,
      'place': {
        'id': id,
        'name': name.text,
        'floor': floor.text,
        'area': area.text,
        'description': note.text,
        'kind': kind,
        'photo': photo,
        'seats': widget.place?['seats'] ?? seats,
      },
    });
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() {
        busy = false;
        error = widget.ops.error;
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
      title: widget.place == null ? '장소 추가' : '장소 안내',
      onClose: leave,
      footer: AppSheetFooter(
        children: [
          FilledButton(
            onPressed: busy ? null : save,
            child: Text(busy ? '저장 중…' : '장소 저장'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: name,
            maxLength: 30,
            decoration: const InputDecoration(labelText: '장소 이름'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: kind,
            decoration: const InputDecoration(labelText: '종류'),
            items: const [
              DropdownMenuItem(value: 'storage', child: Text('보관')),
              DropdownMenuItem(value: 'equipment', child: Text('장비')),
              DropdownMenuItem(value: 'area', child: Text('구역')),
              DropdownMenuItem(value: 'entrance', child: Text('출입구')),
              DropdownMenuItem(value: 'table', child: Text('테이블')),
            ],
            onChanged: (v) => setState(() => kind = v!),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: floor,
            maxLength: 30,
            decoration: const InputDecoration(
              labelText: '층·건물 (선택)',
              hintText: '1층, 2층, 별관, 외부',
            ),
          ),
          TextField(
            controller: area,
            maxLength: 40,
            decoration: const InputDecoration(
              labelText: '구역 (선택)',
              hintText: '홀, 주방, 창고',
            ),
          ),
          TextField(
            controller: note,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: '찾는 방법',
              hintText: '계단 오른쪽 첫 번째 문, 왼쪽 선반',
            ),
          ),
          const SizedBox(height: 16),
          placePhoto(photo),
          TextButton.icon(
            onPressed: busy ? null : pick,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('사진 선택 · 350KB 이내'),
          ),
          if (photo.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => photo = ''),
              child: const Text('사진 제거'),
            ),
          if (error != null)
            Text(error!, style: const TextStyle(color: AppColors.accent)),
          const SizedBox(height: 16),

          const SizedBox(height: 16),
          const Text(
            '재고·매뉴얼에서 같은 장소를 선택해 사용해요. 도면 작성은 선택이에요.',
            style: AppText.caption,
          ),
        ],
      ),
    ),
  );
}
