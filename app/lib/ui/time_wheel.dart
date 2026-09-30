import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'components.dart';

/// Shared 24-hour / half-hour input. A draft changes only on explicit apply.
Future<String?> showTimeWheel(
  BuildContext context, {
  required String title,
  required String value,
}) async {
  var hour = int.parse(value.split(':')[0]);
  var minute = int.parse(value.split(':')[1]) ~/ 30;
  final hourController = FixedExtentScrollController(initialItem: hour);
  final minuteController = FixedExtentScrollController(initialItem: minute);
  try {
    return await showAppFormSheet<String>(
      context: context,
      preferredHeight:
          420 + (MediaQuery.textScalerOf(context).scale(16) - 16) * 4,
      builder: (context) => AppSheetPanel(
        title: Text(title),
        content: SizedBox(
          height: 216,
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  label: '시',
                  child: CupertinoPicker(
                    scrollController: hourController,
                    itemExtent: 48,
                    onSelectedItemChanged: (v) => hour = v,
                    children: [
                      for (var i = 0; i < 24; i++)
                        Center(
                          child: Text(
                            '${i.toString().padLeft(2, '0')}시',
                            style: AppText.body,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Semantics(
                  label: '분',
                  child: CupertinoPicker(
                    scrollController: minuteController,
                    itemExtent: 48,
                    onSelectedItemChanged: (v) => minute = v,
                    children: [
                      for (final m in ['00분', '30분'])
                        Center(child: Text(m, style: AppText.body)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              '${hour.toString().padLeft(2, '0')}:${minute == 0 ? '00' : '30'}',
            ),
            child: const Text('적용'),
          ),
        ],
      ),
    );
  } finally {
    hourController.dispose();
    minuteController.dispose();
  }
}

class AppTimeField extends StatelessWidget {
  const AppTimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label, value;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onChanged == null
        ? null
        : () async {
            final next = await showTimeWheel(
              context,
              title: label,
              value: value,
            );
            if (next != null) onChanged!(next);
          },
    child: Text('$label $value'),
  );
}
