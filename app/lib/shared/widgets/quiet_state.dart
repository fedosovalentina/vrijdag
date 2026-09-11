import 'package:flutter/material.dart';
import 'package:vrijdag/shared/theme/vrijdag_theme.dart';
import 'package:vrijdag/shared/theme/vrijdag_tokens.dart';

/// Deliberate empty / quiet copy (Principle 5 / task-02-measurements).
class QuietState extends StatelessWidget {
  const QuietState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).vrijdagColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VrijdagSpacing.page,
        24,
        VrijdagSpacing.page,
        VrijdagSpacing.sm,
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontSize: 15, color: colors.inkSoft),
      ),
    );
  }
}
