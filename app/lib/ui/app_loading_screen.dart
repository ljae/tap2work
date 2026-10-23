import '../l10n/app_localizations.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'components.dart';
import 'tap_water_loading.dart';

/// Shows the real loading stage without fake percentages or a minimum delay.
class AppLoadingScreen extends StatefulWidget {
  const AppLoadingScreen({
    super.key,
    this.error,
    this.onRetry,
    this.showSkeleton = true,
    this.title = '저장된 매장을 불러오고 있어요',
    this.message = '업무와 매뉴얼, 근무표를 확인하고 있어요.',
  });
  final bool showSkeleton;
  final String title;
  final String message;
  final String? error;
  final VoidCallback? onRetry;
  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen> {
  Timer? timer;
  bool slow = false;
  @override
  void initState() {
    super.initState();
    startWaiting();
  }

  void startWaiting() {
    timer?.cancel();
    slow = false;
    if (widget.error != null) return;
    timer = Timer(const Duration(seconds: 12), () {
      if (mounted) setState(() => slow = true);
    });
  }

  @override
  void didUpdateWidget(covariant AppLoadingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.error != widget.error || oldWidget.title != widget.title) {
      startWaiting();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final failed = widget.error != null;
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: BrandLogo()),
                        const SizedBox(height: 32),
                        Center(
                          child: Container(
                            width: 156,
                            height: 156,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(40),
                              gradient: RadialGradient(
                                colors: [
                                  (failed ? AppColors.accent : AppColors.green)
                                      .withValues(alpha: .12),
                                  AppColors.paper,
                                ],
                              ),
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 120,
                                height: 135,
                                child: FittedBox(
                                  child: TapWaterLoading(animate: !failed),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            failed ? context.t('ui.audit1065') : widget.title,
                            textAlign: TextAlign.center,
                            style: AppText.title,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.error ??
                              (slow
                                  ? context.t('ui.audit1066')
                                  : widget.message),
                          textAlign: TextAlign.center,
                          style: AppText.caption,
                        ),
                        if ((failed || slow) && widget.onRetry != null) ...[
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: widget.onRetry,
                            icon: const Icon(Icons.refresh),
                            label: Text(context.t('ui.audit473')),
                          ),
                        ],
                        if (widget.showSkeleton &&
                            !failed &&
                            !slow &&
                            constraints.maxHeight >= 600) ...[
                          const SizedBox(height: 32),
                          const SizedBox(
                            height: 216,
                            child: WorkspaceSkeleton(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
