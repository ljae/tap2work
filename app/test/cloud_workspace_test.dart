import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tap2work/ui/cloud_workspace.dart';
import 'package:tap2work/state/work_controller.dart';
import 'work_controller_test.dart' show MemoryStore;

void main() {
  testWidgets(
    'public entry shows fixed account and automatic credential fields',
    (tester) async {
      final client = (await tester.runAsync(
        () async => SupabaseClient(
          'https://example.supabase.co',
          'public-test',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      ))!;
      addTearDown(() => tester.runAsync(client.dispose));
      await tester.pumpWidget(
        CloudWorkspace(work: WorkController(MemoryStore()), client: client),
      );
      await tester.pumpAndSettle();
      expect(find.text('로그인'), findsOneWidget);
      expect(find.text('ljae.m10@gmail.com'), findsOneWidget);
      expect(find.text('근무표'), findsNothing);
      final fields = tester
          .widgetList<TextFormField>(find.byType(TextFormField))
          .toList();
      expect(fields.length, 2);
      expect(fields.every((field) => field.initialValue!.isNotEmpty), isTrue);
      expect(find.text('Google로 계속하기'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
