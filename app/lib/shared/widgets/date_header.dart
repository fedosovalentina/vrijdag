import 'package:flutter/material.dart';
import 'package:vrijdag/shared/theme/vrijdag_theme.dart';
import 'package:vrijdag/shared/theme/vrijdag_tokens.dart';

/// Spoken-form date header (F-007 / task-02-measurements).
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
      padding: const EdgeInsets.fromLTRB(
        VrijdagSpacing.page,
        VrijdagSpacing.page,
        VrijdagSpacing.page,
        VrijdagSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            weekdayLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              color: colors.warmGrey,
            ),
          ),
          const SizedBox(height: VrijdagSpacing.xxs),
          Text(
            dateLabel,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 29,
              height: 1.1,
              fontWeight: FontWeight.w500,
              color: colors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
