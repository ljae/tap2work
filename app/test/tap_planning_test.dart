import 'package:flutter_test/flutter_test.dart';
import 'package:tap2work/domain/tap_planning.dart';

void main() {
  test('five-minute blocks keep an order beyond shift end', () {
    final blocks = planTaps(
      [
        const PlannedTap(id: 'first', durationMinutes: 7),
        const PlannedTap(id: 'order', durationMinutes: 11),
      ],
      startMinute: 17 * 60 + 40,
      shiftEndMinute: 18 * 60,
    );
    expect(blocks[0].startMinute, 1060);
    expect(blocks[0].endMinute, 1070);
    expect(blocks[1].startMinute, 1070);
    expect(blocks[1].endMinute, 1085);
    expect(blocks[1].overtime, isTrue);
  });

  test('concurrent blocks respect capacity and exclusive blocks wait', () {
    final blocks = planTaps(
      [
        const PlannedTap(
          id: 'a',
          durationMinutes: 10,
          exclusive: false,
          maxConcurrent: 2,
        ),
        const PlannedTap(
          id: 'b',
          durationMinutes: 10,
          exclusive: false,
          maxConcurrent: 2,
        ),
        const PlannedTap(id: 'c', durationMinutes: 5),
      ],
      startMinute: 540,
      shiftEndMinute: 1080,
    );
    expect(blocks.map((b) => b.startMinute), [540, 540, 550]);
  });

  test('later higher capacity cannot override an earlier concurrent limit', () {
    final blocks = planTaps(
      [
        const PlannedTap(
          id: 'a',
          durationMinutes: 10,
          exclusive: false,
          maxConcurrent: 2,
        ),
        const PlannedTap(
          id: 'b',
          durationMinutes: 10,
          exclusive: false,
          maxConcurrent: 2,
        ),
        const PlannedTap(
          id: 'c',
          durationMinutes: 5,
          exclusive: false,
          maxConcurrent: 99,
        ),
      ],
      startMinute: 541,
      shiftEndMinute: 1080,
    );
    expect(blocks.map((b) => b.startMinute), [545, 545, 555]);
  });

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
