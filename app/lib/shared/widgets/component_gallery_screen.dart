import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/shared/theme/vrijdag_theme.dart';
import 'package:vrijdag/shared/widgets/date_header.dart';
import 'package:vrijdag/shared/widgets/event_row.dart';
import 'package:vrijdag/shared/widgets/quiet_state.dart';
import 'package:vrijdag/shared/widgets/stale_badge.dart';
import 'package:vrijdag/shared/widgets/sync_pending_banner.dart';

/// Debug-only gallery for F-094 components (both themes).
class ComponentGalleryScreen extends StatelessWidget {
  const ComponentGalleryScreen({super.key});

  static bool get isAvailable => kDebugMode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.designGalleryTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.designGalleryLight),
              Tab(text: l10n.designGalleryDark),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Theme(data: buildVrijdagTheme(), child: const _GalleryBody()),
            Theme(
              data: buildVrijdagTheme(brightness: Brightness.dark),
              child: const _GalleryBody(),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryBody extends StatelessWidget {
  const _GalleryBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          DateHeader(
            weekdayLabel: l10n.designGalleryWeekdaySample,
            dateLabel: l10n.designGalleryDateSample,
          ),
          AllDayMarker(
            label: l10n.calendarAllDay,
            title: l10n.birthdaySampleName,
          ),
          EventRow(
            timeLabel: '09:00',
            title: l10n.designGalleryEventTitle,
            subtitle: l10n.designGalleryEventMeta,
          ),
          EventRow(
            timeLabel: '12:00',
            title: l10n.designGalleryOpeningTitle,
            kind: EventMarkerKind.opening,
          ),
          EventRow(
            title: l10n.birthdaySampleName,
            kind: EventMarkerKind.birthday,
          ),
          QuietState(message: l10n.calendarEmptyToday),
          StaleBadge(label: l10n.designGalleryStaleSample),
          const SizedBox(height: 16),
          const SyncPendingBanner(),
        ],
      ),
    );
  }
}
