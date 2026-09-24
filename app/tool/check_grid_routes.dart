import 'package:tap2work/domain/grid_routes.dart';

void expectValue(bool condition, String message) {
  if (!condition) throw StateError(message);
}

void main() {
  const start = (x: 0, y: 1);
  const goal = (x: 2, y: 1);
  final detour = shortestGridPath(
    columns: 3,
    rows: 3,
    start: start,
    goal: goal,
    blocked: {(x: 1, y: 1)},
  );
  expectValue(
    detour.length == 5 && detour.first == start && detour.last == goal,
    'orthogonal detour',
  );
  final unreachable = shortestGridPath(
    columns: 3,
    rows: 3,
    start: start,
    goal: goal,
    blocked: {(x: 1, y: 0), (x: 1, y: 1), (x: 1, y: 2)},
  );
  expectValue(unreachable.isEmpty, 'unreachable target');
  // ignore: avoid_print
  print('Tap planning: 5 checks passed');
}
