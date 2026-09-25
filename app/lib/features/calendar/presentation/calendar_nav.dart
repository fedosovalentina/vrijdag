import 'package:flutter/material.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/shared/theme/vrijdag_theme.dart';
import 'package:vrijdag/shared/theme/vrijdag_tokens.dart';

/// Utility chrome only: today circle + Nieuw / Instellingen (DEC-031).
///
/// Scale jump and zoom strips are gone — shells move by horizontal swipe.
class CalendarChrome extends StatelessWidget {
  const CalendarChrome({
    super.key,
    required this.onToday,
    required this.todayDayOfMonth,
    required this.onTodayActive,
    required this.onNew,
    required this.onSettings,
  });

  final VoidCallback onToday;
  final int todayDayOfMonth;
  final bool onTodayActive;
  final VoidCallback onNew;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).vrijdagColors;
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
              _TodayCircle(
                dayOfMonth: todayDayOfMonth,
                active: onTodayActive,
                onTap: onToday,
                semanticLabel: context.l10n.chromeBackToToday,
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
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colors.ink,
                  ),
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
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colors.inkSoft,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayCircle extends StatelessWidget {
  const _TodayCircle({
    required this.dayOfMonth,
    required this.active,
    required this.onTap,
    required this.semanticLabel,
  });

  final int dayOfMonth;
  final bool active;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).vrijdagColors;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? colors.ink : colors.paper,
                border: Border.all(color: colors.ink, width: 1.5),
              ),
              child: Text(
                '$dayOfMonth',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: active ? colors.paper : colors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
