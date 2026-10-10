import 'dart:convert';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../state/operations_controller.dart';
import 'components.dart';
import 'translated_content.dart';

Future<void> openSharedWelcome(
  BuildContext context,
  OperationsController ops, {
  VoidCallback? onWork,
}) => Navigator.of(context).push<void>(
  AppPageRoute<void>(
    builder: (_) => SharedWelcomeScreen(ops: ops, onWork: onWork),
  ),
);

/// Everyone reads the same store document. Acknowledgements belong to the
/// authenticated actor and are separate from shared work completion.
class SharedWelcomeScreen extends StatefulWidget {
  const SharedWelcomeScreen({super.key, required this.ops, this.onWork});
  final OperationsController ops;
  final VoidCallback? onWork;
  @override
  State<SharedWelcomeScreen> createState() => _SharedWelcomeScreenState();
}

class _SharedWelcomeScreenState extends State<SharedWelcomeScreen> {
  late final String actor;
  late final Object? workspace;
  bool saving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    actor = widget.ops.actorId;
    workspace = widget.ops.data?['workspaceId'];
  }

  bool get valid =>
      actor == widget.ops.actorId &&
      workspace == widget.ops.data?['workspaceId'];
  void close({bool goToWork = false}) {
    if (saving) return;
    Navigator.of(context).pop();
    if (goToWork) widget.onWork?.call();
  }

  Future<void> acknowledge(Json document) async {
    final ops = widget.ops;
    if (saving || ops.busy || !valid || ops.readOnly) return;
    setState(() {
      saving = true;
      error = null;
    });
    final ok = await ops.act('ack_welcome', {
      'revision': ops.data?['revision'],
      'welcomeRevision': document['revision'],
    });
    if (!mounted) return;
    setState(() {
      saving = false;
      if (!ok) error = ops.error ?? context.t('welcome.ackFailed');
    });
    if (ok && valid) close(goToWork: true);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.ops,
    builder: (context, _) {
      final document = valid ? (widget.ops.data?['welcome'] as Json?) : null;
      final needsAck = widget.ops.data?['welcomeNeedsAcknowledgment'] == true;
      return PopScope(
        canPop: !saving,
        child: AppEditorScaffold(
          title: context.t('welcome.heading'),
          subtitle: valid
              ? '${widget.ops.data?['store']?['name'] ?? ''}'
              : null,
          onClose: close,
          body: !valid
              ? Center(child: Information(context.t('welcome.scopeChanged')))
              : document == null
              ? Center(child: Information(context.t('welcome.notReady')))
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.large),
                  children: [
                    Text(context.t('welcome.shared'), style: AppText.caption),
                    const SizedBox(height: AppSpacing.medium),
                    TranslatedContent(
                      ops: widget.ops,
                      kind: 'welcome',
                      source: document,
                      builder: (context, displayed) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${displayed['title'] ?? ''}',
                            key: const ValueKey('shared-welcome-title'),
                            style: AppText.title,
                          ),
                          const SizedBox(height: AppSpacing.large),
                          SelectableText(
                            '${displayed['body'] ?? ''}',
                            key: const ValueKey('shared-welcome-body'),
                            style: AppText.body,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.section),
                    Text(
                      context.t(
                        needsAck ? 'welcome.pending' : 'welcome.acknowledged',
                      ),
                      style: AppText.caption,
                    ),
                    if (widget.ops.canEditTasks) ...[
                      const SizedBox(height: AppSpacing.medium),
                      PressBounce(
                        child: OutlinedButton.icon(
                          key: const ValueKey('shared-welcome-edit'),
                          onPressed:
                              saving || widget.ops.busy || widget.ops.readOnly
                              ? null
                              : () => showAppFormSheet<void>(
                                  context: context,
                                  builder: (_) => SharedWelcomeEditor(
                                    ops: widget.ops,
                                    welcome: document,
                                  ),
                                ),
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(context.t('welcome.edit')),
                        ),
                      ),
                    ],
                  ],
                ),
          footer: AppSheetFooter(
            children: [
              if (error != null)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    error!,
                    style: const TextStyle(color: AppColors.accent),
                  ),
                ),
              if (widget.ops.readOnly)
                Text(context.t('welcome.preview'), style: AppText.caption),
              if (valid && document != null && needsAck && !widget.ops.readOnly)
                PressBounce(
                  child: FilledButton(
                    key: const ValueKey('shared-welcome-acknowledge'),
                    onPressed: saving || widget.ops.busy
                        ? null
                        : () => acknowledge(document),
                    child: Text(
                      context.t(
                        saving ? 'common.saving' : 'welcome.acknowledge',
                      ),
                    ),
                  ),
                ),
              PressBounce(
                child: TextButton(
                  key: const ValueKey('shared-welcome-work'),
                  onPressed: saving ? null : () => close(goToWork: true),
                  child: Text(context.t('welcome.continueWork')),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class SharedWelcomeEditor extends StatefulWidget {
  const SharedWelcomeEditor({
    super.key,
    required this.ops,
    required this.welcome,
  });
  final OperationsController ops;
  final Json welcome;
  @override
  State<SharedWelcomeEditor> createState() => _SharedWelcomeEditorState();
}

class _SharedWelcomeEditorState extends State<SharedWelcomeEditor> {
  late final String actor;
  late final Object? workspace, revision;
  late final Json original;
  late final TextEditingController title, body;
  late String sourceLocale;
  bool important = false, saving = false, leaving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    actor = widget.ops.actorId;
    workspace = widget.ops.data?['workspaceId'];
    revision = widget.ops.data?['revision'];
    original = jsonDecode(jsonEncode(widget.welcome)) as Json;
    title = TextEditingController(text: original['title'] ?? '');
    body = TextEditingController(text: original['body'] ?? '');
    sourceLocale = original['sourceLocale'] ?? 'ko';
  }

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  bool get valid =>
      actor == widget.ops.actorId &&
      workspace == widget.ops.data?['workspaceId'] &&
      widget.ops.canEditTasks;
  bool get dirty =>
      important ||
      title.text != (original['title'] ?? '') ||
      body.text != (original['body'] ?? '') ||
      sourceLocale != (original['sourceLocale'] ?? 'ko');
  Future<void> close() async {
    if (saving) return;
    final discard =
        !dirty ||
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
            ) ==
            true;
    if (discard && mounted) {
      setState(() => leaving = true);
      Navigator.pop(context);
    }
  }

  Future<void> save() async {
    if (saving || widget.ops.busy) return;
    if (!valid || widget.ops.readOnly) {
      setState(() => error = context.t('welcome.wrongPermission'));
      return;
    }
    final heading = title.text.trim(), text = body.text.trim();
    if (heading.isEmpty ||
        heading.length > 120 ||
        text.isEmpty ||
        text.length > 8000) {
      setState(() => error = context.t('welcome.validation'));
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    final ok = await widget.ops.act('save_welcome', {
      'revision': revision,
      'welcome': {'title': heading, 'body': text, 'sourceLocale': sourceLocale},
      'important': important,
    });
    if (!mounted) return;
    setState(() {
      saving = false;
      if (!ok) error = widget.ops.error ?? context.t('welcome.saveFailed');
    });
    if (ok && valid) {
      setState(() => leaving = true);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: leaving,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) close();
    },
    child: ListenableBuilder(
      listenable: widget.ops,
      builder: (context, _) => AppEditorScaffold(
        title: context.t('welcome.editorTitle'),
        subtitle: context.t('welcome.editSummary'),
        onClose: close,
        body: !valid
            ? Center(child: Information(context.t('welcome.scopeChanged')))
            : AbsorbPointer(
                absorbing: saving,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.large),
                  children: [
                    TextField(
                      key: const ValueKey('welcome-editor-title'),
                      controller: title,
                      maxLength: 120,
                      decoration: InputDecoration(
                        labelText: context.t('welcome.titleField'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      key: const ValueKey('welcome-editor-body'),
                      controller: body,
                      minLines: 5,
                      maxLines: 16,
                      maxLength: 8000,
                      decoration: InputDecoration(
                        labelText: context.t('welcome.bodyField'),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppPicker<String>(
                      label: context.t('welcome.sourceLocale'),
                      value: sourceLocale,
                      items: [
                        for (final language in appLanguageNames.entries)
                          DropdownMenuItem(
                            value: language.key,
                            child: Text(language.value),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => sourceLocale = value);
                      },
                    ),
                    const SizedBox(height: 20),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.t('welcome.important')),
                      subtitle: Text(context.t('welcome.importantHelp')),
                      value: important,
                      onChanged: (value) => setState(() => important = value),
                    ),
                  ],
                ),
              ),
        footer: AppSheetFooter(
          children: [
            if (error != null)
              Semantics(
                liveRegion: true,
                child: Text(
                  error!,
                  style: const TextStyle(color: AppColors.accent),
                ),
              ),
            PressBounce(
              child: FilledButton(
                key: const ValueKey('welcome-editor-save'),
                onPressed: !valid || saving || widget.ops.readOnly
                    ? null
                    : save,
                child: Text(
                  context.t(saving ? 'common.saving' : 'common.save'),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
