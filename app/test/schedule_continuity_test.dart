import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/state/schedule_controller.dart';
import 'calendar_test.dart' show calendarData;

void main() {
  testWidgets(
    'distant week requests persistent defaults and keeps range on saves',
    (tester) async {
      final data = calendarData();
      final reads = <Uri>[];
      final writes = <Json>[];
      final ops = OperationsController(
        client: MockClient((request) async {
          if (request.method == 'GET') {
            reads.add(request.url);
            if (request.url.queryParameters['scheduleFrom'] == '2028-10-02') {
              data['staffShifts'] = [
                {
                  'id': 'far',
                  'tapperId': 'cook',
                  'partId': 'kitchen',
                  'date': '2028-10-02',
                  'start': '09:00',
                  'end': '18:00',
                  'status': 'planned',
                },
              ];
            }
          } else {
            writes.add(jsonDecode(request.body) as Json);
          }
          return http.Response(
            jsonEncode(data),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      final model = ScheduleController(ops);
      addTearDown(model.dispose);
      model.selectDay(DateTime(2028, 10, 2));
      await tester.pumpAndSettle();
      expect(reads.last.queryParameters['scheduleFrom'], '2028-10-02');
      expect(reads.last.queryParameters['scheduleTo'], '2028-10-08');
      expect(model.slots(DateTime(2028, 10, 2)).single.crewId, 'cook');
      await ops.act('save_workplace_hours', {
        'days': data['workplace']['days'],
        'defaultAssignmentsEnabled': true,
      });
      expect(writes.single['scheduleFrom'], '2028-10-02');
      expect(writes.single['scheduleTo'], '2028-10-08');
      model.setMonth(true);
      await tester.pumpAndSettle();
      expect(reads.last.queryParameters['scheduleFrom'], '2028-10-01');
      expect(reads.last.queryParameters['scheduleTo'], '2028-10-31');
    },
  );
}
