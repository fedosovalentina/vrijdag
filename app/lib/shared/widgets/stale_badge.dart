import 'package:flutter/material.dart';
import 'package:vrijdag/shared/theme/vrijdag_tokens.dart';
import 'package:vrijdag/shared/theme/vrijdag_theme.dart';

/// Honest age label for cached world data.
class StaleBadge extends StatelessWidget {
  const StaleBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).vrijdagColors;
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: colors.warmGrey),
    );
  }
}

/// Compact all-day / birthday chip above the timed spine.
class AllDayMarker extends StatelessWidget {
  const AllDayMarker({super.key, required this.label, required this.title});

  final String label;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.vrijdagColors;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: VrijdagSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: VrijdagSpacing.sm,
        vertical: VrijdagSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: colors.dust),
        borderRadius: BorderRadius.circular(VrijdagRadii.md),
      ),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodyMedium?.copyWith(color: colors.ink),
          children: [
            TextSpan(
              text: '$label ',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.warmGrey,
                letterSpacing: 0.4,
              ),
            ),
            TextSpan(text: title),
          ],
        ),
      ),
    );
  }
}
