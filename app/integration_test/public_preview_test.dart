import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tap2work/data/http_operations_repository.dart';
import 'package:tap2work/state/app_locale_controller.dart';
import 'package:tap2work/state/work_controller.dart';
import 'package:tap2work/ui/cloud_workspace.dart';
import 'package:tap2work/ui/components.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native login preview loads public data and all four destinations', (
    tester,
  ) async {
    expect(kIsWeb, isFalse, reason: 'Run this smoke test on iOS or Android.');
    // A separate client has no persisted personal session. This test never signs
    // in, creates a workspace, or writes to the production operations endpoint.
    final client = SupabaseClient(
      'https://example.supabase.co',
      'public-test',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    final work = WorkController(DeviceProgressStore());
    addTearDown(client.dispose);
    addTearDown(work.dispose);
    await AppLocaleController.instance.selectLanguage('ko');
    final repository = HttpOperationsRepository(
      endpoint: Uri.parse('http://localhost:3100/api/operations'),
      readOnly: true,
    );
    addTearDown(repository.close);
    final sample = await repository.read(actorId: 'owner');
    expect(sample.statusCode, 200);
    expect(sample.data['taskTemplates'], isNotEmpty);

    await tester.pumpWidget(
      CloudWorkspace(
        client: client,
        work: work,
        loadProviders: () async => {OAuthProvider.apple, OAuthProvider.google},
      ),
    );
    await tester.pumpAndSettle();
    final preview = find.text('저장 없이 샘플 둘러보기');
    await tester.ensureVisible(preview);
    await tester.tap(preview);
    // Loading includes continuous motion, so wait for the actual destination.
    for (var attempt = 0; attempt < 80; attempt++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.byType(FloatingMenu).evaluate().isNotEmpty) break;
    }
    await tester.pumpAndSettle();
    final continueWork = find.byKey(const ValueKey('shared-welcome-work'));
    if (continueWork.evaluate().isNotEmpty) {
      await tester.tap(continueWork);
      await tester.pumpAndSettle();
    }
    expect(find.byType(FloatingMenu), findsOneWidget);
    for (var index = 0; index < 4; index++) {
      await tester.tap(find.byKey(ValueKey('floating-menu-$index')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<FloatingMenu>(find.byType(FloatingMenu)).selectedIndex,
        index,
      );
      expect(tester.takeException(), isNull, reason: 'destination $index');
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
