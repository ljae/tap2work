import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../state/app_locale_controller.dart';
import 'components.dart';

class AppLanguageButton extends StatelessWidget {
  const AppLanguageButton({super.key});
  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () => openAppLanguagePicker(context),
    icon: const Icon(Icons.language_outlined, size: 20),
    label: Text(
      appLanguageNames[AppLocaleScope.controllerOf(context).languageTag]!,
    ),
  );
}

Future<void> openAppLanguagePicker(BuildContext context) async {
  final controller = AppLocaleScope.controllerOf(context);
  await showAppSheet<void>(
    context,
    builder: (context) => ListenableBuilder(
      listenable: controller,
      builder: (context, _) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.t('language.title'), style: AppText.title),
              const SizedBox(height: 16),
              for (final entry in appLanguageNames.entries)
                ListTile(
                  title: Text(
                    entry.value,
                    style: AppText.body.copyWith(
                      fontFamilyFallback: appFontFallbacks,
                    ),
                  ),
                  selected: controller.languageTag == entry.key,
                  trailing: controller.languageTag == entry.key
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () async {
                    await controller.selectLanguage(entry.key);
                    if (context.mounted && controller.lastError == null) {
                      Navigator.pop(context);
                    }
                  },
                ),
              if (controller.lastError != null)
                Text(
                  context.t(controller.lastError!),
                  style: AppText.caption.copyWith(color: AppColors.accent),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.t('common.close')),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
