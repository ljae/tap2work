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
      if (mounted) {
        setState(() => slow = true);
      }
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
    final loading = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: TapWaterLoading(animate: !failed)),
        const SizedBox(height: 20),
        Semantics(
          liveRegion: true,
          child: Text(
            failed ? '매장을 불러오지 못했어요' : widget.title,
            textAlign: TextAlign.center,
            style: AppText.section,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.error ??
              (slow ? '연결이 조금 늦어지고 있어요. 잠시 기다리거나 다시 시도해 주세요.' : widget.message),
          textAlign: TextAlign.center,
          style: AppText.caption,
        ),
        const SizedBox(height: 24),
        if ((failed || slow) && widget.onRetry != null) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: widget.onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
        ],
      ],
    );
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) =>
              widget.showSkeleton &&
                  !failed &&
                  !slow &&
                  constraints.maxHeight >= 600
              ? Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: loading,
                        ),
                      ),
                    ),
                    const Expanded(child: WorkspaceSkeleton()),
                  ],
                )
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: loading,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
