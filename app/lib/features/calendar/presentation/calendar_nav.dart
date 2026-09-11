import 'package:flutter/material.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/features/calendar/domain/calendar_range.dart';
import 'package:vrijdag/shared/theme/vrijdag_theme.dart';
import 'package:vrijdag/shared/theme/vrijdag_tokens.dart';

class CalendarZoomItem {
  const CalendarZoomItem({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
}

/// Zoom strip + scale jump + Nieuw / Instellingen (Task 02 / DEC-025).
class CalendarNav extends StatelessWidget {
  const CalendarNav({
    super.key,
    required this.scale,
    required this.zoomItems,
    required this.zoomSemanticLabel,
    required this.onScaleSelected,
    required this.onNew,
    required this.onSettings,
  });

  final CalendarScale scale;
  final List<CalendarZoomItem> zoomItems;
  final String zoomSemanticLabel;
  final ValueChanged<CalendarScale> onScaleSelected;
  final VoidCallback onNew;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).vrijdagColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.hair)),
      ),
      child: Column(
        children: [
          if (zoomItems.isNotEmpty)
            Semantics(
              label: zoomSemanticLabel,
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    for (final item in zoomItems)
                      Expanded(
                        child: InkWell(
                          onTap: item.onTap,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: item.selected
                                  ? Border(
                                      bottom: BorderSide(
                                        color: colors.ink,
                                        width: 2,
                                      ),
                                    )
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                item.label,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontSize: 12,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                      fontWeight: item.selected
                                          ? FontWeight.w500
                                          : FontWeight.w400,
                                      color: item.selected
                                          ? colors.ink
                                          : colors.warmGrey,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.hair)),
            ),
            child: Semantics(
              label: context.l10n.navScaleJump,
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    _ScaleCell(
                      label: context.l10n.navDay,
                      selected: scale == CalendarScale.day,
                      onTap: () => onScaleSelected(CalendarScale.day),
                    ),
                    _ScaleCell(
                      label: context.l10n.navWeek,
                      selected: scale == CalendarScale.week,
                      onTap: () => onScaleSelected(CalendarScale.week),
                    ),
                    _ScaleCell(
                      label: context.l10n.navMonth,
                      selected: scale == CalendarScale.month,
                      onTap: () => onScaleSelected(CalendarScale.month),
                    ),
                    _ScaleCell(
                      label: context.l10n.navYear,
                      selected: scale == CalendarScale.year,
                      onTap: () => onScaleSelected(CalendarScale.year),
                    ),
                    _ScaleCell(label: context.l10n.navSeason, selected: false),
                  ],
                ),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.hair)),
            ),
            child: SizedBox(
              height: 44,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: VrijdagSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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
          ),
        ],
      ),
    );
  }
}

class _ScaleCell extends StatelessWidget {
  const _ScaleCell({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).vrijdagColors;
    final enabled = onTap != null;
    return Expanded(
      child: Material(
        color: selected ? colors.ink : colors.paper,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VrijdagSpacing.xxs,
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  height: 1.15,
                  fontWeight: FontWeight.w500,
                  color: !enabled
                      ? colors.warmGrey.withValues(alpha: 0.4)
                      : selected
                      ? colors.paper
                      : colors.warmGrey,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
