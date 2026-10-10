import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tap2work/domain/manual_media_repository.dart';
import 'package:tap2work/domain/operations_repository.dart';
import 'package:tap2work/domain/optimized_photo.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/checklist_editor.dart';
import 'package:tap2work/ui/photo_registration.dart';

const mediaWorkspace = '11111111-1111-1111-1111-111111111111';
const mediaOtherWorkspace = '22222222-2222-2222-2222-222222222222';
const mediaReference =
    'tap2work-media:$mediaWorkspace/33333333-3333-3333-3333-333333333333.jpg';

Json mediaFixture() => {
  'revision': 23,
  'workspaceId': mediaWorkspace,
  'actor': {'id': 'owner', 'role': 'owner'},
  'taskTemplates': [
    {
      'id': 'tap-a',
      'title': '식기 정리',
      'emoji': '📋',
      'folderId': 'general',
      'steps': [
        {'id': 'before', 'title': '먼저 확인', 'manual': '이전 행동'},
        {
          'id': 'selected',
          'title': '건조 확인',
          'manual': '물기가 없으면 끝이에요.',
          'tip': '',
          'imageUrl': 'https://example.com/old.jpg',
        },
        {'id': 'after', 'title': '다음 확인', 'manual': '다음 행동'},
      ],
    },
    {
      'id': 'tap-other',
      'title': '다른 TAP',
      'steps': [
        {'id': 'other', 'title': '다른 행동', 'manual': '보존해요.'},
      ],
    },
  ],
  'checklistFolders': [
    {'id': 'general', 'name': '기본'},
  ],
  'tasks': [
    {'id': 'historic', 'completed': true},
  ],
};

class MediaEditorRepository
    implements OperationsRepository, ManualMediaRepository {
  Json snapshot = mediaFixture();
  int uploads = 0;
  final writes = <Json>[];
  Uint8List? uploaded;
  String? uploadActor, uploadWorkspace;
  bool failSave = false, failUpload = false;
  Completer<String>? uploadGate;
  @override
  Future<OperationsResult> read({
    required String actorId,
    String? demoToken,
    String? scheduleFrom,
    String? scheduleTo,
    String? workspaceId,
    bool useCache = true,
  }) async => OperationsResult(200, jsonDecode(jsonEncode(snapshot)) as Json);
  @override
  Future<OperationsResult> write({
    required String actorId,
    String? demoToken,
    required Json values,
  }) async {
    writes.add(jsonDecode(jsonEncode(values)) as Json);
    return failSave
        ? const OperationsResult(400, {'error': '다시 저장해 주세요.'})
        : OperationsResult(200, snapshot);
  }

  @override
  Future<String> uploadManualPhoto({
    required String actorId,
    required String workspaceId,
    required Uint8List bytes,
  }) async {
    uploads++;
    uploaded = bytes;
    uploadActor = actorId;
    uploadWorkspace = workspaceId;
    if (failUpload) throw const ManualMediaException('사진 전송에 실패했어요.');
    return uploadGate?.future ?? Future.value(mediaReference);
  }

  @override
  Future<Uint8List> loadManualPhoto({
    required String actorId,
    required String workspaceId,
    required String reference,
  }) async => img.encodeJpg(img.Image(width: 60, height: 40));
  @override
  void close() {}
}

