import 'package:flutter/material.dart';
import '../data/photo_capture_service.dart';
import 'components.dart';

class PhotoRegistrationField extends StatefulWidget {
  const PhotoRegistrationField({
    super.key,
    required this.value,
    this.pending,
    required this.onChanged,
    required this.onRemove,
    required this.scopeKey,
    required this.isScopeCurrent,
    this.onBusyChanged,
    this.enabled = true,
    this.previewBuilder,
    this.service,
  });
  final String value;
  final OptimizedPhoto? pending;
  final ValueChanged<OptimizedPhoto> onChanged;
  final VoidCallback onRemove;
  final Object scopeKey;
  final bool Function() isScopeCurrent;
  final ValueChanged<bool>? onBusyChanged;
  final bool enabled;
  final Widget Function(String)? previewBuilder;
  final PhotoCaptureService? service;

  @override
  State<PhotoRegistrationField> createState() => _PhotoRegistrationFieldState();
}

class _PhotoRegistrationFieldState extends State<PhotoRegistrationField> {
  late final service = widget.service ?? PhotoCaptureService();
  int job = 0;
  bool busy = false;
  String? error;

  Future<void> pick(PhotoSource source) async {
    final currentJob = ++job;
    final scope = widget.scopeKey;
    setState(() {
      busy = true;
      error = null;
    });
    widget.onBusyChanged?.call(true);
    try {
      final photo = await service.pick(source);
      if (!mounted || job != currentJob) return;
      if (widget.scopeKey != scope || !widget.isScopeCurrent()) {
        setState(() => error = '편집 중인 매장이나 항목이 바뀌었어요. 다시 열어 주세요.');
        return;
      }
      if (photo != null) widget.onChanged(photo);
    } catch (e) {
      if (mounted && job == currentJob && widget.scopeKey == scope) {
        setState(
          () => error = e is PhotoException
              ? e.message
              : '사진을 가져오지 못했어요. 다시 시도해 주세요.',
        );
      }
    } finally {
      if (mounted && job == currentJob) {
        setState(() => busy = false);
        widget.onBusyChanged?.call(false);
      }
    }
  }

  void remove() {
    ++job;
    if (busy) widget.onBusyChanged?.call(false);
    setState(() {
      busy = false;
      error = null;
    });
    widget.onRemove();
  }

  @override
  void dispose() {
    ++job;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.pending != null || widget.value.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.pending != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(
              widget.pending!.bytes,
              height: 240,
              fit: BoxFit.contain,
            ),
          )
        else if (widget.value.isNotEmpty)
          widget.previewBuilder?.call(widget.value) ??
              Image.network(
                widget.value,
                height: 240,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Text('사진을 불러오지 못했어요. 다시 선택해 주세요.'),
              ),
        if (hasPhoto) const SizedBox(height: 16),
        if (service.supportsCamera)
          FilledButton.icon(
            onPressed: !widget.enabled || busy
                ? null
                : () => pick(PhotoSource.camera),
            icon: const Icon(Icons.camera_alt_outlined),
            label: Text(hasPhoto ? '다시 사진 찍기' : '바로 사진 찍기'),
          ),
        TextButton.icon(
          onPressed: !widget.enabled || busy
              ? null
              : () => pick(PhotoSource.gallery),
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('앨범에서 선택'),
        ),
        if (busy)
          Semantics(
            liveRegion: true,
            child: const Text('사진을 준비하고 있어요…', style: AppText.caption),
          ),
        if (hasPhoto)
          TextButton(
            onPressed: widget.enabled ? remove : null,
            child: const Text('사진 제거'),
          ),
        if (error != null)
          Semantics(
            liveRegion: true,
            child: Text(
              error!,
              style: const TextStyle(color: AppColors.accent),
            ),
          ),
      ],
    );
  }
}
