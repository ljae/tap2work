import 'dart:collection';

typedef GridCell = ({int x, int y});

/// Shortest orthogonal walk through a bounded grid. Returns an empty path when
/// either endpoint is blocked or unreachable. Equipment footprints are walls.
List<GridCell> shortestGridPath({
  required int columns,
  required int rows,
  required GridCell start,
  required GridCell goal,
  required Set<GridCell> blocked,
}) {
  bool inside(GridCell p) =>
      p.x >= 0 && p.y >= 0 && p.x < columns && p.y < rows;
  if (!inside(start) ||
      !inside(goal) ||
      blocked.contains(start) ||
      blocked.contains(goal)) {
    return [];
  }
  int heuristic(GridCell p) => (p.x - goal.x).abs() + (p.y - goal.y).abs();
  final open = <GridCell>{start};
  final cost = <GridCell, int>{start: 0};
  final previous = <GridCell, GridCell>{};
  while (open.isNotEmpty) {
    final current = open.reduce((a, b) {
      final aScore = cost[a]! + heuristic(a);
      final bScore = cost[b]! + heuristic(b);
      return aScore <= bScore ? a : b;
    });
    if (current == goal) {
      final path = Queue<GridCell>()..addFirst(current);
      var cursor = current;
      while (previous.containsKey(cursor)) {
        cursor = previous[cursor]!;
        path.addFirst(cursor);
      }
      return path.toList();
    }
    open.remove(current);
    for (final next in <GridCell>[
      (x: current.x + 1, y: current.y),
      (x: current.x - 1, y: current.y),
      (x: current.x, y: current.y + 1),
      (x: current.x, y: current.y - 1),
    ]) {
      if (!inside(next) || blocked.contains(next)) continue;
      final nextCost = cost[current]! + 1;
      if (nextCost < (cost[next] ?? 1 << 30)) {
        cost[next] = nextCost;
        previous[next] = current;
        open.add(next);
      }
    }
  }
  return [];
}
