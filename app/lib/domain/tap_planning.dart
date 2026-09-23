import 'dart:collection';

/// Planning primitives. These calculations do not record attendance or pay.
class PlannedTap {
  const PlannedTap({
    required this.id,
    required this.durationMinutes,
    this.maxConcurrent = 1,
    this.exclusive = true,
  });

  final String id;
  final int durationMinutes;
  final int maxConcurrent;
  final bool exclusive;
}

class PlannedBlock {
  const PlannedBlock(
    this.id,
    this.startMinute,
    this.endMinute, {
    required this.overtime,
    required this.exclusive,
    required this.capacity,
  });
  final String id;
  final int startMinute;
  final int endMinute;
  final bool overtime;
  final bool exclusive;
  final int capacity;
}

/// Assigns five-minute cells in request order. Shift end flags a block but
/// never truncates or defers it. A real scheduler needs accepted order times,
/// actual staffing, breaks and store-specific rules before using this output.
List<PlannedBlock> planTaps(
  List<PlannedTap> taps, {
  required int startMinute,
  required int shiftEndMinute,
}) {
  if (startMinute < 0 || shiftEndMinute < 0) {
    throw ArgumentError('Minutes must be non-negative.');
  }
  final blocks = <PlannedBlock>[];
  for (final tap in taps) {
    if (tap.durationMinutes <= 0 ||
        tap.maxConcurrent < 1 ||
        tap.maxConcurrent > 99) {
      throw ArgumentError('Invalid tap duration or concurrency.');
    }
    final cells = (tap.durationMinutes + 4) ~/ 5;
    var start = ((startMinute + 4) ~/ 5) * 5;
    while (true) {
      final end = start + cells * 5;
      final capacity = tap.exclusive ? 1 : tap.maxConcurrent;
      var fits = true;
      for (var minute = start; minute < end; minute += 5) {
        final active = blocks
            .where(
              (block) =>
                  block.startMinute <= minute && minute < block.endMinute,
            )
            .toList();
        if (active.length >= capacity ||
            active.any(
              (block) => block.exclusive || active.length >= block.capacity,
            )) {
          fits = false;
          break;
        }
      }
      if (fits) {
        blocks.add(
          PlannedBlock(
            tap.id,
            start,
            end,
            overtime: end > shiftEndMinute,
            exclusive: tap.exclusive,
            capacity: capacity,
          ),
        );
        break;
      }
      start += 5;
    }
  }
  return blocks;
}

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
