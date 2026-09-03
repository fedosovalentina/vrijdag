import 'package:flutter/material.dart';
import 'package:vrijdag/shared/theme/vrijdag_tokens.dart';
import 'package:vrijdag/shared/theme/vrijdag_theme.dart';

/// Large spoken-form date header (F-094 / F-007).
class DateHeader extends StatelessWidget {
  const DateHeader({
    super.key,
    required this.weekdayLabel,
    required this.dateLabel,
  });

  final String weekdayLabel;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.vrijdagColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VrijdagSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            weekdayLabel,
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.warmGrey),
          ),
          Text(dateLabel, style: theme.textTheme.headlineMedium),
        ],
      ),
    );
  }
}
