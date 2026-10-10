import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../data/bundled_manual_translations.dart';
import 'manual_translation_editor.dart';
import '../state/operations_controller.dart';
import 'components.dart';

/// Translates display text only. IDs, photos and completion callbacks keep their
/// original objects; switching languages cannot create or complete work.
class TranslatedContent extends StatefulWidget {
  const TranslatedContent({
    super.key,
    required this.ops,
    required this.kind,
    this.entityId,
    this.stepId,
    required this.source,
    required this.builder,
    this.loadDictionary,
  });
  final OperationsController ops;
  final String kind;
  final String? entityId, stepId;
  final Json source;
  final Future<Map<String, String>> Function(String)? loadDictionary;
  final Widget Function(BuildContext context, Json displayed) builder;
  @override
  State<TranslatedContent> createState() => _TranslatedContentState();
}

class _TranslatedContentState extends State<TranslatedContent> {
  String signature = '';
  String language = 'ko';
  int generation = 0;
  bool loading = false, original = false, missing = false, google = false;
  Json? translated;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(TranslatedContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync({bool force = false}) {
    language = AppStrings.of(context).languageTag;
    final next = jsonEncode([
      widget.ops.actorId,
      widget.ops.data?['workspaceId'],
      widget.kind,
      widget.entityId,
      widget.stepId,
      language,
      widget.source,
      widget.ops.data?['manualContentTranslations'],
    ]);
    if (!force && next == signature) return;
    signature = next;
    final request = ++generation;
    translated = null;
    original = false;
    missing = false;
    google = false;
    final sourceLanguage = '${widget.source['sourceLocale'] ?? 'ko'}';
    loading = language != sourceLanguage;
    if (!loading) return;
    _load(request);
  }

  Json? _selected(Json? document) {
    if (document == null) return null;
    if (widget.stepId == null) return document;
    return (document['steps'] as List? ?? [])
        .whereType<Json>()
        .where((row) => row['id'] == widget.stepId)
        .firstOrNull;
  }

  Future<void> _load(int request) async {
    final actor = widget.ops.actorId;
    final workspace = widget.ops.data?['workspaceId'];
    final displayFields =
        [
              'title',
              'manual',
              'tip',
              'body',
              'name',
              'floor',
              'area',
              'description',
            ]
            .where(
              (key) =>
                  widget.source[key] is String &&
                  (widget.source[key] as String).trim().isNotEmpty,
            )
            .toList();
    final overlay = <String, dynamic>{};
    final store = widget.ops.data?['manualContentTranslations'];
    String? templateId = widget.entityId;
    if (widget.kind == 'task') {
      templateId = widget.ops
          .rows('tasks')
          .where((t) => t['id'] == widget.entityId)
          .firstOrNull?['templateId'];
    }
    dynamic languageRows;
    if (widget.kind == 'welcome') {
      languageRows = store?['welcome']?[language];
    } else if (widget.kind == 'place') {
      final places = store?['places'];
      final place = places?[widget.entityId];
      languageRows = place?[language];
    } else {
      languageRows = store?['manuals']?[templateId]?[language];
    }
    final cells = widget.stepId == null
        ? languageRows
        : languageRows?['steps']?[widget.stepId];
    for (final field in displayFields) {
      final source = widget.source[field] as String;
      final cell = cells?[field];
      if (cell is Map &&
          cell['sourceText'] == source &&
          cell['text'] is String) {
        overlay[field] = cell['text'];
      }
    }
    if (overlay.length < displayFields.length) {
      final dictionary =
          await (widget.loadDictionary ?? BundledManualTranslations.load)(
            language,
          );
      if (!mounted || request != generation) return;
      for (final field in displayFields) {
        final value = dictionary[widget.source[field]];
        if (!overlay.containsKey(field) && value != null) {
          overlay[field] = value;
        }
      }
    }
    // Paid translation is opt-in deployment capability, disabled for this
    // release. Prepared dictionaries and registered edits need no API call.
    if (overlay.length < displayFields.length &&
        widget.kind != 'place' &&
        widget.ops.data?['translationRuntimeEnabled'] == true) {
      try {
        final result = await widget.ops.translateContent(
          kind: widget.kind,
          id: widget.entityId,
          targetLocale: language,
        );
        if (!mounted || request != generation) return;
        final source = _selected(result['original'] as Json?);
        final candidate = _selected(result['translated'] as Json?);
        if (result['status'] == 'translated' &&
            source != null &&
            candidate != null) {
          for (final field in displayFields) {
            if (source[field] == widget.source[field] &&
                candidate[field] is String) {
              overlay[field] = candidate[field];
              google = true;
            }
          }
        }
      } catch (_) {
        /* Current source stays readable. */
      }
    }
    if (!mounted ||
        request != generation ||
        actor != widget.ops.actorId ||
        workspace != widget.ops.data?['workspaceId']) {
      return;
    }
    await Future<void>.value();
    if (!mounted || request != generation) return;
    setState(() {
      loading = false;
      missing = overlay.length < displayFields.length;
      translated = overlay.isEmpty ? null : overlay;
    });
  }

  @override
  Widget build(BuildContext context) {
    final foreign = language != '${widget.source['sourceLocale'] ?? 'ko'}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (foreign) ...[
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                context.t(
                  loading
                      ? 'manual.translating'
                      : missing
                      ? 'translation.needed'
                      : google
                      ? 'manual.automaticTranslation'
                      : 'translation.prepared',
                ),
                style: AppText.caption,
              ),
              if (translated != null)
                TextButton(
                  onPressed: () => setState(() => original = !original),
                  child: Text(
                    context.t(
                      original ? 'manual.translation' : 'manual.original',
                    ),
                  ),
                ),
              if (!loading &&
                  widget.ops.canEditTasks &&
                  !widget.ops.readOnly &&
                  (widget.kind == 'welcome' ||
                      widget.kind == 'manual' ||
                      widget.kind == 'place'))
                TextButton(
                  onPressed: () async {
                    await showAppFormSheet<void>(
                      context: context,
                      builder: (_) => ManualTranslationEditor(
                        ops: widget.ops,
                        kind: widget.kind,
                        entityId: widget.entityId,
                        stepId: widget.stepId,
                        locale: language,
                        source: widget.source,
                        initial: translated ?? {},
                      ),
                    );
                    if (mounted) setState(() => _sync(force: true));
                  },
                  child: Text(context.t('translation.edit')),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        widget.builder(context, {
          ...widget.source,
          if (!original && translated != null) ...translated!,
        }),
        if (google && !original && translated != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => launchUrl(
                Uri.parse('https://translate.google.com/'),
                mode: LaunchMode.externalApplication,
              ),
              child: Image.asset(
                'assets/branding/google_translate.png',
                height: 24,
                semanticLabel: 'Powered by Google Translate',
              ),
            ),
          ),
      ],
    );
  }
}
