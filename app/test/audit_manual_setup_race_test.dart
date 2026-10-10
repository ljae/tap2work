import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/main.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/state/work_controller.dart';
import 'package:tap2work/ui/manual_setup_screen.dart';
import 'operations_test.dart' show sample, response;
import 'work_controller_test.dart' show MemoryStore;

void main() {
  testWidgets(
    'manual setup opening base survives poll: a remote condition and my place change are both saved',
    (tester) async {
      var state = sample();
      state['store'] = <String, dynamic>{};
      state['store']['manualSetup'] = {
        'conditions': {'selfbar': false, 'tableBurner': false},
        'places': {'waste': 'waste-old', 'dry': 'dry'},
      };
      state['zones'] = <Json>[
        for (final id in ['waste-old', 'waste-new', 'dry'])
          {'id': id, 'name': id, 'floor': '1층', 'area': '', 'description': ''},
      ];
      final posts = <Json>[];
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') {
            final body = jsonDecode(r.body) as Json;
            posts.add(body);
            state['store']['manualSetup'] = body['setup'];
          }
          return response(state);
        }),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      final work = WorkController(MemoryStore());
      addTearDown(work.dispose);
      await tester.pumpWidget(
        Tap2workApp(
          controller: work,
          homeOverride: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => openManualSetup(context, ops),
                child: const Text('설정 열기'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('설정 열기'));
      await tester.pumpAndSettle();
      final picker = tester.widget<DropdownButtonFormField<String>>(
        find.byKey(const ValueKey('waste-waste-old')),
      );
      picker.onChanged!('waste-new');
      await tester.pump();
      state['store']['manualSetup'] = {
        'conditions': {'selfbar': true, 'tableBurner': false},
        'places': {'waste': 'waste-old', 'dry': 'dry'},
      };
      state['revision'] = (state['revision'] as int) + 1;
      await ops.refresh(force: true);
      await tester.pumpAndSettle();
      await tester.tap(find.text('변경 적용'));
      await tester.pumpAndSettle();
      expect(posts.single['setup']['conditions']['selfbar'], true);
      expect(posts.single['setup']['places']['waste'], 'waste-new');
      expect(posts.single['revision'], state['revision']);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'an open manual setup cannot install examples into a newly selected store',
    (tester) async {
      final state = sample();
      state['workspaceId'] = 'store-a';
      state['store'] = <String, dynamic>{};
      state['zones'] = <Json>[];
      final posts = <Json>[];
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') posts.add(jsonDecode(r.body) as Json);
          return response(state);
        }),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      final work = WorkController(MemoryStore());
      addTearDown(work.dispose);
      await tester.pumpWidget(
        Tap2workApp(
          controller: work,
          homeOverride: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => openManualSetup(context, ops),
                child: const Text('설정 열기'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('설정 열기'));
      await tester.pumpAndSettle();
      state['workspaceId'] = 'store-b';
      await ops.refresh(force: true);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('add-dishwashing-example')),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byKey(const ValueKey('add-dishwashing-example')));
      await tester.pumpAndSettle();
      expect(posts, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
