import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tap2work/main.dart';
import 'package:tap2work/state/work_controller.dart';
import 'package:tap2work/ui/cloud_workspace.dart';
import 'package:tap2work/ui/login_screen.dart';
import 'work_controller_test.dart' show MemoryStore;

void main() {
  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(1200, 900),
  ]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets(
        'login remains usable at $size with text scale $scale',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final work = WorkController(MemoryStore());
          addTearDown(work.dispose);
          var privacy = 0;
          var preview = 0;
          await tester.pumpWidget(
            Tap2workApp(
              controller: work,
              homeOverride: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: LoginScreen(
                    signInButtons: SocialSignInButtons(
                      loadProviders: () async => {
                        OAuthProvider.apple,
                        OAuthProvider.google,
                      },
                      onSignIn: (_) async {},
                    ),
                    onPrivacy: () => privacy++,
                    onPreview: () => preview++,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final google = tester.getRect(
            find.widgetWithText(OutlinedButton, 'Google로 계속하기'),
          );
          final apple = tester.getRect(
            find.widgetWithText(OutlinedButton, 'Apple로 계속하기'),
          );
          expect(google.width, apple.width);
          expect(google.height, greaterThanOrEqualTo(56));
          expect(apple.height, greaterThanOrEqualTo(56));
          expect(google.left, greaterThanOrEqualTo(0));
          expect(google.right, lessThanOrEqualTo(size.width));
          await tester.ensureVisible(find.text('저장 없이 샘플 둘러보기'));
          await tester.tap(find.text('저장 없이 샘플 둘러보기'));
          await tester.ensureVisible(find.text('개인정보처리방침'));
          await tester.tap(find.text('개인정보처리방침'));
          expect(preview, 1);
          expect(privacy, 1);
          expect(tester.takeException(), isNull);
        },
        variant: TargetPlatformVariant.only(
          size.width == 1200 ? TargetPlatform.linux : TargetPlatform.android,
        ),
      );
    }
  }

  testWidgets(
    'pending sign-in prevents duplicate requests and failure permits retry',
    (tester) async {
      final pending = Completer<void>();
      var requests = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialSignInButtons(
              loadProviders: () async => {
                OAuthProvider.apple,
                OAuthProvider.google,
              },
              onSignIn: (_) {
                requests++;
                return pending.future;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Google로 계속하기'));
      await tester.pump();
      await tester.tap(find.text('Apple로 계속하기'));
      expect(requests, 1);
      expect(find.text('계정 연결을 기다리고 있어요.'), findsOneWidget);
      pending.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.textContaining('로그인하지 못했어요.'), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Google로 계속하기'),
            )
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets('provider retry clears stale connection error', (tester) async {
    var loads = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SocialSignInButtons(
            loadProviders: () async {
              if (++loads == 1) throw StateError('offline');
              return {OAuthProvider.google, OAuthProvider.apple};
            },
            onSignIn: (_) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('로그인 연결 상태를 확인하지 못했어요.'), findsOneWidget);
    await tester.tap(find.text('연결 다시 확인'));
    await tester.pumpAndSettle();
    expect(loads, 2);
    expect(find.textContaining('로그인 연결 상태를 확인하지 못했어요.'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
