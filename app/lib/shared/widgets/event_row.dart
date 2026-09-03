import 'package:flutter/material.dart';
import 'package:vrijdag/shared/theme/vrijdag_tokens.dart';
import 'package:vrijdag/shared/theme/vrijdag_theme.dart';

enum EventMarkerKind { timed, allDay, birthday, opening }

/// Single calendar row with shape marker (DEC-024).
class EventRow extends StatelessWidget {
  const EventRow({
    super.key,
    required this.title,
    this.timeLabel,
    this.subtitle,
    this.kind = EventMarkerKind.timed,
    this.onTap,
  });

  final String title;
  final String? timeLabel;
  final String? subtitle;
  final EventMarkerKind kind;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.vrijdagColors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: VrijdagSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 52,
              child: timeLabel == null
                  ? null
                  : Text(
                      timeLabel!,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: colors.warmGrey,
                      ),
                    ),
            ),
            const SizedBox(width: VrijdagSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _Marker(kind: kind, colors: colors),
            ),
            const SizedBox(width: VrijdagSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.ink,
                    ),
                  ),
                  if (subtitle != null)
                    Text(subtitle!, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({required this.kind, required this.colors});

  final EventMarkerKind kind;
  final VrijdagColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return switch (kind) {
      EventMarkerKind.timed => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: colors.ink, shape: BoxShape.circle),
      ),
      EventMarkerKind.allDay => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: colors.dust, shape: BoxShape.circle),
      ),
      EventMarkerKind.birthday => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colors.rust, width: 2),
        ),
      ),
      EventMarkerKind.opening => Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colors.moss, width: 1.5),
        ),
      ),
    };
  }
}
