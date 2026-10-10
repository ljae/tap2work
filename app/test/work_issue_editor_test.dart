import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tap2work/domain/manual_media_repository.dart';
import 'package:tap2work/domain/optimized_photo.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/photo_registration.dart';
import 'package:tap2work/ui/work_issue_editor.dart';
import 'manual_media_editor_test.dart'
    show MediaEditorRepository, mediaReference, mediaOtherWorkspace;

class IssueRepo extends MediaEditorRepository
    implements TaskIssueMediaRepository {
  int issueUploads = 0;
  @override
  Future<Json> uploadWorkIssuePhoto({
    required String actorId,
    required String workspaceId,
    required String taskId,
    required Uint8List bytes,
  }) async {
    issueUploads++;
    return {'reference': mediaReference, 'receipt': 'signed-fixture'};
  }
}

void main() {
  testWidgets(
    'routine report retains photo receipt and draft on failed save; retries without reupload',
    (t) async {
      final repo = IssueRepo()..failSave = true;
      repo.snapshot['mediaUploadEnabled'] = true;
      final ops = OperationsController(
        repository: repo,
        accessToken: () async => 'session',
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkIssueEditor(
              ops: ops,
              task: const {'id': 'routine', 'canComplete': true},
            ),
          ),
        ),
      );
      await t.enterText(find.byType(TextField), 'Drain blocked');
      final field = t.widget<PhotoRegistrationField>(
        find.byType(PhotoRegistrationField),
      );
      field.onChanged(
        OptimizedPhoto(
          bytes: Uint8List.fromList(
            img.encodeJpg(img.Image(width: 2, height: 2)),
          ),
          width: 1,
          height: 1,
        ),
      );
      await t.pump();
      await t.tap(find.text('기록'));
      await t.pumpAndSettle();
      expect(repo.issueUploads, 1);
      expect(find.text('Drain blocked'), findsOneWidget);
      expect(repo.writes.single['severity'], 'blocked');
      expect(repo.writes.single['photoReceipt'], 'signed-fixture');
      await t.tap(find.text('기록'));
      await t.pumpAndSettle();
      expect(repo.issueUploads, 1);
      expect(repo.writes.length, 2);
      expect(repo.writes.first['requestId'], repo.writes.last['requestId']);
      ops.data = {...ops.data!, 'workspaceId': mediaOtherWorkspace};
      ops.notifyListeners();
      await t.pump();
      expect(
        t
            .widget<FilledButton>(find.widgetWithText(FilledButton, '기록'))
            .onPressed,
        isNull,
      );
    },
  );
}
