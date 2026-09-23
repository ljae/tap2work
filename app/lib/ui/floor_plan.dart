import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import '../domain/tap_planning.dart';
import 'components.dart';

const _kinds = {
  'table': '테이블',
  'equipment': '주요 기기',
  'storage': '보관',
  'entrance': '출입구',
  'area': '구역',
};
const _routes = {
  '재료 준비': ['storage', 'fridge', 'prep', 'stove'],
  '설거지': ['pass', 'sink', 'storage'],
  '첫 출근': ['entrance', 'exit', 'sink', 'prep'],
};
Json _copy(Json value) => jsonDecode(jsonEncode(value)) as Json;

class FloorPlanView extends StatefulWidget {
  const FloorPlanView({super.key, required this.operations});
  final OperationsController operations;
  @override
  State<FloorPlanView> createState() => _FloorPlanViewState();
}

class _FloorPlanViewState extends State<FloorPlanView> {
  String? selected;
  String route = '전체 배치';
  @override
  Widget build(BuildContext context) {
    final ops = widget.operations;
    final layout = ops.data?['layout'] as Json?;
    if (layout == null) {
      return const Information('매장 배치를 불러오려면 최신 매장 서버에 연결해 주세요.');
    }
    final zones = ops.rows('zones');
    final availableRoutes = _routes.entries
        .where((r) => r.value.every((id) => zones.any((z) => z['id'] == id)))
        .toList();
    final path =
        availableRoutes.where((r) => r.key == route).firstOrNull?.value ??
        <String>[];
    final selection = zones.where((z) => z['id'] == selected).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeading(
          'OUR RESTAURANT',
          '우리 매장의 전체 배치',
          '홀 테이블부터 주방 기기까지, 어디에 무엇이 있는지 한눈에.',
        ),
        _Summary(zones: zones),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (ops.isLeader)
              FilledButton.icon(
                onPressed: ops.busy
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _LayoutEditor(operations: ops),
                        ),
                      ),
                icon: const Icon(Icons.edit_location_alt_outlined),
                label: const Text('배치 설정'),
              ),
            const Text(
              '테이블 · 기기 · 보관 · 출입구',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 6,
          children: [
            for (final name in ['전체 배치', ...availableRoutes.map((r) => r.key)])
              ChoiceChip(
                label: Text(name),
                selected: route == name,
                onSelected: (_) => setState(() => route = name),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _MapCanvas(
          layout: layout,
          zones: zones,
          selected: selected,
          route: path,
          onSelect: (id) => setState(() => selected = id),
        ),
        const SizedBox(height: 10),
        const Text(
          '두 손가락으로 확대 · 항목을 눌러 상세 확인 · 격자는 상대적인 배치 기준',
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        if (selection != null) ...[
          const SizedBox(height: 16),
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${selection['name']} · ${_kinds[selection['kind']]}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (selection['kind'] == 'table')
                  Text('${selection['seats']}인석'),
                if (selection['description'] != '')
                  Text(
                    selection['description'],
                    style: const TextStyle(height: 1.7),
                  ),
                if (ops.rows('items').any((i) => i['zone'] == selection['id']))
                  Text(
                    '보관 재료: ${ops.rows('items').where((i) => i['zone'] == selection['id']).map((i) => i['name']).join(', ')}',
                  ),
              ],
            ),
          ),
        ],
        if (path.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Information(
              '$route 예시 · 장애물을 피해 이동 가능한 격자 경로를 표시해요. 막힌 구간은 선이 보이지 않아요.\n${path.indexed.map((p) => '${p.$1 + 1}. ${zones.firstWhere((z) => z['id'] == p.$2)['name']}').join(' → ')}',
            ),
          ),
        const SizedBox(height: 20),
        const Text(
          '전체 테이블과 기기',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        // Full-size list targets remain easy to use even with a small overview map.
        for (final z in zones)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(_icon(z['kind'])),
            title: Text(z['name']),
            subtitle: Text(
              z['kind'] == 'table'
                  ? '${z['seats']}인석'
                  : _kinds[z['kind']] ?? '장소',
            ),
            selected: selected == z['id'],
            trailing: const Icon(Icons.location_on_outlined),
            onTap: () => setState(() => selected = z['id']),
          ),
        const Information(
          '좌석 수는 설정된 정원이며 실시간 착석 정보가 아니에요. 배치는 개략도이며, 실제 장비 사용법과 안전·비상 동선은 현장에서 확인해 주세요.',
        ),
      ],
    );
  }
}

