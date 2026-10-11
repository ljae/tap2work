import 'package:flutter/material.dart';

abstract final class AppColors {
  static const paper = Color(0xFF171C1C);
  static const surface = Color(0xFF232B2A);
  static const elevated = Color(0xFF303B38);
  static const white = Color(0xFFFFFFFF);
  static const accent = Color(0xFFFFA28E);
  static const accentSoft = Color(0xFF44312D);
  static const green = Color(0xFF79E2BA);
  static const primary = Color(0xFF087568);
  static const ink = Color(0xFFF2F5EF);
  static const muted = Color(0xFFADBAB4);
  static const lime = Color(0xFF29483D);
  static const peach = Color(0xFF403729);
  static const amber = Color(0xFFE9AC4C);
  static const blue = Color(0xFF8DBAEA);
  static const line = Color(0xFF3A4742);
  static const controlLine = Color(0xFF72877C);
}

abstract final class AppShape {
  static const control = 14.0;
  static const card = 20.0;
  static const sheet = 28.0;
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
    fontFamilyFallback: [
      'NotoSansThai',
      'NotoSansDevanagari',
      'NotoSansSC',
      'NotoSansJP',
    ],
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.4,
    color: AppColors.ink,
  );
  static const title = TextStyle(
    fontFamily: 'Pretendard',
    fontFamilyFallback: [
      'NotoSansThai',
      'NotoSansDevanagari',
      'NotoSansSC',
      'NotoSansJP',
    ],
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -.6,
    color: AppColors.ink,
  );
  static const body = TextStyle(
    fontFamily: 'Pretendard',
    fontFamilyFallback: [
      'NotoSansThai',
      'NotoSansDevanagari',
      'NotoSansSC',
      'NotoSansJP',
    ],
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.ink,
  );
  static const caption = TextStyle(
    fontFamily: 'Pretendard',
    fontFamilyFallback: [
      'NotoSansThai',
      'NotoSansDevanagari',
      'NotoSansSC',
      'NotoSansJP',
    ],
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.muted,
  );
}

const appCardShadow = [
  BoxShadow(color: Color(0x18000000), blurRadius: 24, offset: Offset(0, 6)),
];
