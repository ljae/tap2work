import 'package:flutter/material.dart';

abstract final class AppColors {
  static const paper = Color(0xFFF2F4F6);
  static const white = Color(0xFFFFFFFF);
  // This coral keeps white button labels above the normal-text contrast target.
  static const accent = Color(0xFFB8422C);
  static const accentSoft = Color(0xFFFFECE6);
  static const green = Color(0xFF193B3A);
  static const ink = Color(0xFF191F28);
  static const muted = Color(0xFF6B7684);
  static const lime = Color(0xFFEAF1E7);
  static const peach = Color(0xFFFFEBE4);
  static const line = Color(0xFFD7DEDA);
  static const controlLine = Color(0xFF829586);
}

abstract final class AppSpacing {
  static const small = 8.0;
  static const medium = 16.0;
  static const large = 24.0;
  static const section = 32.0;
}

abstract final class AppText {
  static const title = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.ink,
  );
  static const body = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.ink,
  );
  static const caption = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.muted,
  );
}

const appCardShadow = [
  BoxShadow(color: Color(0x0A000000), blurRadius: 20, offset: Offset(0, 4)),
];
