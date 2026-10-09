import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'components.dart';

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
                                Expanded(child: _actions()),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _LoginIntroduction(),
                                const SizedBox(height: AppSpacing.section),
                                _actions(),
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

  Widget _actions() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
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
            const Text('내 매장으로 들어가기', style: AppText.section),
            const SizedBox(height: AppSpacing.large),
            signInButtons,
            const SizedBox(height: AppSpacing.medium),
            const Text(
              '비밀번호는 TAP Work에 전달되지 않아요.',
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
          child: const Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text('저장 없이 샘플 둘러보기'),
              Icon(CupertinoIcons.arrow_right, size: 16),
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
          child: const Text('개인정보처리방침'),
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
        '우리 매장의 하루를',
        style: AppText.title.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 4),
      Text(
        '함께, 더 가볍게.',
        style: AppText.title.copyWith(
          color: AppColors.green,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: AppSpacing.small),
      const Text('오늘의 업무부터 근무표까지,\n크루와 함께 한곳에서 관리해요.', style: AppText.body),
      const SizedBox(height: AppSpacing.medium),
      const Text('업무 · 매뉴얼 · 근무표 · 우리매장', style: AppText.caption),
    ],
  );
}
