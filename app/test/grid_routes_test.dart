import 'package:flutter_test/flutter_test.dart';
import 'package:tap2work/domain/grid_routes.dart';

void main() {
  test(
    'path walks around a blocked footprint and rejects unreachable goal',
    () {
      const start = (x: 0, y: 1);
      const goal = (x: 2, y: 1);
      final path = shortestGridPath(
        columns: 3,
        rows: 3,
        start: start,
        goal: goal,
        blocked: {(x: 1, y: 1)},
      );
      expect(path.first, start);
      expect(path.last, goal);
      expect(path.length, 5);
      expect(
        shortestGridPath(
          columns: 3,
          rows: 3,
          start: start,
          goal: goal,
          blocked: {(x: 1, y: 0), (x: 1, y: 1), (x: 1, y: 2)},
        ),
        isEmpty,
      );
    },
  );
}
