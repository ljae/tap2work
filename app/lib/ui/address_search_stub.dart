import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';

Widget addressSearch(
  String query,
  ValueChanged<Map<String, dynamic>> onSelected,
) => Builder(
  builder: (context) => Padding(
    padding: EdgeInsets.all(24),
    child: Text(context.t('ui.audit1079')),
  ),
);
