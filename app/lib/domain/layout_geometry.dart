typedef LayoutCell = ({int x, int y});

Set<LayoutCell> occupiedLayoutCells(Map<String, dynamic> zone) {
  final shape = zone['shape'] ?? 'rect';
  final rotation = zone['rotation'] ?? 0;
  final width = zone['width'] as int, height = zone['height'] as int;
  final baseWidth = rotation == 90 || rotation == 270 ? height : width;
  final baseHeight = rotation == 90 || rotation == 270 ? width : height;
  final notchWidth = zone['notchWidth'] as int? ?? 0;
  final notchDepth = zone['notchDepth'] as int? ?? 0;
  final result = <LayoutCell>{};
  for (var y = 0; y < baseHeight; y++) {
    for (var x = 0; x < baseWidth; x++) {
      final removed = shape == 'l'
          ? x >= baseWidth - notchWidth && y < notchDepth
          : shape == 'u' &&
                x >= (baseWidth - notchWidth) ~/ 2 &&
                x < (baseWidth - notchWidth) ~/ 2 + notchWidth &&
                y < notchDepth;
      if (removed) continue;
      var tx = x, ty = y;
      if (rotation == 90) {
        tx = baseHeight - 1 - y;
        ty = x;
      }
      if (rotation == 180) {
        tx = baseWidth - 1 - x;
        ty = baseHeight - 1 - y;
      }
      if (rotation == 270) {
        tx = y;
        ty = baseWidth - 1 - x;
      }
      result.add((x: (zone['x'] as int) + tx, y: (zone['y'] as int) + ty));
    }
  }
  return result;
}