IconData _icon(String kind) => switch (kind) {
  'table' => Icons.table_restaurant_outlined,
  'equipment' => Icons.kitchen_outlined,
  'storage' => Icons.inventory_2_outlined,
  'entrance' => Icons.door_front_door_outlined,
  _ => Icons.crop_square,
};

class _Summary extends StatelessWidget {
  const _Summary({required this.zones});
  final List<Json> zones;
  @override
  Widget build(BuildContext context) {
    final tables = zones.where((z) => z['kind'] == 'table').toList();
    final seats = tables.fold<int>(0, (sum, z) => sum + (z['seats'] as int));
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: [
        for (final text in [
          '테이블 ${tables.length}개',
          '총 $seats석',
          '주요 기기 ${zones.where((z) => z['kind'] == 'equipment').length}대',
        ])
          Chip(
            label: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            backgroundColor: AppColors.lime.withValues(alpha: .45),
          ),
      ],
    );
  }
}

class _MapCanvas extends StatefulWidget {
  const _MapCanvas({
    required this.layout,
    required this.zones,
    required this.onSelect,
    this.selected,
    this.onPlace,
    this.route = const [],
  });
  final Json layout;
  final List<Json> zones;
  final String? selected;
  final ValueChanged<String> onSelect;
  final void Function(int, int)? onPlace;
  final List<String> route;
  @override
  State<_MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<_MapCanvas> {
  final transform = TransformationController();
  @override
  void dispose() {
    transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Surface(
    padding: const EdgeInsets.all(10),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.layout['name'],
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: () => transform.value = Matrix4.identity(),
              child: const Text('전체 보기'),
            ),
          ],
        ),
        LayoutBuilder(
          builder: (context, box) {
            final cols = widget.layout['columns'] as int;
            final rows = widget.layout['rows'] as int;
            final unit = math.min(box.maxWidth / cols, 420.0 / rows);
            final sorted = [...widget.zones]
              ..sort(
                (a, b) => (a['kind'] == 'area' ? 0 : 1).compareTo(
                  b['kind'] == 'area' ? 0 : 1,
                ),
              );
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: InteractiveViewer(
                transformationController: transform,
                minScale: 1,
                maxScale: 4,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: widget.onPlace == null
                      ? null
                      : (event) => widget.onPlace!(
                          (event.localPosition.dx / unit).floor(),
                          (event.localPosition.dy / unit).floor(),
                        ),
                  child: SizedBox(
                    width: unit * cols,
                    height: unit * rows,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _GridPainter(
                              cols,
                              rows,
                              widget.zones,
                              widget.route,
                            ),
                          ),
                        ),
                        for (final z in sorted)
                          Positioned(
                            left: (z['x'] as num) * unit,
                            top: (z['y'] as num) * unit,
                            width: (z['width'] as num) * unit,
                            height: (z['height'] as num) * unit,
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Material(
                                color: z['kind'] == 'area'
                                    ? const Color(0xFFEDECE2)
                                    : z['kind'] == 'table'
                                    ? const Color(0xFFE5EDC6)
                                    : const Color(0xFFE1E8E4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    z['kind'] == 'table' ? 10 : 4,
                                  ),
                                  side: BorderSide(
                                    color:
                                        z['id'] == widget.selected ||
                                            widget.route.contains(z['id'])
                                        ? AppColors.green
                                        : AppColors.line,
                                    width: z['id'] == widget.selected ? 2.5 : 1,
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () => widget.onSelect(z['id']),
                                  child: Tooltip(
                                    message:
                                        '${z['name']}${z['kind'] == 'table' ? ' · ${z['seats']}인석' : ''}',
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(3),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _icon(z['kind']),
                                                size: 18,
                                                color: AppColors.green,
                                              ),
                                              Text(
                                                '${widget.route.contains(z['id']) ? '${widget.route.indexOf(z['id']) + 1}. ' : ''}${z['name']}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              if (z['kind'] == 'table')
                                                Text(
                                                  '${z['seats']}인석',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ),
  );
}

class _GridPainter extends CustomPainter {
  _GridPainter(this.columns, this.rows, this.zones, this.route);
  final int columns, rows;
  final List<Json> zones;
  final List<String> route;
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.line.withValues(alpha: .7)
      ..strokeWidth = .5;
    for (var x = 0; x <= columns; x++) {
      canvas.drawLine(
        Offset(x * size.width / columns, 0),
        Offset(x * size.width / columns, size.height),
        grid,
      );
    }
    for (var y = 0; y <= rows; y++) {
      canvas.drawLine(
        Offset(0, y * size.height / rows),
        Offset(size.width, y * size.height / rows),
        grid,
      );
    }
    final line = Paint()
      ..color = AppColors.green.withValues(alpha: .5)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    for (var i = 1; i < route.length; i++) {
      final from = zones.where((z) => z['id'] == route[i - 1]).firstOrNull;
      final to = zones.where((z) => z['id'] == route[i]).firstOrNull;
      if (from == null || to == null) continue;
      GridCell center(Json z) => (
        x: (z['x'] as int) + (z['width'] as int) ~/ 2,
        y: (z['y'] as int) + (z['height'] as int) ~/ 2,
      );
      final blocked = <GridCell>{};
      for (final z in zones) {
        if (z['id'] == from['id'] ||
            z['id'] == to['id'] ||
            z['kind'] == 'area' ||
            z['kind'] == 'entrance') {
          continue;
        }
        for (
          var x = z['x'] as int;
          x < (z['x'] as int) + (z['width'] as int);
          x++
        ) {
          for (
            var y = z['y'] as int;
            y < (z['y'] as int) + (z['height'] as int);
            y++
          ) {
            blocked.add((x: x, y: y));
          }
        }
      }
      final cells = shortestGridPath(
        columns: columns,
        rows: rows,
        start: center(from),
        goal: center(to),
        blocked: blocked,
      );
      if (cells.length < 2) continue;
      final path = Path()
        ..moveTo(
          (cells.first.x + .5) * size.width / columns,
          (cells.first.y + .5) * size.height / rows,
        );
      for (final cell in cells.skip(1)) {
        path.lineTo(
          (cell.x + .5) * size.width / columns,
          (cell.y + .5) * size.height / rows,
        );
      }
      canvas.drawPath(path, line);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => true;
}

class _LayoutEditor extends StatefulWidget {
  const _LayoutEditor({required this.operations});
  final OperationsController operations;
  @override
  State<_LayoutEditor> createState() => _LayoutEditorState();
}

class _LayoutEditorState extends State<_LayoutEditor> {
  late Json layout;
  late List<Json> zones;
  late int revision;
  late String actorId;
  String? selected;
  bool dirty = false;
  bool leaving = false;
  String? error;
  OperationsController get ops => widget.operations;
  Json? get selection => zones.where((z) => z['id'] == selected).firstOrNull;
  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    layout = _copy(ops.data!['layout'] as Json);
    zones = ops.rows('zones').map(_copy).toList();
    revision = ops.data!['revision'];
    actorId = ops.actorId;
    selected = null;
    dirty = false;
    error = null;
  }

  Future<void> leave() async {
    if (ops.busy) return;
    final discard =
        !dirty ||
        await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('배치 변경을 취소할까요?'),
                content: const Text('저장하지 않은 배치 변경은 사라져요.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('계속 편집'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('변경 취소'),
                  ),
                ],
              ),
            ) ==
            true;
    if (discard && mounted) {
      setState(() => leaving = true);
      Navigator.pop(context);
    }
  }

  void move(int x, int y) {
    final item = selection;
    if (item == null) return;
    setState(() {
      item['x'] = x.clamp(0, math.max(0, layout['columns'] - item['width']));
      item['y'] = y.clamp(0, math.max(0, layout['rows'] - item['height']));
      dirty = true;
      error = null;
    });
  }

  String? get geometryError {
    final tableNames = <String>{};
    for (final z in zones) {
      if (z['x'] + z['width'] > layout['columns'] ||
          z['y'] + z['height'] > layout['rows']) {
        return '${z['name']}이 매장 경계를 벗어나요. 위치나 크기를 수정해 주세요.';
      }
      if (z['kind'] == 'table' && !tableNames.add(z['name'])) {
        return '테이블 이름은 서로 다르게 정해 주세요.';
      }
      for (final other in zones) {
        if (z == other || z['kind'] == 'area' || other['kind'] == 'area') {
          continue;
        }
        if (z['x'] < other['x'] + other['width'] &&
            z['x'] + z['width'] > other['x'] &&
            z['y'] < other['y'] + other['height'] &&
            z['y'] + z['height'] > other['y']) {
          return '${z['name']}과 ${other['name']}의 위치가 겹쳐요. 빈 칸으로 옮겨 주세요.';
        }
      }
    }
    return null;
  }

  Future<void> save() async {
    if (geometryError != null) {
      setState(() => error = geometryError);
      return;
    }
    if (ops.actorId != actorId || !ops.isLeader) {
      setState(() => error = '편집을 시작한 역할로 다시 연결해 주세요.');
      return;
    }
    final ok = await ops.act('save_layout', {
      'revision': revision,
      'layout': layout,
      'zones': zones,
    });
    if (!mounted) return;
    if (ok) {
      setState(() {
        dirty = false;
        leaving = true;
      });
      Navigator.pop(context);
    } else {
      setState(() => error = ops.error ?? '저장하지 못했어요.');
    }
  }

  Future<void> reload() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('최신 배치를 불러올까요?'),
        content: const Text('현재 편집한 내용은 버리고 매장에 저장된 배치를 불러와요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('계속 편집'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('불러오기'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    await ops.refresh();
    if (!mounted) return;
    if (ops.error != null) {
      setState(() => error = ops.error);
      return;
    }
    setState(load);
  }

  Future<void> editItem([Json? item]) async {
    var spot = (0, 0);
    search:
    for (var y = 0; y < layout['rows'] - 1; y++) {
      for (var x = 0; x < layout['columns'] - 1; x++) {
        if (!zones.any(
          (z) =>
              z['kind'] != 'area' &&
              x < z['x'] + z['width'] &&
              x + 2 > z['x'] &&
              y < z['y'] + z['height'] &&
              y + 2 > z['y'],
        )) {
          spot = (x, y);
          break search;
        }
      }
    }
    final result = await showDialog<Json>(
      context: context,
      builder: (_) =>
          _ItemDialog(item: item, layout: layout, initialSpot: spot),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (item == null) {
        zones.add(result);
      } else {
        zones[zones.indexOf(item)] = result;
      }
      selected = result['id'];
      dirty = true;
      error = null;
    });
  }

  Future<void> dimensions() async {
    final result = await showDialog<Json>(
      context: context,
      builder: (_) => _DimensionsDialog(layout: layout),
    );
    if (result != null && mounted) {
      setState(() {
        layout = result;
        dirty = true;
        error = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ops,
    builder: (context, _) => PopScope(
      canPop: leaving || (!dirty && !ops.busy),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('매장 배치 설정'),
          leading: IconButton(
            tooltip: '편집 닫기',
            onPressed: leave,
            icon: const Icon(Icons.close),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              key: const Key('save-layout'),
              onPressed: ops.readOnly || ops.busy || !dirty ? null : save,
              icon: const Icon(Icons.save_outlined),
              label: Text(
                ops.readOnly
                    ? '공개 미리보기 · 저장 불가'
                    : ops.busy
                    ? '저장 중…'
                    : '배치 저장',
              ),
            ),
          ),
        ),
        body: AbsorbPointer(
          absorbing: ops.busy,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Information(
                      ops.readOnly
                          ? '배치를 자유롭게 바꿔 볼 수 있지만 공개 미리보기에서는 저장되지 않아요.'
                          : '항목을 선택한 뒤 빈 칸을 눌러 이동하세요. 배치 저장 전까지는 다른 동료에게 반영되지 않아요.',
                    ),
                    if (ops.data?['revision'] != revision) ...[
                      const SizedBox(height: 12),
                      const Information(
                        '매장 정보가 변경됐어요. 덮어쓰지 않도록 최신 배치를 불러온 뒤 다시 편집해 주세요.',
                      ),
                      TextButton(
                        onPressed: reload,
                        child: const Text('최신 배치 불러오기'),
                      ),
                    ],
                    if (error != null || geometryError != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          error ?? geometryError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    _Summary(zones: zones),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: zones.length >= 80
                              ? null
                              : () => editItem(),
                          icon: const Icon(Icons.add),
                          label: const Text('테이블·기기 추가'),
                        ),
                        TextButton.icon(
                          onPressed: dimensions,
                          icon: const Icon(Icons.grid_on),
                          label: const Text('매장 크기·이름'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _MapCanvas(
                      layout: layout,
                      zones: zones,
                      selected: selected,
                      onSelect: (id) => setState(() => selected = id),
                      onPlace: move,
                    ),
                    const SizedBox(height: 12),
                    if (selection != null)
                      Surface(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${selection!['name']} 선택됨',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Text(
                              '빈 칸을 누르거나 화살표로 한 칸씩 옮기세요.',
                              style: TextStyle(fontSize: 12),
                            ),
                            Wrap(
                              spacing: 4,
                              children: [
                                for (final direction in [
                                  (Icons.arrow_back, -1, 0, '왼쪽 이동'),
                                  (Icons.arrow_upward, 0, -1, '위로 이동'),
                                  (Icons.arrow_downward, 0, 1, '아래로 이동'),
                                  (Icons.arrow_forward, 1, 0, '오른쪽 이동'),
                                ])
                                  IconButton(
                                    tooltip: direction.$4,
                                    onPressed: () => move(
                                      selection!['x'] + direction.$2,
                                      selection!['y'] + direction.$3,
                                    ),
                                    icon: Icon(direction.$1),
                                  ),
                              ],
                            ),
                            Wrap(
                              spacing: 10,
                              children: [
                                TextButton.icon(
                                  onPressed: () => editItem(selection),
                                  icon: const Icon(Icons.tune),
                                  label: const Text('이름·크기·좌석 수정'),
                                ),
                                TextButton.icon(
                                  onPressed: () => setState(() {
                                    zones.remove(selection);
                                    selected = null;
                                    dirty = true;
                                  }),
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('배치에서 삭제'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final z in zones)
                          ChoiceChip(
                            label: Text(z['name']),
                            selected: selected == z['id'],
                            onSelected: (_) =>
                                setState(() => selected = z['id']),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Information(
                      '테이블·기기는 서로 겹치지 않게 배치해 주세요. 구역은 다른 항목의 배경으로 겹칠 수 있어요. 업무·재고에 연결된 장소는 삭제할 수 없어요. 도면 이미지 업로드와 실제 치수 측정은 아직 지원하지 않아요.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _ItemDialog extends StatefulWidget {
  const _ItemDialog({
    this.item,
    required this.layout,
    required this.initialSpot,
  });
  final Json? item;
  final Json layout;
  final (int, int) initialSpot;
  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  final form = GlobalKey<FormState>();
  late String kind;
  late TextEditingController name, description, x, y, width, height, seats;
  @override
  void initState() {
    super.initState();
    final item = widget.item;
    kind = item?['kind'] ?? 'table';
    name = TextEditingController(text: item?['name'] ?? '새 테이블');
    description = TextEditingController(text: item?['description'] ?? '');
    x = TextEditingController(
      text: '${(item?['x'] ?? widget.initialSpot.$1) + 1}',
    );
    y = TextEditingController(
      text: '${(item?['y'] ?? widget.initialSpot.$2) + 1}',
    );
    width = TextEditingController(text: '${item?['width'] ?? 2}');
    height = TextEditingController(text: '${item?['height'] ?? 2}');
    seats = TextEditingController(
      text: '${item?['seats'] == 0 ? 4 : item?['seats'] ?? 4}',
    );
  }

  @override
  void dispose() {
    for (final c in [name, description, x, y, width, height, seats]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget number(String label, TextEditingController controller, int max) =>
      SizedBox(
        width: 115,
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
          keyboardType: TextInputType.number,
          validator: (v) {
            final n = int.tryParse(v ?? '');
            return n == null || n < 1 || n > max ? '1~$max 입력' : null;
          },
        ),
      );
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.item == null ? '테이블·기기 추가' : '배치 항목 수정'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: kind,
                decoration: const InputDecoration(labelText: '종류'),
                items: _kinds.entries
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => kind = v!),
              ),
              if (kind == 'equipment')
                Wrap(
                  spacing: 4,
                  children: [
                    for (final preset in ['냉장고', '가스레인지', '오븐', '식기세척기', '포스기'])
                      ActionChip(
                        label: Text(preset),
                        onPressed: () => name.text = preset,
                      ),
                  ],
                ),
              TextFormField(
                controller: name,
                maxLength: 30,
                decoration: const InputDecoration(labelText: '이름'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? '이름을 입력해 주세요' : null,
              ),
              TextFormField(
                controller: description,
                maxLength: 500,
                maxLines: 2,
                decoration: const InputDecoration(labelText: '위치·사용 안내 (선택)'),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  number('가로 위치 (칸)', x, widget.layout['columns']),
                  number('세로 위치 (칸)', y, widget.layout['rows']),
                  number('가로 크기 (칸)', width, widget.layout['columns']),
                  number('세로 크기 (칸)', height, widget.layout['rows']),
                  if (kind == 'table') number('좌석 수', seats, 20),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      FilledButton(
        onPressed: () {
          if (!form.currentState!.validate()) return;
          Navigator.pop(context, <String, dynamic>{
            'id':
                widget.item?['id'] ??
                'layout-${DateTime.now().microsecondsSinceEpoch}',
            'kind': kind,
            'name': name.text.trim(),
            'description': description.text.trim(),
            'x': int.parse(x.text) - 1,
            'y': int.parse(y.text) - 1,
            'width': int.parse(width.text),
            'height': int.parse(height.text),
            'seats': kind == 'table' ? int.parse(seats.text) : 0,
          });
        },
        child: const Text('배치에 적용'),
      ),
    ],
  );
}

class _DimensionsDialog extends StatefulWidget {
  const _DimensionsDialog({required this.layout});
  final Json layout;
  @override
  State<_DimensionsDialog> createState() => _DimensionsDialogState();
}

class _DimensionsDialogState extends State<_DimensionsDialog> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.layout['name']);
  late final columns = TextEditingController(
    text: '${widget.layout['columns']}',
  );
  late final rows = TextEditingController(text: '${widget.layout['rows']}');
  @override
  void dispose() {
    name.dispose();
    columns.dispose();
    rows.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('매장 크기·이름'),
    content: SizedBox(
      width: 360,
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                maxLength: 40,
                decoration: const InputDecoration(labelText: '매장 배치 이름'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? '이름을 입력해 주세요' : null,
              ),
              for (final field in [('가로 칸 수', columns), ('세로 칸 수', rows)])
                TextFormField(
                  controller: field.$2,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: field.$1),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    return n == null || n < 8 || n > 30 ? '8~30 입력' : null;
                  },
                ),
              const SizedBox(height: 12),
              const Text(
                '실제 미터 단위가 아닌 배치 격자예요. 크기를 줄이면 항목이 경계를 벗어나지 않는지 확인해 주세요.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      FilledButton(
        onPressed: () {
          if (form.currentState!.validate()) {
            Navigator.pop(context, <String, dynamic>{
              'name': name.text.trim(),
              'columns': int.parse(columns.text),
              'rows': int.parse(rows.text),
            });
          }
        },
        child: const Text('크기 적용'),
      ),
    ],
  );
}