Future<OperationsController> mountMediaEditor(
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
  await ops.refresh();
  await t.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ManualTaskEditor(
                  ops: ops,
                  templateId: 'tap-a',
                  sourceStepId: 'selected',
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

Future<OptimizedPhoto> supplyPhoto(WidgetTester t) async {
  final photo = OptimizedPhoto(
    bytes: img.encodeJpg(img.Image(width: 60, height: 40)),
    width: 60,
    height: 40,
  );
  t
      .widget<PhotoRegistrationField>(find.byType(PhotoRegistrationField))
      .onChanged(photo);
  await t.pumpAndSettle();
  return photo;
}

Future<void> saveMediaEditor(WidgetTester t) async {
  await t.tap(find.widgetWithText(FilledButton, '매뉴얼 저장'));
  await t.pumpAndSettle();
}

void main() {
  testWidgets(
    'optimized upload then same selected step save with opening revision and records preserved',
    (t) async {
      final repository = MediaEditorRepository();
      final ops = await mountMediaEditor(t, repository);
      final before = jsonEncode(ops.data?['tasks']);
      final photo = await supplyPhoto(t);
      await saveMediaEditor(t);
      expect(repository.uploads, 1);
      expect(repository.uploaded, orderedEquals(photo.bytes));
      expect(repository.uploadActor, 'owner');
      expect(repository.uploadWorkspace, mediaWorkspace);
      final saved = repository.writes.single;
      expect(saved['action'], 'save_manual_tap');
      expect(saved['revision'], 23);
      expect(saved['templateId'], 'tap-a');
      final steps = (saved['steps'] as List).cast<Json>();
      expect(steps.map((s) => s['id']), ['before', 'selected', 'after']);
      expect(steps[1]['imageUrl'], mediaReference);
      expect(steps.first, mediaFixture()['taskTemplates'][0]['steps'][0]);
      expect(steps.last, mediaFixture()['taskTemplates'][0]['steps'][2]);
      expect(jsonEncode(ops.data?['tasks']), before);
      expect(find.text('열기'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'failed save keeps uploaded ref and retries without another upload',
    (t) async {
      final repository = MediaEditorRepository()..failSave = true;
      await mountMediaEditor(t, repository);
      await supplyPhoto(t);
      await saveMediaEditor(t);
      expect(repository.uploads, 1);
      expect(find.text('다시 저장해 주세요.'), findsOneWidget);
      final field = t.widget<PhotoRegistrationField>(
        find.byType(PhotoRegistrationField),
      );
      expect(field.pending, isNull);
      expect(field.value, mediaReference);
      repository.failSave = false;
      await saveMediaEditor(t);
      expect(repository.uploads, 1);
      expect(repository.writes.length, 2);
      expect(repository.writes.last['steps'][1]['imageUrl'], mediaReference);
      expect(find.text('열기'), findsOneWidget);
    },
  );

  testWidgets(
    'failed upload retains optimized preview and performs no manual or completion write',
    (t) async {
      final repository = MediaEditorRepository()..failUpload = true;
      final ops = await mountMediaEditor(t, repository);
      final before = jsonEncode(ops.data);
      final photo = await supplyPhoto(t);
      await saveMediaEditor(t);
      expect(repository.writes, isEmpty);
      final field = t.widget<PhotoRegistrationField>(
        find.byType(PhotoRegistrationField),
      );
      expect(field.pending, same(photo));
      expect(field.value, 'https://example.com/old.jpg');
      expect(find.text('사진 전송에 실패했어요.'), findsOneWidget);
      expect(jsonEncode(ops.data), before);
      repository.failUpload = false;
      await saveMediaEditor(t);
      expect(repository.uploads, 2);
      expect(repository.writes.single['action'], 'save_manual_tap');
    },
  );

  testWidgets(
    'workspace changes during upload block save and retain optimized draft',
    (t) async {
      final repository = MediaEditorRepository()
        ..uploadGate = Completer<String>();
      final ops = await mountMediaEditor(t, repository);
      final photo = await supplyPhoto(t);
      await t.tap(find.widgetWithText(FilledButton, '매뉴얼 저장'));
      await t.pump();
      expect(repository.uploads, 1);
      ops.data = {...ops.data!, 'workspaceId': mediaOtherWorkspace};
      repository.uploadGate!.complete(mediaReference);
      await t.pumpAndSettle();
      expect(repository.writes, isEmpty);
      expect(
        t
            .widget<PhotoRegistrationField>(find.byType(PhotoRegistrationField))
            .pending,
        same(photo),
      );
      expect(find.textContaining('매장이 변경'), findsOneWidget);
    },
  );
}
