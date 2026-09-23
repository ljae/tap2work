import 'package:tap2work/domain/tap_planning.dart';

void expectValue(bool condition, String message) {
  if (!condition) throw StateError(message);
}

void main() {
  final blocks = planTaps(
    [
      const PlannedTap(id: 'prep', durationMinutes: 7),
      const PlannedTap(id: 'order', durationMinutes: 11),
    ],
    startMinute: 1060,
    shiftEndMinute: 1080,
  );
  expectValue(blocks[0].endMinute == 1070, 'round to 5 minutes');
  expectValue(
    blocks[1].endMinute == 1085 && blocks[1].overtime,
    'keep order and flag excess time',
  );
  final concurrent = planTaps(
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
  expectValue(
    concurrent[0].startMinute == concurrent[1].startMinute &&
        concurrent[2].startMinute == 550,
    'concurrency and exclusivity',
  );
  final mixed = planTaps(
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
  expectValue(
    mixed[0].startMinute == 545 && mixed[2].startMinute == 555,
    'five-minute alignment and earlier capacity',
  );
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
