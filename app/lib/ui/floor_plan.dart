import '../l10n/app_localizations.dart';
import 'place_guide.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import '../state/operations_controller.dart';
import '../domain/grid_routes.dart';
import '../domain/layout_geometry.dart';
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
  String mapFloor = '';
  @override
  Widget build(BuildContext context) {
    final ops = widget.operations;
    final layout = ops.data?['layout'] as Json?;
    if (layout == null) {
      return Information(context.t('ui.audit121'));
    }
    final mapFloors = ops
        .rows('zones')
        .map((z) => z['floor'] as String? ?? '')
        .toSet()
        .toList();
    if (mapFloors.isNotEmpty && !mapFloors.contains(mapFloor)) {
      mapFloor = mapFloors.first;
    }
    final zones = ops
        .rows('zones')
        .where((z) => z['mapped'] != false && (z['floor'] ?? '') == mapFloor)
        .toList();
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
        PlaceGuide(ops: ops),
        const SizedBox(height: 24),
        ExpansionTile(
          title: Text(context.t('ui.audit122')),
          children: [
            Wrap(
              spacing: 8,
              children: [
                for (final f in mapFloors)
                  ChoiceChip(
                    label: Text(f.isEmpty ? context.t('ui.audit620') : f),
                    selected: mapFloor == f,
                    onSelected: (_) => setState(() {
                      mapFloor = f;
                      selected = null;
                      route = '전체 배치';
                    }),
                  ),
              ],
            ),
            _Summary(zones: zones),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (ops.isLeader)
                  PressBounce(
                    child: FilledButton.icon(
                      onPressed: ops.busy
                          ? null
                          : () => showAppSheet(
                              context,
                              builder: (_) => _LayoutEditor(
                                operations: ops,
                                floor: mapFloor,
                              ),
                            ),
                      icon: const Icon(Icons.edit_location_alt_outlined),
                      label: Text(context.t('ui.audit123')),
                    ),
                  ),
                Text(
                  context.t('ui.audit124'),
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AppChoiceGroup<String>(
              values: ['전체 배치', ...availableRoutes.map((r) => r.key)],
              selected: route,
              labelOf: (name) => name,
              onSelected: (name) => setState(() => route = name),
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
            Text(
              context.t('ui.audit125'),
              style: TextStyle(fontSize: 13, color: AppColors.muted),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (selection['kind'] == 'table')
                      Text(
                        context.t(
                          'ui.audit621',
                          args: {'p0': selection['seats']},
                        ),
                      ),
                    if (selection['description'] != '')
                      Text(
                        selection['description'],
                        style: const TextStyle(height: 1.7),
                      ),
                    if (ops
                        .rows('items')
                        .any((i) => i['zone'] == selection['id']))
                      Text(
                        context.t(
                          'ui.audit622',
                          args: {
                            'p0': ops
                                .rows('items')
                                .where((i) => i['zone'] == selection['id'])
                                .map((i) => i['name'])
                                .join(', '),
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (path.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Information(
                  context.t(
                    'ui.audit623',
                    args: {
                      'p0': route,
                      'p1': path.indexed
                          .map(
                            (p) =>
                                '${p.$1 + 1}. ${zones.firstWhere((z) => z['id'] == p.$2)['name']}',
                          )
                          .join(' → '),
                    },
                  ),
                ),
              ),
            const SizedBox(height: 20),
            SectionHeading(
              context.t('ui.audit1449'),
              context.t('ui.audit1450'),
            ),
            Surface(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: [
                  for (final (index, item) in ops.rows('items').indexed) ...[
                    if (index > 0) const Divider(height: 1),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 5),
                      leading: const Icon(Icons.inventory_2_outlined),
                      title: Text(
                        '${item['name']} · ${item['quantity']}${item['unit']}',
                      ),
                      subtitle: Text(
                        context.t(
                          'ui.audit624',
                          args: {
                            'p0': _stamp(item['lastCheckedAt']),
                            'p1': _stamp(item['lastOrderedAt']),
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
        Information(context.t('ui.audit126')),
      ],
    );
  }
}

String _stamp(dynamic value) {
  final date = DateTime.tryParse(
    '$value',
  )?.toUtc().add(const Duration(hours: 9));
  if (date == null) return '기록 없음';
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
    final values = [
      ('tables', '테이블', '${tables.length}개'),
      ('seats', '좌석 정원', '$seats석'),
      (
        'equipment',
        '주요 기기',
        '${zones.where((z) => z['kind'] == 'equipment').length}대',
      ),
    ];
    return Row(
      children: [
        for (final (index, value) in values.indexed) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              key: Key('layout-summary-${value.$1}'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value.$2,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value.$3,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
    this.onTransform,
    this.route = const [],
  });
  final Json layout;
  final List<Json> zones;
  final String? selected;
  final ValueChanged<String> onSelect;
  final void Function(int, int)? onPlace;
  final void Function(String, int, int, int, int)? onTransform;
  final List<String> route;
  @override
  State<_MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<_MapCanvas> {
  final transform = TransformationController();
  final canvasKey = GlobalKey();
  Json? dragOrigin;
  Offset? dragStart;
  Offset scene(Offset global) =>
      (canvasKey.currentContext!.findRenderObject() as RenderBox).globalToLocal(
        global,
      );
  void startTransform(Json zone, DragStartDetails details) {
    dragOrigin = Map<String, dynamic>.from(zone);
    dragStart = scene(details.globalPosition);
    widget.onSelect(zone['id']);
  }

  void updateTransform(
    DragUpdateDetails details,
    double unit, {
    bool resize = false,
  }) {
    final origin = dragOrigin;
    if (origin == null || dragStart == null) return;
    final delta = scene(details.globalPosition) - dragStart!;
    final dx = (delta.dx / unit).round();
    final dy = (delta.dy / unit).round();
    widget.onTransform?.call(
      origin['id'],
      origin['x'] + (resize ? 0 : dx),
      origin['y'] + (resize ? 0 : dy),
      origin['width'] + (resize ? dx : 0),
      origin['height'] + (resize ? dy : 0),
    );
  }

  void cancelTransform() {
    final origin = dragOrigin;
    if (origin != null) {
      widget.onTransform?.call(
        origin['id'],
        origin['x'],
        origin['y'],
        origin['width'],
        origin['height'],
      );
    }
    dragOrigin = null;
    dragStart = null;
  }

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
            PressBounce(
              child: TextButton(
                onPressed: () => transform.value = Matrix4.identity(),
                child: Text(context.t('ui.audit127')),
              ),
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
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  gestureSettings: const DeviceGestureSettings(touchSlop: 6),
                ),
                child: InteractiveViewer(
                  transformationController: transform,
                  panEnabled: widget.onTransform == null,
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
                      key: canvasKey,
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
                              child: GestureDetector(
                                key: ValueKey('move-zone-${z['id']}'),
                                dragStartBehavior: DragStartBehavior.down,
                                onPanStart: widget.onTransform == null
                                    ? null
                                    : (d) => startTransform(z, d),
                                onPanUpdate: widget.onTransform == null
                                    ? null
                                    : (d) => updateTransform(d, unit),
                                onPanEnd: (_) {
                                  dragOrigin = null;
                                  dragStart = null;
                                },
                                onPanCancel: cancelTransform,
                                child: ClipPath(
                                  clipper: _FootprintClipper(z),
                                  child: Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: Material(
                                      color: z['kind'] == 'area'
                                          ? AppColors.elevated
                                          : z['kind'] == 'table'
                                          ? const Color(0xFF293748)
                                          : AppColors.elevated,
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
                                          width: z['id'] == widget.selected
                                              ? 2.5
                                              : 1,
                                        ),
                                      ),
                                      child: InkWell(
                                        onTap: () => widget.onSelect(z['id']),
                                        child: Tooltip(
                                          message:
                                              '${z['name']}${z['kind'] == 'table' ? context.t('ui.audit2100', args: {'p0': z['seats']}) : ''}',
                                          child: Center(
                                            child: Padding(
                                              padding: const EdgeInsets.all(3),
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      _icon(z['kind']),
                                                      size: 18,
                                                      color: AppColors.green,
                                                    ),
                                                    Text(
                                                      '${widget.route.contains(z['id']) ? '${widget.route.indexOf(z['id']) + 1}. ' : ''}${z['name']}',
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                    if (z['kind'] == 'table')
                                                      Text(
                                                        context.t(
                                                          'ui.audit621',
                                                          args: {
                                                            'p0': z['seats'],
                                                          },
                                                        ),
                                                        style: const TextStyle(
                                                          fontSize: 13,
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
                              ),
                            ),
                          if (widget.onTransform != null)
                            for (final z in sorted.where(
                              (z) => z['id'] == widget.selected,
                            ))
                              Positioned(
                                left: ((z['x'] + z['width']) * unit - 24).clamp(
                                  0.0,
                                  unit * cols - 30,
                                ),
                                top: ((z['y'] + z['height']) * unit - 24).clamp(
                                  0.0,
                                  unit * rows - 30,
                                ),
                                width: 30,
                                height: 30,
                                child: Semantics(
                                  label: context.t(
                                    'ui.audit625',
                                    args: {'p0': z['name']},
                                  ),
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors
                                        .resizeUpLeftDownRight,
                                    child: GestureDetector(
                                      key: ValueKey('resize-zone-${z['id']}'),
                                      dragStartBehavior: DragStartBehavior.down,
                                      onPanStart: (d) => startTransform(z, d),
                                      onPanUpdate: (d) => updateTransform(
                                        d,
                                        unit,
                                        resize: true,
                                      ),
                                      onPanEnd: (_) {
                                        dragOrigin = null;
                                        dragStart = null;
                                      },
                                      onPanCancel: cancelTransform,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.accent,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          CupertinoIcons
                                              .arrow_up_left_arrow_down_right,
                                          color: Colors.white,
                                          size: 17,
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
              ),
            );
          },
        ),
      ],
    ),
  );
}

class _FootprintClipper extends CustomClipper<Path> {
  const _FootprintClipper(this.zone);
  final Json zone;
  @override
  Path getClip(Size size) {
    final unitX = size.width / (zone['width'] as int);
    final unitY = size.height / (zone['height'] as int);
    final path = Path();
    for (final cell in occupiedLayoutCells(zone)) {
      path.addRect(
        Rect.fromLTWH(
          (cell.x - (zone['x'] as int)) * unitX,
          (cell.y - (zone['y'] as int)) * unitY,
          unitX,
          unitY,
        ),
      );
    }
    return path;
  }

  @override
  bool shouldReclip(covariant _FootprintClipper oldClipper) =>
      oldClipper.zone != zone;
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
      GridCell center(Json z) {
        final cells = occupiedLayoutCells(z).toList();
        final x = (z['x'] as int) + (z['width'] as int) ~/ 2;
        final y = (z['y'] as int) + (z['height'] as int) ~/ 2;
        cells.sort(
          (a, b) => ((a.x - x).abs() + (a.y - y).abs()).compareTo(
            (b.x - x).abs() + (b.y - y).abs(),
          ),
        );
        return (x: cells.first.x, y: cells.first.y);
      }

      final blocked = <GridCell>{};
      for (final z in zones) {
        if (z['id'] == from['id'] ||
            z['id'] == to['id'] ||
            z['kind'] == 'area' ||
            z['kind'] == 'entrance') {
          continue;
        }
        blocked.addAll(occupiedLayoutCells(z).map((c) => (x: c.x, y: c.y)));
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
  const _LayoutEditor({required this.operations, required this.floor});
  final String floor;
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
    zones = ops
        .rows('zones')
        .where(
          (z) => z['mapped'] != false && (z['floor'] ?? '') == widget.floor,
        )
        .map(_copy)
        .toList();
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
        await showAppDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(context.t('ui.audit128')),
                content: Text(context.t('ui.audit129')),
                actions: [
                  PressBounce(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(context.t('ui.audit21')),
                    ),
                  ),
                  PressBounce(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(context.t('ui.audit130')),
                    ),
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

  void transformZone(String id, int x, int y, int width, int height) {
    final zone = zones.firstWhere((z) => z['id'] == id);
    final previous = Map<String, dynamic>.from(zone);
    final shaped = (zone['shape'] ?? 'rect') != 'rect';
    final minBaseWidth = zone['shape'] == 'u'
        ? 3
        : shaped
        ? 2
        : 1;
    final minBaseHeight = shaped ? 2 : 1;
    final rotated = [90, 270].contains(zone['rotation']);
    final w = width.clamp(
      rotated ? minBaseHeight : minBaseWidth,
      layout['columns'] as int,
    );
    final h = height.clamp(
      rotated ? minBaseWidth : minBaseHeight,
      layout['rows'] as int,
    );
    setState(() {
      zone.addAll({
        'x': x.clamp(0, layout['columns'] - w),
        'y': y.clamp(0, layout['rows'] - h),
        'width': w,
        'height': h,
      });
      if (shaped) {
        final baseW = rotated ? h : w;
        final baseH = rotated ? w : h;
        zone['notchWidth'] = (zone['notchWidth'] as int).clamp(
          1,
          baseW - (zone['shape'] == 'u' ? 2 : 1),
        );
        zone['notchDepth'] = (zone['notchDepth'] as int).clamp(1, baseH - 1);
      }
      final issue = geometryError;
      if (issue != null) {
        zone
          ..clear()
          ..addAll(previous);
        error = issue;
      } else {
        dirty = true;
        error = null;
      }
    });
  }

  String? get geometryError {
    final tableNames = <String>{};
    for (final z in zones) {
      final rotation = z['rotation'] ?? 0;
      final shape = z['shape'] ?? 'rect';
      final baseWidth = rotation == 90 || rotation == 270
          ? z['height']
          : z['width'];
      final baseHeight = rotation == 90 || rotation == 270
          ? z['width']
          : z['height'];
      if (shape != 'rect' &&
          ((z['notchWidth'] ?? 0) < 1 ||
              (z['notchDepth'] ?? 0) < 1 ||
              z['notchWidth'] > baseWidth - (shape == 'u' ? 2 : 1) ||
              z['notchDepth'] >= baseHeight)) {
        return context.t('ui.audit2101', args: {'p0': z['name']});
      }
      if (z['x'] + z['width'] > layout['columns'] ||
          z['y'] + z['height'] > layout['rows']) {
        return context.t('ui.audit2102', args: {'p0': z['name']});
      }
      if (z['kind'] == 'table' && !tableNames.add(z['name'])) {
        return '테이블 이름은 서로 다르게 정해 주세요.';
      }
      for (final other in zones) {
        if (z == other || z['kind'] == 'area' || other['kind'] == 'area') {
          continue;
        }
        if (occupiedLayoutCells(
          z,
        ).intersection(occupiedLayoutCells(other)).isNotEmpty) {
          return context.t(
            'ui.audit2103',
            args: {'p0': z['name'], 'p1': other['name']},
          );
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
      setState(() => error = context.t('ui.audit1244'));
      return;
    }
    final ok = await ops.act('save_layout', {
      'revision': revision,
      'layout': layout,
      'floorScope': widget.floor,
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
      setState(() => error = ops.error ?? context.t('ui.audit760'));
    }
  }

  Future<void> reload() async {
    final yes = await showAppDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t('ui.audit131')),
        content: Text(context.t('ui.audit132')),
        actions: [
          PressBounce(
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.t('ui.audit21')),
            ),
          ),
          PressBounce(
            child: FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.t('ui.audit133')),
            ),
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
    final result = await showAppFormSheet<Json>(
      context: context,
      builder: (_) =>
          _ItemDialog(item: item, layout: layout, initialSpot: spot),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (item == null) {
        result['floor'] = widget.floor;
        zones.add(result);
      } else {
        // The item editor owns geometry/name, not floor/photo/place metadata.
        // This also keeps the floor on a new, not-yet-persisted draft table.
        zones[zones.indexOf(item)] = {...item, ...result};
      }
      selected = result['id'];
      dirty = true;
      error = null;
    });
  }

  Future<void> dimensions() async {
    final result = await showAppFormSheet<Json>(
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
          title: Text(context.t('ui.audit134')),
          leading: IconButton(
            tooltip: context.t('ui.audit626'),
            onPressed: leave,
            icon: const Icon(Icons.close),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: PressBounce(
              child: FilledButton.icon(
                key: const Key('save-layout'),
                onPressed: ops.readOnly || ops.busy || !dirty ? null : save,
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  ops.readOnly
                      ? context.t('ui.audit627')
                      : ops.busy
                      ? context.t('ui.audit532')
                      : context.t('ui.audit628'),
                ),
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
                          ? context.t('ui.audit629')
                          : context.t('ui.audit630'),
                    ),
                    if (ops.data?['revision'] != revision) ...[
                      const SizedBox(height: 12),
                      Information(context.t('ui.audit135')),
                      PressBounce(
                        child: TextButton(
                          onPressed: reload,
                          child: Text(context.t('ui.audit136')),
                        ),
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
                    if (ops
                        .rows('zones')
                        .any(
                          (z) =>
                              z['mapped'] == false &&
                              (z['floor'] ?? '') == widget.floor &&
                              !zones.any((d) => d['id'] == z['id']),
                        ))
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: context.t('ui.audit137'),
                        ),
                        items: [
                          for (final z
                              in ops
                                  .rows('zones')
                                  .where(
                                    (z) =>
                                        z['mapped'] == false &&
                                        (z['floor'] ?? '') == widget.floor &&
                                        !zones.any((d) => d['id'] == z['id']),
                                  ))
                            DropdownMenuItem(
                              value: z['id'] as String,
                              child: Text(z['name']),
                            ),
                        ],
                        onChanged: (id) async {
                          final place = ops
                              .rows('zones')
                              .firstWhere((z) => z['id'] == id);
                          final result = await showAppFormSheet<Json>(
                            context: context,
                            builder: (_) => _ItemDialog(
                              item: place,
                              layout: layout,
                              initialSpot: (0, 0),
                            ),
                          );
                          if (result != null && mounted) {
                            setState(() {
                              zones.add({...place, ...result, 'mapped': true});
                              dirty = true;
                              selected = id;
                            });
                          }
                        },
                      ),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        PressBounce(
                          child: OutlinedButton.icon(
                            onPressed: zones.length >= 80
                                ? null
                                : () => editItem(),
                            icon: const Icon(Icons.add),
                            label: Text(context.t('ui.audit138')),
                          ),
                        ),
                        PressBounce(
                          child: TextButton.icon(
                            onPressed: dimensions,
                            icon: const Icon(Icons.grid_on),
                            label: Text(context.t('ui.audit139')),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        context.t('ui.audit631'),
                        style: TextStyle(fontSize: 13, color: AppColors.muted),
                      ),
                    ),
                    _MapCanvas(
                      layout: layout,
                      zones: zones,
                      selected: selected,
                      onSelect: (id) => setState(() => selected = id),
                      onPlace: move,
                      onTransform: transformZone,
                    ),
                    const SizedBox(height: 12),
                    if (selection != null)
                      Surface(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.t(
                                'ui.audit632',
                                args: {'p0': selection!['name']},
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              context.t('ui.audit140'),
                              style: TextStyle(fontSize: 13),
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
                                PressBounce(
                                  child: TextButton.icon(
                                    onPressed: () => editItem(selection),
                                    icon: const Icon(Icons.tune),
                                    label: Text(context.t('ui.audit141')),
                                  ),
                                ),
                                PressBounce(
                                  child: TextButton.icon(
                                    onPressed: () => setState(() {
                                      zones.remove(selection);
                                      selected = null;
                                      dirty = true;
                                    }),
                                    icon: const Icon(Icons.delete_outline),
                                    label: Text(context.t('ui.audit142')),
                                  ),
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
                            chipAnimationStyle: AppMotion.chipStyle(context),
                            label: Text(z['name']),
                            selected: selected == z['id'],
                            onSelected: (_) =>
                                setState(() => selected = z['id']),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Information(context.t('ui.audit143')),
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
  late String shape;
  late int rotation;
  late TextEditingController name, description, x, y, width, height, seats;
  late TextEditingController notchWidth, notchDepth;
  @override
  void initState() {
    super.initState();
    final item = widget.item;
    kind = item?['kind'] ?? 'table';
    shape = item?['shape'] ?? 'rect';
    rotation = item?['rotation'] ?? 0;
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
    notchWidth = TextEditingController(
      text: '${item?['notchWidth'] == 0 ? 1 : item?['notchWidth'] ?? 1}',
    );
    notchDepth = TextEditingController(
      text: '${item?['notchDepth'] == 0 ? 1 : item?['notchDepth'] ?? 1}',
    );
  }

  @override
  void dispose() {
    for (final c in [
      name,
      description,
      x,
      y,
      width,
      height,
      seats,
      notchWidth,
      notchDepth,
    ]) {
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
            return n == null || n < 1 || n > max
                ? context.t('ui.audit2104', args: {'p0': max})
                : null;
          },
        ),
      );
  @override
  Widget build(BuildContext context) => AppSheetPanel(
    title: Text(
      widget.item == null ? context.t('ui.audit138') : context.t('ui.audit633'),
    ),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 20,
            children: [
              AppPicker<String>(
                label: context.t('ui.audit181'),
                value: kind,
                items: _kinds.entries
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(context.t(e.value)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => kind = v!),
              ),
              AppPicker<String>(
                label: context.t('ui.audit634'),
                value: shape,
                items: [
                  DropdownMenuItem(
                    value: 'rect',
                    child: Text(context.t('ui.audit635')),
                  ),
                  DropdownMenuItem(
                    value: 'l',
                    child: Text(context.t('ui.audit636')),
                  ),
                  DropdownMenuItem(
                    value: 'u',
                    child: Text(context.t('ui.audit637')),
                  ),
                ],
                onChanged: (v) => setState(() => shape = v!),
              ),
              if (shape != 'rect') ...[
                AppPicker<int>(
                  label: context.t('ui.audit638'),
                  value: rotation,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('0°')),
                    DropdownMenuItem(value: 90, child: Text('90°')),
                    DropdownMenuItem(value: 180, child: Text('180°')),
                    DropdownMenuItem(value: 270, child: Text('270°')),
                  ],
                  onChanged: (v) => setState(() => rotation = v!),
                ),
                Wrap(
                  spacing: 12,
                  children: [
                    number('홈 너비 (칸)', notchWidth, widget.layout['columns']),
                    number('홈 깊이 (칸)', notchDepth, widget.layout['rows']),
                  ],
                ),
              ],
              if (kind == 'equipment')
                Wrap(
                  spacing: 4,
                  children: [
                    for (final preset in ['냉장고', '가스레인지', '오븐', '식기세척기', '포스기'])
                      ActionChip(
                        chipAnimationStyle: AppMotion.chipStyle(context),
                        label: Text(preset),
                        onPressed: () => name.text = preset,
                      ),
                  ],
                ),
              TextFormField(
                controller: name,
                maxLength: 30,
                decoration: InputDecoration(labelText: context.t('ui.audit50')),
                validator: (v) => v == null || v.trim().isEmpty
                    ? context.t('ui.audit1464')
                    : null,
              ),
              TextFormField(
                controller: description,
                maxLength: 500,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: context.t('ui.audit144'),
                ),
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
      PressBounce(
        child: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.t('ui.audit33')),
        ),
      ),
      PressBounce(
        child: FilledButton(
          onPressed: () {
            if (!form.currentState!.validate()) return;
            final baseWidth = rotation == 90 || rotation == 270
                ? int.parse(height.text)
                : int.parse(width.text);
            final baseHeight = rotation == 90 || rotation == 270
                ? int.parse(width.text)
                : int.parse(height.text);
            if (shape != 'rect' &&
                (int.parse(notchWidth.text) >
                        baseWidth - (shape == 'u' ? 2 : 1) ||
                    int.parse(notchDepth.text) >= baseHeight)) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(context.t('ui.audit639'))));
              return;
            }
            Navigator.pop(context, <String, dynamic>{
              ...?widget.item,
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
              'shape': shape,
              'rotation': shape == 'rect' ? 0 : rotation,
              'notchWidth': shape == 'rect' ? 0 : int.parse(notchWidth.text),
              'notchDepth': shape == 'rect' ? 0 : int.parse(notchDepth.text),
              'seats': kind == 'table' ? int.parse(seats.text) : 0,
            });
          },
          child: Text(context.t('ui.audit145')),
        ),
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
  Widget build(BuildContext context) => AppSheetPanel(
    title: Text(context.t('ui.audit139')),
    content: SizedBox(
      width: 360,
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 20,
            children: [
              TextFormField(
                controller: name,
                maxLength: 40,
                decoration: InputDecoration(
                  labelText: context.t('ui.audit146'),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? context.t('ui.audit1464')
                    : null,
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
              Text(context.t('ui.audit147'), style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    ),
    actions: [
      PressBounce(
        child: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.t('ui.audit33')),
        ),
      ),
      PressBounce(
        child: FilledButton(
          onPressed: () {
            if (form.currentState!.validate()) {
              Navigator.pop(context, <String, dynamic>{
                'name': name.text.trim(),
                'columns': int.parse(columns.text),
                'rows': int.parse(rows.text),
              });
            }
          },
          child: Text(context.t('ui.audit148')),
        ),
      ),
    ],
  );
}
