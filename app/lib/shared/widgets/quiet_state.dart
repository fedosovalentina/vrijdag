import 'package:flutter/material.dart';
import 'package:vrijdag/shared/theme/vrijdag_tokens.dart';
import 'package:vrijdag/shared/theme/vrijdag_theme.dart';

/// Deliberate empty / quiet day copy (Principle 5).
class QuietState extends StatelessWidget {
  const QuietState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).vrijdagColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VrijdagSpacing.lg),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
      ),
    );
  }
}
