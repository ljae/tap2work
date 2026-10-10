import 'dart:convert';
import '../domain/edit_conflict.dart';
import 'edit_conflict_dialog.dart';
import '../l10n/app_localizations.dart';
import 'translated_content.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../data/photo_capture_service.dart';
import '../state/operations_controller.dart';
import 'components.dart';
import 'photo_registration.dart';

Widget placePhoto(String value, {OperationsController? ops}) {
  Widget fallback(BuildContext context, Object error, StackTrace? stack) =>
      Padding(
        padding: const EdgeInsets.all(16),
        child: Text(context.t('photo.loadFailed')),
      );
  if (value.isEmpty) return const SizedBox.shrink();
  if (value.startsWith('tap2work-media:')) {
    return ops == null
        ? Builder(builder: (context) => Text(context.t('photo.loginRequired')))
        : _PrivatePlacePhoto(value: value, ops: ops);
  }
  try {
    final image = value.startsWith('data:')
        ? Image.memory(
            base64Decode(value.split(',').last),
            fit: BoxFit.contain,
            errorBuilder: fallback,
          )
        : _ExternalPlacePhoto(value: value);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 300),
        child: image,
      ),
    );
  } catch (_) {
    return Builder(builder: (context) => Text(context.t('photo.loadFailed')));
  }
}

class _ExternalPlacePhoto extends StatefulWidget {
  const _ExternalPlacePhoto({required this.value});
  final String value;
  @override
  State<_ExternalPlacePhoto> createState() => _ExternalPlacePhotoState();
}

class _ExternalPlacePhotoState extends State<_ExternalPlacePhoto> {
  int attempt = 0;
  @override
  Widget build(BuildContext context) => Image.network(
    widget.value,
    key: ValueKey((widget.value, attempt)),
    fit: BoxFit.contain,
    errorBuilder: (_, _, _) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(context.t('photo.loadFailed')),
          TextButton(
            onPressed: () async {
              await NetworkImage(widget.value).evict();
              if (mounted) setState(() => attempt++);
            },
            child: Text(context.t('common.retry')),
          ),
        ],
      ),
    ),
  );
}

class _PrivatePlacePhoto extends StatefulWidget {
  const _PrivatePlacePhoto({required this.value, required this.ops});
  final String value;
  final OperationsController ops;
  @override
  State<_PrivatePlacePhoto> createState() => _PrivatePlacePhotoState();
}

class _PrivatePlacePhotoState extends State<_PrivatePlacePhoto> {
  Future<Uint8List>? bytes;
  String? actor, workspace;
  Widget failure(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Text(context.t('photo.loadFailed')),
        TextButton(
          onPressed: () => setState(load),
          child: Text(context.t('common.retry')),
        ),
      ],
    ),
  );
  void load() {
    actor = widget.ops.actorId;
    workspace = widget.ops.data?['workspaceId'] ?? widget.ops.workspaceId;
    bytes = widget.ops.loadManualPhoto(widget.value);
    // Observe errors immediately, including a request retired before a rebuild.
    // FutureBuilder still receives the failure and shows its retry action.
    bytes!.ignore();
  }

  void changed() {
    final nextWorkspace =
        widget.ops.data?['workspaceId'] ?? widget.ops.workspaceId;
    if (mounted &&
        (actor != widget.ops.actorId || workspace != nextWorkspace)) {
      setState(load);
    }
  }

  @override
  void initState() {
    super.initState();
    widget.ops.addListener(changed);
    load();
  }

  @override
  void didUpdateWidget(covariant _PrivatePlacePhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ops != widget.ops) {
      oldWidget.ops.removeListener(changed);
      widget.ops.addListener(changed);
    }
    if (oldWidget.value != widget.value || oldWidget.ops != widget.ops) load();
  }

  @override
  void dispose() {
    widget.ops.removeListener(changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
    key: ValueKey((widget.value, actor, workspace)),
    future: bytes,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return failure(context);
      }
      if (!snapshot.hasData) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Text(context.t('photo.loading')),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: Image.memory(
            snapshot.data!,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => failure(context),
          ),
        ),
      );
    },
  );
}

