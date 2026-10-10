import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tap2work/l10n/app_localizations.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/crew_invitation_screen.dart';

void main() {
  for (final locale in appSupportedLocales) {
    testWidgets(
      'invite preview, source names and recovery at 320px large text ${locale.toLanguageTag()}',
      (t) async {
        t.view.physicalSize = const Size(320, 1000);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        var fail = false;
        final actions = <String>[];
        final ops = OperationsController(
          accessToken: () async => 'fixture',
          client: MockClient((r) async {
            Json data;
            var status = 200;
            if (r.method == 'GET') {
              data = {'needsWorkspace': true};
            } else {
              final input = jsonDecode(r.body) as Json;
              actions.add(input['action']);
              if (fail) {
                status = 409;
                data = {'error': '초대가 만료됐어요.'};
              } else {
                data = {
                  'workspaceName': 'Source Store',
                  'crewName': 'Source Crew',
                  'role': 'crew',
                  'expiresAt': '2026-10-17T12:00:00Z',
                };
              }
            }
            return http.Response(
              jsonEncode(data),
              status,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        );
        addTearDown(ops.dispose);
        await ops.refresh();
        final strings = AppStrings(locale.toLanguageTag());
        await t.pumpWidget(
          MaterialApp(
            locale: locale,
            supportedLocales: appSupportedLocales,
            localizationsDelegates: const [
              AppStrings.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: CrewInvitationScreen(ops: ops, initialCode: 'ABCD' * 6),
          ),
        );
        await t.pumpAndSettle();
        await t.scrollUntilVisible(
          find.byType(TextField),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await t.pumpAndSettle();
        final codeController = t
            .widget<TextField>(find.byType(TextField))
            .controller!;
        final inspect = find.text(strings.text('invite.inspect'));
        await t.scrollUntilVisible(
          inspect,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await t.pumpAndSettle();
        await t.tap(inspect);
        await t.pumpAndSettle();
        await t.scrollUntilVisible(
          find.text('Source Store'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await t.pumpAndSettle();
        expect(find.text('Source Store'), findsOneWidget);
        expect(
          find.text(strings.text('invite.crewName', {'name': 'Source Crew'})),
          findsOneWidget,
        );
        expect(actions, ['preview']);
        fail = true;
        await t.scrollUntilVisible(
          inspect,
          -150,
          scrollable: find.byType(Scrollable).first,
        );
        await t.pumpAndSettle();
        await t.tap(inspect);
        await t.pumpAndSettle();
        expect(codeController.text, 'ABCD' * 6);
        final failure = find.text(
          locale.languageCode == 'ko'
              ? '초대가 만료됐어요.'
              : strings.text('invite.failed'),
        );
        await t.scrollUntilVisible(
          failure,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await t.pumpAndSettle();
        expect(failure, findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );
  }
}
