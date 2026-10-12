import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import '../l10n/app_localizations.dart';
import '../l10n/entity_name_scope.dart';
import 'components.dart';
import 'manual_translation_editor.dart';

Future<void> editEntityNameTranslation(
  BuildContext context,
  OperationsController ops,
  String kind,
  String id,
  String source,
) async {
  if (ops.readOnly || (kind == 'part' ? !ops.isOwner : !ops.canEditTasks)) {
    return;
  }
  final actor = ops.actorId, workspace = ops.data?['workspaceId'];
  final locale = await showAppSheet<String>(
    context,
    builder: (c) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(c.t('translation.edit'), style: AppText.title),
          ),
          for (final language in appLanguageNames.entries.where(
            (e) => e.key != 'ko',
          ))
            ListTile(
              title: Text(language.value),
              onTap: () => Navigator.pop(c, language.key),
            ),
        ],
      ),
    ),
  );
  if (!context.mounted ||
      locale == null ||
      ops.actorId != actor ||
      ops.data?['workspaceId'] != workspace) {
    return;
  }
  await showAppFormSheet<void>(
    context: context,
    builder: (_) => ManualTranslationEditor(
      ops: ops,
      kind: kind,
      entityId: id,
      locale: locale,
      source: {'name': source},
      initial: {
        'name': entityDisplayName(
          context,
          ops,
          kind,
          id,
          source,
          locale: locale,
        ),
      },
    ),
  );
}
