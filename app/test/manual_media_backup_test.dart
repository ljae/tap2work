import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tap2work/data/checklist_backup_repository.dart';
import 'package:tap2work/ui/checklist_backup_screen.dart';
import 'manual_media_editor_test.dart'
    show
        MediaEditorRepository,
        mediaWorkspace,
        mediaOtherWorkspace,
        mediaReference;
import 'package:tap2work/state/operations_controller.dart';

class MediaBackupRepository extends ChecklistBackupRepository {
  String? picked;
  @override
  Future<String?> read(String scope) async => null;
  @override
  Future<String?> pick() async => picked;
}

void main() {
  for (final crossWorkspace in [false, true]) {
    testWidgets(
      'backup ${crossWorkspace ? 'other' : 'same'} workspace counts only inaccessible private photos',
      (t) async {
        final operationsRepository = MediaEditorRepository();
        final ops = OperationsController(
          repository: operationsRepository,
          accessToken: () async => 'fixture-session',
        );
        addTearDown(ops.dispose);
        await ops.refresh();
        final otherRef =
            'tap2work-media:$mediaOtherWorkspace/44444444-4444-4444-4444-444444444444.jpg';
        final repository = MediaBackupRepository()
          ..picked = jsonEncode({
            'format': 'tap2work-checklists',
            'schemaVersion': 1,
            'folders': [
              {'id': 'general', 'name': '기본'},
            ],
            'templates': [
              {
                'id': 'restored',
                'title': '건조 확인',
                'steps': [
                  {'id': 'same', 'title': '같은 매장', 'imageUrl': mediaReference},
                  {
                    'id': 'another',
                    'title': '둘째 사진',
                    'imageUrl': crossWorkspace ? otherRef : mediaReference,
                  },
                  {
                    'id': 'public',
                    'title': '공개 안내',
                    'imageUrl': 'https://example.com/photo.jpg',
                  },
                  {'id': 'empty', 'title': '사진 없음', 'imageUrl': ''},
                ],
              },
            ],
            'workspaceId': mediaWorkspace,
          });
        await t.pumpWidget(
          MaterialApp(
            home: ChecklistBackupScreen(ops: ops, repository: repository),
          ),
        );
        await t.pumpAndSettle();
        await t.tap(find.text('백업 파일 선택'));
        await t.pumpAndSettle();
        if (crossWorkspace) {
          await t.scrollUntilVisible(
            find.textContaining('다른 매장에 등록된 사진 1개'),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          expect(find.textContaining('다른 매장에 등록된 사진 1개'), findsOneWidget);
        } else {
          expect(find.textContaining('다른 매장에 등록된 사진'), findsNothing);
        }
        await t.scrollUntilVisible(
          find.text('개인화 사본으로 추가 복원'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await t.tap(find.text('개인화 사본으로 추가 복원'));
        await t.pumpAndSettle();
        final saved = operationsRepository.writes.single;
        expect(saved['action'], 'restore_checklist_backup');
        expect(saved['revision'], 23);
        expect(
          saved['backup']['templates'][0]['steps'][0]['imageUrl'],
          mediaReference,
        );
        expect(
          find.textContaining(
            crossWorkspace ? '사진 1개를 다시 등록' : '개인화 사본으로 추가했어요',
          ),
          findsOneWidget,
        );
        expect(t.takeException(), isNull);
      },
    );
  }
}
