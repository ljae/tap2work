import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/photo_registration.dart';
import 'package:tap2work/ui/place_guide.dart';
import 'manual_media_editor_test.dart'
    show
        MediaEditorRepository,
        mediaReference,
        mediaOtherWorkspace,
        supplyPhoto;

Future<OperationsController> mountPlacePhoto(
  WidgetTester t,
  MediaEditorRepository repository,
) async {
  t.view.physicalSize = const Size(390, 1000);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  final ops = OperationsController(
    repository: repository,
    accessToken: () async => 'fixture-session',
  );
  addTearDown(ops.dispose);
  repository.snapshot['zones'] = <Json>[
    {
      'id': 'place-a',
      'name': '건조 선반',
      'kind': 'storage',
      'floor': '',
      'area': '',
      'description': '',
      'photo': 'https://example.com/old.jpg',
      'seats': 0,
    },
  ];
  await ops.refresh();
  await t.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => PlaceEditor(
                  ops: ops,
                  place: const {
                    'id': 'place-a',
                    'name': '건조 선반',
                    'kind': 'storage',
                    'photo': 'https://example.com/old.jpg',
                  },
                ),
              ),
            ),
            child: const Text('열기'),
          ),
        ),
      ),
    ),
  );
  await t.tap(find.text('열기'));
  await t.pumpAndSettle();
  await t.scrollUntilVisible(
    find.byType(PhotoRegistrationField),
    400,
    scrollable: find.byType(Scrollable).first,
  );
  await t.pumpAndSettle();
  return ops;
}

void main() {
  testWidgets(
    'place preserves opening fields, safely rebases an unrelated revision and reuses uploaded reference on failure',
    (t) async {
      final repository = MediaEditorRepository()..failSave = true;
      final ops = await mountPlacePhoto(t, repository);
      await supplyPhoto(t);
      // Capture-time conversion itself must not allow an early place write.
      final field = t.widget<PhotoRegistrationField>(
        find.byType(PhotoRegistrationField),
      );
      field.onBusyChanged!(true);
      await t.pump();
      expect(
        t
            .widget<FilledButton>(find.widgetWithText(FilledButton, '장소 저장'))
            .onPressed,
        isNull,
      );
      field.onBusyChanged!(false);
      await t.pump();
      ops.data = {...ops.data!, 'revision': 24};
      await t.tap(find.text('장소 저장'));
      await t.pumpAndSettle();
      expect(repository.uploads, 1);
      expect(repository.writes.single['revision'], 24);
      expect(repository.writes.single['action'], 'save_place');
      expect(repository.writes.single['place']['photo'], mediaReference);
      final draft = t.widget<PhotoRegistrationField>(
        find.byType(PhotoRegistrationField),
      );
      expect(draft.pending, isNull);
      expect(draft.value, mediaReference);
      repository.failSave = false;
      await t.tap(find.text('장소 저장'));
      await t.pumpAndSettle();
      expect(repository.uploads, 1);
      expect(repository.writes.last['revision'], 24);
    },
  );

  testWidgets(
    'place workspace switch during upload cannot save into new workspace',
    (t) async {
      final repository = MediaEditorRepository()
        ..uploadGate = Completer<String>();
      final ops = await mountPlacePhoto(t, repository);
      final photo = await supplyPhoto(t);
      await t.tap(find.text('장소 저장'));
      await t.pump();
      expect(repository.uploads, 1);
      ops.data = {...ops.data!, 'workspaceId': mediaOtherWorkspace};
      ops.workspaceId = mediaOtherWorkspace;
      repository.uploadGate!.complete(mediaReference);
      await t.pumpAndSettle();
      expect(repository.writes, isEmpty);
      expect(
        t
            .widget<PhotoRegistrationField>(find.byType(PhotoRegistrationField))
            .pending,
        same(photo),
      );
      await t.scrollUntilVisible(
        find.textContaining('매장이 변경'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('매장이 변경'), findsOneWidget);
    },
  );
}
