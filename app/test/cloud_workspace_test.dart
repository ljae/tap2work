import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tap2work/ui/cloud_workspace.dart';
import 'package:tap2work/state/work_controller.dart';
import 'work_controller_test.dart' show MemoryStore;

void main() {
  testWidgets(
    'personal entry shows social login and privacy without shared credentials',
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
        CloudWorkspace(
          work: WorkController(MemoryStore()),
          client: client,
          loadProviders: () async => {
            OAuthProvider.apple,
            OAuthProvider.google,
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Google로 계속하기'), findsOneWidget);
      expect(find.text('Apple로 계속하기'), findsOneWidget);
      expect(find.text('개인정보처리방침'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.textContaining('공용 계정'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
