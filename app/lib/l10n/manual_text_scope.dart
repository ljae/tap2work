import 'package:flutter/widgets.dart';
import '../data/bundled_manual_translations.dart';
import 'app_localizations.dart';

class PreparedManualScope extends StatefulWidget {
  const PreparedManualScope({
    super.key,
    required this.language,
    required this.child,
  });
  final String language;
  final Widget child;
  @override
  State<PreparedManualScope> createState() => _PreparedManualScopeState();
}

class _PreparedManualScopeState extends State<PreparedManualScope> {
  late Future<Map<String, String>> loading = BundledManualTranslations.load(
    widget.language,
  );
  @override
  void didUpdateWidget(PreparedManualScope old) {
    super.didUpdateWidget(old);
    if (old.language != widget.language) {
      loading = BundledManualTranslations.load(widget.language);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, String>>(
    future: loading,
    builder: (_, snapshot) => _ManualDictionary(
      // Never show the previous language while the next dictionary loads.
      values: snapshot.connectionState == ConnectionState.done
          ? snapshot.data ?? const {}
          : const {},
      child: widget.child,
    ),
  );
}

class _ManualDictionary extends InheritedWidget {
  const _ManualDictionary({required this.values, required super.child});
  final Map<String, String> values;
  @override
  bool updateShouldNotify(_ManualDictionary old) =>
      !identical(values, old.values);
}

String manualDisplayText(
  BuildContext context,
  String source, {
  Map<String, dynamic>? translations,
  String? templateId,
  String? stepId,
  String field = 'title',
}) {
  final language = AppStrings.of(context).languageTag;
  if (language == 'ko') return source;
  final row = translations?['manuals']?[templateId]?[language];
  dynamic cell;
  if (stepId == null) {
    cell = row?[field];
  } else {
    cell = row?['steps']?[stepId]?[field];
  }
  if (cell is Map && cell['sourceText'] == source && cell['text'] is String) {
    return cell['text'] as String;
  }
  return context
          .dependOnInheritedWidgetOfExactType<_ManualDictionary>()
          ?.values[source] ??
      source;
}
