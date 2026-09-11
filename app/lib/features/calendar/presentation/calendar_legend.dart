import 'package:flutter/material.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/shared/theme/vrijdag_theme.dart';
import 'package:vrijdag/shared/theme/vrijdag_tokens.dart';

/// Dot = event, ring = birthday (Task 02 Year / Month legend).
class CalendarLegend extends StatelessWidget {
  const CalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).vrijdagColors;
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(fontSize: 12, color: colors.inkSoft);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VrijdagSpacing.page,
        0,
        VrijdagSpacing.page,
        VrijdagSpacing.sm,
      ),
      child: Wrap(
        spacing: VrijdagSpacing.lg,
        runSpacing: VrijdagSpacing.xs,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colors.ink,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: VrijdagSpacing.xs),
              Text(l10n.yearLegendEvent, style: style),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.rust, width: 1.5),
                ),
              ),
              const SizedBox(width: VrijdagSpacing.xs),
              Text(l10n.yearLegendBirthday, style: style),
            ],
          ),
        ],
      ),
    );
  }
}
