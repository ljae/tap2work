import 'dart:async';
import 'package:flutter/material.dart';
import 'components.dart';

/// Real startup/data loading, without a fabricated percentage or minimum delay.
class AppLoadingScreen extends StatefulWidget {
  const AppLoadingScreen({
    super.key,
    this.error,
    this.onRetry,
    this.showSkeleton = true,
  });
  final bool showSkeleton;
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
    timer = Timer(const Duration(seconds: 12), () {
      if (mounted) setState(() => slow = true);
    });
  }

  @override
  void didUpdateWidget(covariant AppLoadingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.error != widget.error) {
      if (widget.error == null) {
        startWaiting();
      } else {
        timer?.cancel();
      }
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.error == null && !slow
      ? Scaffold(
          backgroundColor: AppColors.paper,
          body: widget.showSkeleton
              ? const WorkspaceSkeleton()
              : const SizedBox.expand(),
        )
      : Scaffold(
          backgroundColor: AppColors.paper,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          widget.error != null ? '연결을 확인해 주세요' : '매장을 준비하고 있어요',
                          textAlign: TextAlign.center,
                          style: AppText.section,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.error ??
                            (slow
                                ? '연결이 조금 늦어지고 있어요. 잠시만 기다려 주세요.'
                                : '오늘의 업무와 근무표를 불러와요.'),
                        textAlign: TextAlign.center,
                        style: AppText.caption,
                      ),
                      const SizedBox(height: 28),
                      if (widget.error == null)
                        const ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                          child: AppLinearProgress(minHeight: 4),
                        ),
                      if (widget.error != null && widget.onRetry != null)
                        FilledButton.icon(
                          onPressed: widget.onRetry,
                          icon: const Icon(Icons.refresh),
                          label: const Text('다시 시도'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
}
