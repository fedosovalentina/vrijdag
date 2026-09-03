import 'package:flutter/material.dart';
import 'package:vrijdag/shared/theme/vrijdag_tokens.dart';
import 'package:vrijdag/shared/theme/vrijdag_theme.dart';

/// Explains a permission before the OS prompt (F-094).
class PermissionExplainer extends StatelessWidget {
  const PermissionExplainer({
    super.key,
    required this.body,
    required this.actionLabel,
    required this.onContinue,
    this.onNotNow,
    this.notNowLabel,
  });

  final String body;
  final String actionLabel;
  final VoidCallback onContinue;
  final VoidCallback? onNotNow;
  final String? notNowLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).vrijdagColors;
    return Padding(
      padding: const EdgeInsets.all(VrijdagSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            body,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
          ),
          const SizedBox(height: VrijdagSpacing.md),
          FilledButton(onPressed: onContinue, child: Text(actionLabel)),
          if (onNotNow != null && notNowLabel != null)
            TextButton(onPressed: onNotNow, child: Text(notNowLabel!)),
        ],
      ),
    );
  }
}
