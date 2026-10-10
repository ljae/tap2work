import 'dart:convert';
import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import '../data/checklist_backup_repository.dart';
import '../domain/manual_media_repository.dart';
import 'components.dart';

class ChecklistBackupScreen extends StatefulWidget {
  const ChecklistBackupScreen({super.key, required this.ops, this.repository});
  final OperationsController ops;
  final ChecklistBackupRepository? repository;
  @override
  State<ChecklistBackupScreen> createState() => _ChecklistBackupScreenState();
}

class _ChecklistBackupScreenState extends State<ChecklistBackupScreen> {
  late final repository = widget.repository ?? ChecklistBackupRepository();
  late final scope =
      '${widget.ops.data?['workspaceId'] ?? widget.ops.endpoint}/${widget.ops.actorId}';
  late final String actor;
  late final Object? workspace;
  String? stored, error, message;
  Json? preview;
  int? previewRevision;
  bool busy = false;
  int get photosToRegister => (preview?['templates'] as List? ?? [])
      .expand((t) => t['steps'] as List)
      .where((s) {
        final value = s['imageUrl'];
        if (value is! String) return false;
        final photoWorkspace = manualMediaWorkspace(value);
        return photoWorkspace != null && photoWorkspace != workspace;
      })
      .length;
  String operationId = 'restore-${DateTime.now().microsecondsSinceEpoch}';
  @override
  void initState() {
    super.initState();
    actor = widget.ops.actorId;
    workspace = widget.ops.data?['workspaceId'];
    load();
  }

  bool get valid =>
      widget.ops.actorId == actor &&
      widget.ops.data?['workspaceId'] == workspace &&
      widget.ops.canEditTasks &&
      !widget.ops.readOnly;
  Future<void> load() async {
    try {
      final value = await repository.read(scope);
      if (mounted) setState(() => stored = value);
    } catch (e) {
      if (mounted) setState(() => error = '기기 백업을 읽지 못했어요.');
    }
  }

  String get payload => const JsonEncoder.withIndent(
    '  ',
  ).convert(widget.ops.data?['checklistBackup']);
  Future<void> run(Future<void> Function() fn) async {
    if (busy || !valid) return;
    setState(() {
      busy = true;
      error = null;
      message = null;
    });
    try {
      await fn();
    } catch (e) {
      if (mounted) {
        setState(() => error = '처리하지 못했어요. 파일 형식·저장 공간·권한을 확인해 주세요.');
      }
    }
    if (mounted) setState(() => busy = false);
  }

  void review(String value) {
    if (!valid) return;
    final file = jsonDecode(value);
    if (file is! Json ||
        file['format'] != 'tap2work-checklists' ||
        file['schemaVersion'] != 1 ||
        file['templates'] is! List ||
        file['folders'] is! List) {
      throw const FormatException('Invalid backup');
    }
    final templates = file['templates'] as List;
    if (templates.isEmpty ||
        templates.length > 650 ||
        (file['folders'] as List).length > 30 ||
        templates.any(
          (t) =>
              t is! Json ||
              t['title'] is! String ||
              t['steps'] is! List ||
              (t['steps'] as List).any((s) => s is! Json),
        )) {
      throw const FormatException('Invalid backup content');
    }
    setState(() {
      preview = file;
      previewRevision = widget.ops.data?['revision'];
      operationId = 'restore-${DateTime.now().microsecondsSinceEpoch}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final count =
        (widget.ops.data?['checklistBackup']?['templates'] as List? ?? [])
            .length;
    return AppEditorScaffold(
      title: '개인화 매뉴얼 백업',
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Information(
            '개인화·자체 작성 TAP과 Task·매뉴얼·운영 규칙을 백업해요. 공용 연결 TAP과 업무 수행·출퇴근·급여 기록은 제외해요. 사진·영상 파일은 백업에 포함하지 않아요. 다른 매장에서는 등록 사진을 다시 올려 주세요.',
          ),
          const SizedBox(height: 16),
          Text('백업 대상 $count개 TAP', style: AppText.section),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: busy || !valid || count == 0
                ? null
                : () => run(() async {
                    final value = payload;
                    await repository.save(scope, value);
                    if (mounted) {
                      setState(() {
                        stored = value;
                        message = '이 기기에 백업했어요. 브라우저 데이터 삭제에 대비해 파일도 내보내 주세요.';
                      });
                    }
                  }),
            child: const Text('이 기기에 백업'),
          ),
          TextButton(
            onPressed: busy || !valid || count == 0
                ? null
                : () => run(() async {
                    if (await repository.export(payload) && mounted) {
                      setState(
                        () => message = '파일 내보내기를 요청했어요. 다운로드한 파일을 확인해 주세요.',
                      );
                    }
                  }),
            child: const Text('백업 파일 내보내기'),
          ),
          const SizedBox(height: 24),
          const Text('백업 복원', style: AppText.section),
          TextButton(
            onPressed: busy || !valid || stored == null
                ? null
                : () => run(() async {
                    review(stored!);
                  }),
            child: const Text('이 기기 백업 불러오기'),
          ),
          OutlinedButton(
            onPressed: busy || !valid
                ? null
                : () => run(() async {
                    final value = await repository.pick();
                    if (value != null && mounted) review(value);
                  }),
            child: const Text('백업 파일 선택'),
          ),
          if (preview != null && valid) ...[
            const SizedBox(height: 24),
            Text(
              '복원할 TAP ${(preview!['templates'] as List).length}개',
              style: AppText.section,
            ),
            for (final t in (preview!['templates'] as List).take(30))
              Text(
                '${t['title']} · ${(t['steps'] as List? ?? []).length}개 Task',
                style: AppText.caption,
              ),
            const SizedBox(height: 12),
            if (photosToRegister > 0)
              Information(
                '다른 매장에 등록된 사진 $photosToRegister개는 가져오지 않아요. 내용은 복원하고 사진은 이 매장에서 다시 등록해 주세요.',
              ),
            const Information(
              '현재 목록은 유지하고 개인화 사본으로 추가해요. 파트·시간대·크루·장소는 다시 연결하고 사용을 켜 주세요. 기존 업무 기록은 바뀌지 않아요.',
            ),
            FilledButton(
              onPressed: busy || !valid
                  ? null
                  : () => run(() async {
                      final removedPhotos = photosToRegister;
                      final ok = await widget.ops
                          .act('restore_checklist_backup', {
                            'revision': previewRevision,
                            'operationId': operationId,
                            'backup': preview,
                          });
                      if (mounted) {
                        setState(() {
                          if (ok) {
                            preview = null;
                            message = removedPhotos == 0
                                ? '개인화 사본으로 추가했어요. TAP 설정을 확인해 주세요.'
                                : '내용을 복원했어요. 사진 $removedPhotos개를 다시 등록하고 TAP 설정을 확인해 주세요.';
                          } else {
                            error = widget.ops.error;
                          }
                        });
                      }
                    }),
              child: const Text('개인화 사본으로 추가 복원'),
            ),
          ],
          if (error != null) Information(error!),
          if (message != null) Information(message!),
        ],
      ),
    );
  }
}
