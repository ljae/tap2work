import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tap2work/ui/cloud_workspace.dart';
import 'package:tap2work/state/work_controller.dart';
import 'work_controller_test.dart' show MemoryStore;

void main() {
  testWidgets('signed-out entry requires an account and opens themed sign-in', (
    tester,
  ) async {
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
    expect(find.text('로그인 · 회원가입'), findsOneWidget);
    expect(find.text('근무표'), findsNothing);
    await tester.tap(find.text('로그인 · 회원가입'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('다시 만나 반가워요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
