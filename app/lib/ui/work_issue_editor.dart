import 'dart:math';
import 'package:flutter/material.dart';
import '../data/photo_capture_service.dart';
import '../l10n/app_localizations.dart';
import '../state/operations_controller.dart';
import 'components.dart';
import 'photo_registration.dart';
import 'place_guide.dart';
import 'action_failure_text.dart';

/// Keep the report draft and an uploaded candidate until the operation succeeds.
class WorkIssueEditor extends StatefulWidget {
  const WorkIssueEditor({super.key, required this.ops, required this.task});
  final OperationsController ops;
  final Json task;
  @override
  State<WorkIssueEditor> createState() => _WorkIssueEditorState();
}

class _WorkIssueEditorState extends State<WorkIssueEditor> {
  final reason = TextEditingController();
  final requestId = List.generate(
    16,
    (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  bool unknownResult = false;
  late final actor = widget.ops.actorId;
  late final workspace = widget.ops.data?['workspaceId'];
  late final day = widget.ops.data?['day'];
  String severity = 'blocked';
  OptimizedPhoto? pending;
  Json? candidate;
  bool busy = false, photoBusy = false, leaving = false;
  String? error;
  bool get current =>
      actor == widget.ops.actorId &&
      workspace == widget.ops.data?['workspaceId'] &&
      day == widget.ops.data?['day'];
  bool get dirty =>
      reason.text.isNotEmpty || pending != null || candidate != null;
  Future<void> close() async {
    if (busy || photoBusy) return;
    if (dirty &&
        await showAppDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: Text(context.t('welcome.leaveTitle')),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: Text(context.t('welcome.keepEditing')),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: Text(context.t('welcome.discard')),
                  ),
                ],
              ),
            ) !=
            true) {
      return;
    }
    if (mounted) {
      setState(() => leaving = true);
      Navigator.pop(context);
    }
  }

  Future<void> save() async {
    if (!current || busy || photoBusy || reason.text.trim().isEmpty) return;
    setState(() => busy = true);
    try {
      if (pending != null) {
        candidate = await widget.ops.uploadWorkIssuePhoto(
          pending!.bytes,
          widget.task['id'],
        );
        pending = null;
      }
      if (!mounted) return;
      if (!current) {
        setState(() {
          busy = false;
          error = context.t('welcome.scopeChanged');
        });
        return;
      }
      final ok = await widget.ops.act('flag_work_issue', {
        'taskId': widget.task['id'],
        'requestId': requestId,
        'reason': reason.text.trim(),
        'severity': severity,
        if (candidate != null) 'photo': candidate!['reference'],
        if (candidate != null) 'photoReceipt': candidate!['receipt'],
      });
      if (!mounted) return;
      if (ok && current) {
        setState(() => leaving = true);
        Navigator.pop(context);
      } else {
        setState(() {
          busy = false;
          unknownResult =
              widget.ops.actionFailure?['code'] == 'WRITE_RESULT_UNKNOWN';
          error = actionFailureText(context, widget.ops);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          error = context.t('photo.pickFailed');
        });
      }
    }
  }

  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.ops,
    builder: (context, _) => PopScope(
      canPop: leaving || (!busy && !photoBusy && !dirty),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) close();
      },
      child: AppEditorScaffold(
        title: context.t('issue.report'),
        onClose: close,
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            RadioGroup<String>(
              groupValue: severity,
              onChanged: (value) {
                if (!busy && !unknownResult && current && value != null) {
                  setState(() => severity = value);
                }
              },
              child: Column(
                children: [
                  for (final value in ['blocked', 'note'])
                    RadioListTile<String>(
                      value: value,
                      enabled: !busy && !unknownResult && current,
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.t('issue.$value')),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: reason,
              maxLength: 500,
              minLines: 3,
              maxLines: 6,
              enabled: !busy && !unknownResult && current,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: context.t('issue.reason')),
            ),
            if (widget.ops.data?['mediaUploadEnabled'] == true &&
                (widget.task['canComplete'] == true || widget.ops.canEditTasks))
              PhotoRegistrationField(
                previewBuilder: (value) => placePhoto(value, ops: widget.ops),
                value: candidate?['reference'] ?? '',
                pending: pending,
                scopeKey: (actor, workspace, day, widget.task['id']),
                isScopeCurrent: () => current,
                enabled: !busy && !unknownResult && current,
                onBusyChanged: (v) => setState(() => photoBusy = v),
                onChanged: (photo) => setState(() {
                  pending = photo;
                  candidate = null;
                }),
                onRemove: () => setState(() {
                  pending = null;
                  candidate = null;
                }),
              ),
          ],
        ),
        footer: AppSheetFooter(
          children: [
            if (error != null) Information(error!),
            if (!current) Information(context.t('welcome.scopeChanged')),
            FilledButton(
              onPressed:
                  busy || photoBusy || !current || reason.text.trim().isEmpty
                  ? null
                  : save,
              child: Text(context.t(busy ? 'common.saving' : 'issue.record')),
            ),
          ],
        ),
      ),
    ),
  );
}
