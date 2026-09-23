import 'package:flutter/material.dart';
import 'components.dart';

/// Supplied menu sheet: use dish art only for matching sample menu items.
class MenuArtwork extends StatelessWidget {
  const MenuArtwork({super.key, required this.menuId, required this.menuName});

  final String menuId;
  final String menuName;

  static const _art = <String, Rect>{
    'soup': Rect.fromLTWH(140, 285, 535, 550),
    'salad': Rect.fromLTWH(730, 285, 535, 550),
    'bowl': Rect.fromLTWH(140, 885, 535, 565),
    'tomato': Rect.fromLTWH(140, 885, 535, 565),
    'pork': Rect.fromLTWH(730, 885, 535, 565),
  };

  @override
  Widget build(BuildContext context) {
    final crop = _art[menuId];
    if (crop == null) {
      final emoji = switch (menuId) {
        'tea' => '🍜',
        'water' => '🥤',
        'special' => '🍳',
        _ => '🍽️',
      };
      return Semantics(
        label: '$menuName 그림',
        image: true,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF7EEE1),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 24)),
        ),
      );
    }
    return ArtworkCrop(
      asset: 'assets/menu/menu_tap2.png',
      crop: crop,
      width: 48,
      height: 48,
      borderRadius: 12,
      semanticLabel: '$menuName 그림',
    );
  }
}
