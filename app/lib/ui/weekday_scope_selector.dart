import 'package:flutter/material.dart';
import 'components.dart';

/// Shared editing scope. Selecting days never changes their saved values.
class WeekdayScopeSelector extends StatelessWidget {
  const WeekdayScopeSelector({
    super.key,
    required this.all,
    required this.selected,
    required this.openDays,
    required this.enabled,
    required this.onMode,
    required this.onDay,
  });
  final bool all, enabled;
  final Set<int> selected, openDays;
  final ValueChanged<bool> onMode;
  final ValueChanged<int> onDay;
  static const names = ['월', '화', '수', '목', '금', '토', '일'];
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 8,
        children: [
          for (final mode in [true, false])
            SizedBox(
              width: 124,
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(mode ? '전체' : '개별'),
                value: all == mode,
                onChanged: enabled ? (_) => onMode(mode) : null,
              ),
            ),
        ],
      ),
      Builder(
        builder: (context) {
          final chips = <Widget>[
            for (var d = 1; d <= 7; d++)
              ChoiceChip(
                key: ValueKey('scope-day-$d'),
                showCheckmark: false,
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                label: SizedBox(
                  width: 32,
                  child: Center(
                    child: Text(
                      names[d - 1],
                      style: TextStyle(
                        decoration: openDays.contains(d)
                            ? null
                            : TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                ),
                selected: openDays.contains(d) && (all || selected.contains(d)),
                onSelected: enabled && openDays.contains(d)
                    ? (_) => onDay(d)
                    : null,
              ),
          ];
          if (MediaQuery.textScalerOf(context).scale(14) > 18) {
            return Wrap(spacing: 8, runSpacing: 4, children: chips);
          }
          return Row(
            children: [
              for (final chip in chips)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: chip,
                  ),
                ),
            ],
          );
        },
      ),
      if (!all)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('여러 요일을 함께 선택할 수 있어요.', style: AppText.caption),
        ),
    ],
  );
}
