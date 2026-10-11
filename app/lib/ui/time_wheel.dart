import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'components.dart';

/// Shared 24-hour / half-hour input. A draft changes only on explicit apply.
Future<String?> showTimeWheel(
  BuildContext context, {
  required String title,
  required String value,
}) => showAppFormSheet<String>(
  context: context,
  maxWidth: appEditorWidth,
  preferredHeight: 680 + (MediaQuery.textScalerOf(context).scale(16) - 16) * 8,
  builder: (_) => _TimeWheel(title: title, value: value),
);

class _TimeWheel extends StatefulWidget {
  const _TimeWheel({required this.title, required this.value});
  final String title, value;
  @override
  State<_TimeWheel> createState() => _TimeWheelState();
}

class _TimeWheelState extends State<_TimeWheel> {
  late int hour = int.parse(widget.value.split(':')[0]);
  late int minute = int.parse(widget.value.split(':')[1]) ~/ 30;
  late final hourController = FixedExtentScrollController(initialItem: hour);
  late final minuteController = FixedExtentScrollController(
    initialItem: minute,
  );
  String get value =>
      '${hour.toString().padLeft(2, '0')}:${minute == 0 ? '00' : '30'}';

  // The wheel and quick controls share the same draft; no hidden save on scroll.
  void step(int delta) {
    final next = (hour * 60 + minute * 30 + delta) % 1440;
    setState(() {
      hour = next ~/ 60;
      minute = next % 60 ~/ 30;
    });
    hourController.jumpToItem(hour);
    minuteController.jumpToItem(minute);
  }

  @override
  void dispose() {
    hourController.dispose();
    minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final extent = (MediaQuery.textScalerOf(context).scale(24) + 20).clamp(
      52.0,
      96.0,
    );
    Widget wheel({required bool hours}) => Expanded(
      child: Column(
        children: [
          Text(
            context.t(hours ? 'time.hour' : 'time.minute'),
            style: AppText.caption,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: extent * 3,
            child: Semantics(
              label: context.t(hours ? 'time.hour' : 'time.minute'),
              child: CupertinoPicker(
                scrollController: hours ? hourController : minuteController,
                itemExtent: extent,
                diameterRatio: 1.5,
                squeeze: 1.05,
                selectionOverlay: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(AppShape.control),
                    border: Border.all(
                      color: AppColors.green.withValues(alpha: .32),
                    ),
                  ),
                ),
                onSelectedItemChanged: (v) => setState(() {
                  if (hours) {
                    hour = v;
                  } else {
                    minute = v;
                  }
                }),
                children: [
                  for (var i = 0; i < (hours ? 24 : 2); i++)
                    Center(
                      child: Text(
                        (hours ? i : i * 30).toString().padLeft(2, '0'),
                        style: AppText.title.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    return AppSheetPanel(
      title: Text(widget.title),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.lime,
              borderRadius: BorderRadius.circular(AppShape.card),
            ),
            child: Column(
              children: [
                Text(
                  context.t('time.format'),
                  style: AppText.caption.copyWith(color: AppColors.green),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  key: const ValueKey('time-draft-preview'),
                  style: AppText.title.copyWith(
                    fontSize: 44,
                    letterSpacing: -1.5,
                    color: AppColors.green,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              wheel(hours: true),
              const SizedBox(width: 12),
              wheel(hours: false),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const ValueKey('time-minus-30'),
                  onPressed: () => step(-30),
                  child: Text(context.t('time.minus')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  key: const ValueKey('time-plus-30'),
                  onPressed: () => step(30),
                  child: Text(context.t('time.plus')),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.t('common.cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, value),
          child: Text(context.t('time.apply')),
        ),
      ],
    );
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
  Widget build(BuildContext context) => OutlinedButton.icon(
    icon: const Icon(CupertinoIcons.clock, size: 18),
    onPressed: onChanged == null
        ? null
        : () async {
            final next = await showTimeWheel(
              context,
              title: label,
              value: value,
            );
            if (next != null) onChanged?.call(next);
          },
    label: Text(
      '$label $value',
      style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
    ),
  );
}
