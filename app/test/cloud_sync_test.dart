import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/cloud_workspace.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets(
    'unchanged sync keeps data, polls at 30s and stops in background',
    (tester) async {
      var reads = 0;
      final ops = OperationsController(
        readOnly: false,
        accessToken: () async => 'session',
        client: MockClient((request) async {
          reads++;
          if (request.url.queryParameters['revision'] == '8') {
            expect(request.url.queryParameters['workspace'], 'workspace-a');
            expect(request.url.queryParameters['role'], 'owner');
            return http.Response('{"unchanged":true}', 200);
          }
          return http.Response(
            jsonEncode({
              'revision': 8,
              'syncWindow': 100,
              'workspaceId': 'workspace-a',
              'actor': {'id': 'owner', 'role': 'owner'},
              'tasks': [
                {'id': 'keep'},
              ],
            }),
            200,
          );
        }),
      );

      await ops.start();
      expect(reads, 1);
      await tester.pump(const Duration(seconds: 6));
      expect(reads, 1);
      await tester.pump(const Duration(seconds: 25));
      await tester.pumpAndSettle();
      expect(reads, 2);
      expect(ops.rows('tasks').single['id'], 'keep');
      ops.didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pump(const Duration(minutes: 2));
      expect(reads, 2);
      ops.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(reads, 3);
      expect(ops.data!['revision'], 8);
      ops.dispose();
    },
  );
  testWidgets(
    'SSO buttons route to the chosen provider and disclose unavailable providers',
    (tester) async {
      final selected = <OAuthProvider>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialSignInButtons(
              loadProviders: () async => {
                OAuthProvider.google,
                OAuthProvider.apple,
              },
              onSignIn: (p) async {
                selected.add(p);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Google로 계속하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apple로 계속하기'));
      await tester.pumpAndSettle();
      expect(selected, [OAuthProvider.google, OAuthProvider.apple]);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialSignInButtons(
              key: const ValueKey('off'),
              loadProviders: () async => {},
              onSignIn: (p) async {
                selected.add(p);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('소셜 로그인 연결 준비 중'), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Google로 계속하기'),
            )
            .onPressed,
        isNull,
      );
    },
  );
}
