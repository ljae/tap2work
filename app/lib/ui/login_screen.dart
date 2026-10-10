import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'components.dart';
import '../l10n/app_localizations.dart';
import 'app_language_picker.dart';

/// Presentation only: authentication and read-only preview stay in the host.
class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    required this.signInButtons,
    required this.onPrivacy,
    required this.onPreview,
  });

  final Widget signInButtons;
  final VoidCallback onPrivacy;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.9, -0.8),
          radius: 1.3,
          colors: [AppColors.lime.withValues(alpha: 0.5), AppColors.paper],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? 48 : AppSpacing.large,
                      vertical: AppSpacing.section,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: wide ? 1040 : 440),
                      child: wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Expanded(child: _LoginIntroduction()),
                                const SizedBox(width: 80),
                                Expanded(child: _actions(context)),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _LoginIntroduction(),
                                const SizedBox(height: AppSpacing.section),
                                _actions(context),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );

  Widget _actions(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Align(alignment: Alignment.centerRight, child: AppLanguageButton()),
      const SizedBox(height: AppSpacing.small),
      Container(
        padding: const EdgeInsets.all(AppSpacing.large),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: appCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.t('login.enterStore'), style: AppText.section),
            const SizedBox(height: AppSpacing.large),
            signInButtons,
            const SizedBox(height: AppSpacing.medium),
            Text(
              context.t('login.passwordPrivate'),
              style: AppText.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.medium),
      PressBounce(
        child: TextButton(
          onPressed: onPreview,
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: AppColors.ink,
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text(context.t('login.preview')),
              const Icon(CupertinoIcons.arrow_right, size: 16),
            ],
          ),
        ),
      ),
      PressBounce(
        child: TextButton(
          onPressed: onPrivacy,
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: AppColors.muted,
            textStyle: AppText.caption,
          ),
          child: Text(context.t('login.privacy')),
        ),
      ),
    ],
  );
}

class _LoginIntroduction extends StatelessWidget {
  const _LoginIntroduction();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const BrandLogo(),
      const SizedBox(height: AppSpacing.large),
      Text(
        context.t('login.heading'),
        style: AppText.title.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 4),
      Text(
        context.t('login.headingAccent'),
        style: AppText.title.copyWith(
          color: AppColors.green,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: AppSpacing.small),
      Text(context.t('login.description'), style: AppText.body),
      const SizedBox(height: AppSpacing.medium),
      Text(
        [
          'nav.work',
          'nav.manual',
          'nav.roster',
          'nav.store',
        ].map(context.t).join(' · '),
        style: AppText.caption,
      ),
    ],
  );
}
