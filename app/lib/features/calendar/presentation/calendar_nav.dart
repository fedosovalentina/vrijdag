import 'package:flutter/material.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/shared/theme/vrijdag_theme.dart';
import 'package:vrijdag/shared/theme/vrijdag_tokens.dart';

/// Utility chrome only: today date + Nieuw / Instellingen (DEC-031).
///
/// Scale jump and zoom strips are gone — shells move by horizontal swipe.
class CalendarChrome extends StatelessWidget {
  const CalendarChrome({
    super.key,
    required this.onToday,
    required this.todayLabel,
    required this.onTodayActive,
    required this.onNew,
    required this.onSettings,
  });

  final VoidCallback onToday;
  final String todayLabel;
  final bool onTodayActive;
  final VoidCallback onNew;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).vrijdagColors;
    final labelStyle = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w500);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.hair)),
      ),
      child: SizedBox(
        height: 44,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: VrijdagSpacing.sm),
          child: Row(
            children: [
              TextButton(
                onPressed: onToday,
                style: TextButton.styleFrom(
                  foregroundColor: onTodayActive ? colors.ink : colors.inkSoft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(44, 44),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Semantics(
                  button: true,
                  label: context.l10n.chromeBackToToday,
                  child: Text(
                    todayLabel,
                    style: labelStyle?.copyWith(
                      color: onTodayActive ? colors.ink : colors.inkSoft,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onNew,
                style: TextButton.styleFrom(
                  foregroundColor: colors.ink,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(44, 44),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  context.l10n.chromeNew,
                  style: labelStyle?.copyWith(color: colors.ink),
                ),
              ),
              const SizedBox(width: VrijdagSpacing.xs),
              TextButton(
                onPressed: onSettings,
                style: TextButton.styleFrom(
                  foregroundColor: colors.inkSoft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(44, 44),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  context.l10n.chromeSettings,
                  style: labelStyle?.copyWith(color: colors.inkSoft),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
