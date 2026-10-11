import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../state/app_locale_controller.dart';
import 'components.dart';
import 'country_flag.dart';

class AppLanguageButton extends StatelessWidget {
  const AppLanguageButton({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final controller = AppLocaleScope.controllerOf(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final tag = controller.languageTag;
        final name = appLanguageNames[tag]!;
        final flag = CountryFlag(countryCode: appLanguageCountries[tag]);
        if (compact) {
          return IconButton(
            key: const ValueKey('header-language-button'),
            tooltip: '${context.t('language.title')} · $name',
            onPressed: () => openAppLanguagePicker(context),
            style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
            icon: flag,
          );
        }
        return TextButton.icon(
          onPressed: () => openAppLanguagePicker(context),
          icon: flag,
          label: Text(name),
        );
      },
    );
  }
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
                  key: ValueKey('app-language-${entry.key}'),
                  leading: CountryFlag(
                    countryCode: appLanguageCountries[entry.key],
                  ),
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
