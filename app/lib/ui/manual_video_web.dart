import 'dart:js_interop';
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

Widget manualVideo(
  String url,
  String label,
  VoidCallback onError, {
  bool motion = false,
}) => motion
    ? _MotionPlayer(url: url, label: label)
    : _ManualVideo(url: url, label: label, onError: onError);

class _MotionPlayer extends StatefulWidget {
  const _MotionPlayer({required this.url, required this.label});
  final String url, label;
  @override
  State<_MotionPlayer> createState() => _MotionPlayerState();
}

class _MotionPlayerState extends State<_MotionPlayer> {
  static int serial = 0;
  late final String viewType = 'manual-motion-${serial++}';
  late final web.HTMLIFrameElement frame;
  @override
  void initState() {
    super.initState();
    frame = web.HTMLIFrameElement()
      ..src = widget.url
      ..title = widget.label
      ..referrerPolicy = 'no-referrer'
      ..setAttribute(
        'sandbox',
        'allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox',
      )
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%';
    ui.platformViewRegistry.registerViewFactory(viewType, (_) => frame);
  }

  @override
  void dispose() {
    frame.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: viewType);
}

class _ManualVideo extends StatefulWidget {
  const _ManualVideo({
    required this.url,
    required this.label,
    required this.onError,
  });
  final String url, label;
  final VoidCallback onError;
  @override
  State<_ManualVideo> createState() => _ManualVideoState();
}

class _ManualVideoState extends State<_ManualVideo> {
  static int serial = 0;
  late final String viewType = 'manual-video-${serial++}';
  late final web.HTMLVideoElement video;
  late final JSFunction errorListener, visibilityListener;
  @override
  void initState() {
    super.initState();
    video = web.HTMLVideoElement()
      ..src = widget.url
      ..controls = true
      ..preload = 'metadata'
      ..setAttribute('playsinline', '')
      ..setAttribute('aria-label', widget.label)
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'contain'
      ..style.backgroundColor = '#111c18';
    errorListener = ((web.Event _) {
      if (mounted) widget.onError();
    }).toJS;
    visibilityListener = ((web.Event _) {
      if (web.document.hidden) video.pause();
    }).toJS;
    video.addEventListener('error', errorListener);
    web.document.addEventListener('visibilitychange', visibilityListener);
    ui.platformViewRegistry.registerViewFactory(viewType, (_) => video);
  }

  @override
  void dispose() {
    video.pause();
    video.removeEventListener('error', errorListener);
    web.document.removeEventListener('visibilitychange', visibilityListener);
    video.removeAttribute('src');
    video.load();
    video.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: viewType);
}