/// Translate presentation fields only; location references always keep source IDs.
Json displayedPlace(
  BuildContext context,
  OperationsController ops,
  Json source,
) {
  final language = AppStrings.of(context).languageTag;
  if (language == 'ko') return source;
  final cells = ops
      .data?['manualContentTranslations']?['places']?[source['id']]?[language];
  return {
    ...source,
    for (final field in ['name', 'floor', 'area', 'description'])
      if (cells?[field] is Map &&
          cells[field]['sourceText'] == source[field] &&
          cells[field]['text'] is String)
        field: cells[field]['text'],
  };
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
  final actor = ops.actorId, workspace = ops.data?['workspaceId'];
  await showAppSheet<void>(
    context,
    builder: (_) => ListenableBuilder(
      listenable: ops,
      builder: (context, _) =>
          actor != ops.actorId || workspace != ops.data?['workspaceId']
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Information(context.t('welcome.scopeChanged')),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TranslatedContent(
                      ops: ops,
                      kind: 'place',
                      entityId: id,
                      source: p,
                      builder: (context, shown) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(shown['name'], style: AppText.title),
                          Text(placeAddress(shown), style: AppText.caption),
                          const SizedBox(height: 16),
                          Text(shown['description'] ?? ''),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    placePhoto(p['photo'] ?? '', ops: ops),
                    const SizedBox(height: 16),

                    for (final i
                        in ops.rows('items').where((i) => i['zone'] == id))
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
                        label: Text(context.t('place.edit')),
                      ),
                  ],
                ),
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
                label: Text(
                  f == '전체'
                      ? context.t('common.all')
                      : displayedPlace(
                          context,
                          widget.ops,
                          places.firstWhere((p) => p['floor'] == f),
                        )['floor'],
                ),
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
            title: Text(displayedPlace(context, widget.ops, p)['name']),
            subtitle: Text(
              [
                placeAddress(displayedPlace(context, widget.ops, p)),
                displayedPlace(context, widget.ops, p)['description'] ?? '',
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
  const PlaceEditor({
    super.key,
    required this.ops,
    this.place,
    this.photoService,
  });
  final OperationsController ops;
  final Json? place;
  final PhotoCaptureService? photoService;
  @override
  State<PlaceEditor> createState() => _PlaceEditorState();
}

class _PlaceEditorState extends State<PlaceEditor> {
  late final Json openingSnapshot;
  late final name = TextEditingController(text: widget.place?['name'] ?? ''),
      floor = TextEditingController(text: widget.place?['floor'] ?? ''),
      area = TextEditingController(text: widget.place?['area'] ?? ''),
      note = TextEditingController(text: widget.place?['description'] ?? '');
  late String kind = widget.place?['kind'] ?? 'storage',
      photo = widget.place?['photo'] ?? '';
  late final Object? revision, workspace;
  late final String actor;
  late final id =
      widget.place?['id'] ?? 'place-${DateTime.now().microsecondsSinceEpoch}';
  String? error;
  bool busy = false;
  bool photoBusy = false;
  OptimizedPhoto? pendingPhoto;
  @override
  void initState() {
    super.initState();
    openingSnapshot = copyEditSnapshot(widget.ops.data!);
    revision = widget.ops.data?['revision'];
    actor = widget.ops.actorId;
    workspace = widget.ops.data?['workspaceId'] ?? widget.ops.workspaceId;
  }

  bool get scopeCurrent =>
      widget.ops.actorId == actor &&
      (widget.ops.data?['workspaceId'] ?? widget.ops.workspaceId) == workspace;
  late int seats = widget.place?['kind'] == 'table'
      ? widget.place!['seats']
      : 4;
  bool get dirty =>
      name.text != (widget.place?['name'] ?? '') ||
      floor.text != (widget.place?['floor'] ?? '') ||
      area.text != (widget.place?['area'] ?? '') ||
      note.text != (widget.place?['description'] ?? '') ||
      pendingPhoto != null ||
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

  Future<void> save() async {
    if (busy || photoBusy) return;
    if (!scopeCurrent) {
      setState(() => error = '매장이 바뀌었어요. 다시 열어 주세요.');
      return;
    }
    setState(() => busy = true);
    var savedPhoto = photo;
    try {
      if (pendingPhoto != null) {
        savedPhoto = widget.ops.cloud
            ? await widget.ops.uploadManualPhoto(pendingPhoto!.bytes)
            : pendingPhoto!.dataUrl;
      }
      if (!mounted) return;
      if (!scopeCurrent) {
        setState(() {
          busy = false;
          error = '매장이 바뀌었어요. 다시 열어 주세요.';
        });
        return;
      }
      // Keep this uploaded candidate on the draft when the following CAS save
      // fails. Retry uses the same object instead of creating another upload.
      setState(() {
        photo = savedPhoto;
        pendingPhoto = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = e.toString();
        });
      }
      return;
    }
    final ok = await widget.ops.saveDraft(
      'save_place',
      {
        'editingExisting': widget.place != null,
        'place': {
          'id': id,
          'name': name.text,
          'floor': floor.text,
          'area': area.text,
          'description': note.text,
          'kind': kind,
          'photo': savedPhoto,
          'seats': seats,
        },
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
          if (error != null)
            Semantics(
              liveRegion: true,
              child: Text(
                error!,
                style: AppText.caption.copyWith(color: AppColors.accent),
              ),
            ),
          FilledButton(
            onPressed: busy || photoBusy ? null : save,
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
          PhotoRegistrationField(
            value: photo,
            pending: pendingPhoto,
            scopeKey: (actor, workspace, id),
            isScopeCurrent: () => scopeCurrent,
            enabled: !busy,
            service: widget.photoService,
            previewBuilder: (value) => placePhoto(value, ops: widget.ops),
            onBusyChanged: (value) => setState(() => photoBusy = value),
            onChanged: (value) => setState(() {
              pendingPhoto = value;
              error = null;
            }),
            onRemove: () => setState(() {
              photo = '';
              pendingPhoto = null;
            }),
          ),
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
