import 'package:flutter/material.dart';

abstract final class AppColors {
  static const paper = Color(0xFF101112);
  static const surface = Color(0xFF181A1C);
  static const elevated = Color(0xFF222528);
  static const white = Color(0xFFFFFFFF);
  static const accent = Color(0xFFFF9986);
  static const accentSoft = Color(0xFF392622);
  static const green = Color(0xFF46C69B);
  static const primary = Color(0xFF007D73);
  static const ink = Color(0xFFF0F2F4);
  static const muted = Color(0xFFA0A7AF);
  static const lime = Color(0xFF17382E);
  static const peach = Color(0xFF392E20);
  static const amber = Color(0xFFE9AC4C);
  static const blue = Color(0xFF8DBAEA);
  static const line = Color(0xFF2B2E32);
  static const controlLine = Color(0xFF686F78);
}

abstract final class AppSpacing {
  static const small = 8.0;
  static const medium = 16.0;
  static const large = 24.0;
  static const section = 32.0;
}

abstract final class AppText {
  static const section = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.4,
    color: AppColors.ink,
  );
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
