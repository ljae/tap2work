import 'package:flutter/material.dart';

// Native builds retain the existing external-player action. This web release
// does not add an unverified native codec/plugin dependency.
Widget manualVideo(
  String url,
  String label,
  VoidCallback onError, {
  bool motion = false,
}) => const SizedBox.shrink();
