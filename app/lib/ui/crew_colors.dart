import 'package:flutter/material.dart';

/// Stable per crew ID across work and calendar; always pair color with a name.
Color crewColor(String id) {
  var hash = 0;
  for (final unit in id.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  const palette = [
    Color(0xFF62C7AF),
    Color(0xFFE49ABF),
    Color(0xFF8DBAEA),
    Color(0xFFE9AC4C),
    Color(0xFFB7A5E3),
  ];
  return palette[hash % palette.length];
}
