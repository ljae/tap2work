import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tap2work/data/account_repository.dart';
import 'package:tap2work/data/native_auth_service.dart';
import 'package:tap2work/state/account_controller.dart';
import 'package:tap2work/ui/account_screen.dart';
import 'package:tap2work/ui/privacy_screen.dart';

class FakeAccount implements AccountRepository {
  FakeAccount({this.owner = true});
  final bool owner;
  int deletes = 0;
  Object? error;
  Completer<String?>? pending;
  @override
  Future<DeletionPreview> previewDeletion() async => DeletionPreview(
    token: 'fresh',
    destroysWorkspace: owner,
    hasApple: false,
    workspaceName: '테스트 매장',
    memberCount: 3,
  );
  @override
  Future<String?> deleteAccount(DeletionPreview preview) async {
    deletes++;
    if (error != null) throw error!;
    return pending?.future;
  }
}

void main() {
  test(
    'delete requires preview, blocks duplicate requests and preserves cancellation',
    () async {
      final repo = FakeAccount()..error = const SignInCancelled();
      final state = AccountController(repo);
      addTearDown(state.dispose);
      await state.deleteConfirmed();
      expect(repo.deletes, 0);
      await state.loadPreview();
      await state.deleteConfirmed();
      expect(state.deleted, false);
      expect(state.error, isNull);
      expect(state.preview, isNotNull);
      repo.error = const AuthException('범위 변경');
      await state.deleteConfirmed();
      expect(state.error, '범위 변경');
      expect(state.preview, isNull);
      repo.error = null;
      repo.pending = Completer<String?>();
      await state.loadPreview();
      final deletion = state.deleteConfirmed();
      await state.deleteConfirmed();
      expect(repo.deletes, 3);
      repo.pending!.complete('기기 백업 삭제 필요');
      await deletion;
      expect(state.deleted, true);
      expect(state.completionWarning, '기기 백업 삭제 필요');
    },
  );
  for (final width in [320.0, 390.0]) {
    testWidgets(
      'owner sees store consequences and explicit confirmation at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = FakeAccount();
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 1200),
                textScaler: TextScaler.linear(1.6),
              ),
              child: Scaffold(
                body: AccountScreen(repository: repo, onSignOut: () async {}),
              ),
            ),
          ),
        );
        await tester.tap(find.text('삭제 범위 확인'));
        await tester.pumpAndSettle();
        expect(find.textContaining('테스트 매장'), findsOneWidget);
        expect(find.textContaining('3명'), findsOneWidget);
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
        await tester.ensureVisible(find.byType(CheckboxListTile));
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pumpAndSettle();
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNotNull,
        );
        expect(repo.deletes, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('privacy is bundled and identifies the operator before login', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PrivacyScreen())),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.textContaining('OpenEdu'), findsWidgets);
    expect(find.textContaining('tap2work.dev@gmail.com'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
