import 'package:flutter/widgets.dart';
import '../l10n/app_localizations.dart';
import '../state/operations_controller.dart';

/// Stable server codes select a recovery instruction in the user's language.
/// Unknown details stay available as source text elsewhere, never as the only
/// instruction a worker receives.
String actionFailureText(BuildContext context, OperationsController ops) =>
    context.t(switch (ops.actionFailure?['code']) {
      'REVISION_CONFLICT' => 'failure.revision',
      'WRITE_RESULT_UNKNOWN' => 'failure.unknownResult',
      'WORK_ISSUE_BLOCKED' => 'work.issueBlocked',
      'ISSUE_PHOTO_FORBIDDEN' => 'failure.photoForbidden',
      'INVENTORY_NOT_READY' => 'failure.inventoryNotReady',
      _ => 'work.saveFailed',
    });
