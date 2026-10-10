import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';
import 'translated_content.dart';
import 'place_guide.dart';

/// Place photographs and guidance share the action, with the same free exact-
/// source translation contract as the full place page. IDs/photos stay fixed.
class LinkedPlaceGuide extends StatelessWidget {
  const LinkedPlaceGuide({super.key, required this.ops, required this.place});
  final OperationsController ops;
  final Json place;
  @override
  Widget build(BuildContext context) => TranslatedContent(
    ops: ops,
    kind: 'place',
    entityId: place['zoneId'],
    source: place,
    builder: (context, shown) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${shown['name'] ?? ''}', style: AppText.section),
          Text(placeAddress(shown), style: AppText.caption),
          const SizedBox(height: AppSpacing.small),
          if ('${shown['photo'] ?? ''}'.isNotEmpty)
            placePhoto(shown['photo'], ops: ops),
          Text('${shown['description'] ?? ''}', style: AppText.body),
        ],
      ),
    ),
  );
}
