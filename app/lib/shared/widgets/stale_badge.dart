import 'package:flutter/material.dart';
import 'package:vrijdag/shared/theme/vrijdag_theme.dart';
import 'package:vrijdag/shared/theme/vrijdag_tokens.dart';

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

/// All-day / birthday band above the timed spine (task-02-measurements).
class AllDayMarker extends StatelessWidget {
  const AllDayMarker({
    super.key,
    required this.label,
    required this.title,
    this.onTap,
  });

  final String label;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.vrijdagColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VrijdagSpacing.page,
        0,
        VrijdagSpacing.page,
        VrijdagSpacing.sm,
      ),
      child: Material(
        color: colors.paper,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VrijdagRadii.control),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: VrijdagSpacing.sm,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: colors.hair),
              borderRadius: BorderRadius.circular(VrijdagRadii.control),
            ),
            child: Text.rich(
              TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  color: colors.ink,
                ),
                children: [
                  TextSpan(
                    text: label.toUpperCase(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      letterSpacing: 0.44,
                      color: colors.warmGrey,
                    ),
                  ),
                  const TextSpan(text: '  '),
                  TextSpan(text: title),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
