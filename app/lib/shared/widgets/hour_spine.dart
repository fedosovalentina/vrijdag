import 'package:flutter/material.dart';
import 'package:vrijdag/shared/widgets/event_row.dart';

/// Quiet-day hour marks (Task 02). Numerals, not copy.
class HourSpine extends StatelessWidget {
  const HourSpine({
    super.key,
    this.hours = const [8, 12, 18],
    this.faded = true,
    this.onHourTap,
  });

  final List<int> hours;
  final bool faded;
  final ValueChanged<int>? onHourTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: faded ? 0.35 : 1,
      child: Column(
        children: [
          for (final hour in hours)
            EventRow(
              timeLabel: hour.toString().padLeft(2, '0'),
              title: '',
              kind: EventMarkerKind.emptyHour,
              onTap: onHourTap == null ? null : () => onHourTap!(hour),
            ),
        ],
      ),
    );
  }
}
