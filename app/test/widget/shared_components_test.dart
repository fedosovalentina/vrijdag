import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vrijdag/l10n/app_localizations.dart';
import 'package:vrijdag/shared/theme/vrijdag_theme.dart';
import 'package:vrijdag/shared/widgets/date_header.dart';
import 'package:vrijdag/shared/widgets/event_row.dart';
import 'package:vrijdag/shared/widgets/quiet_state.dart';

void main() {
  testWidgets('shared components render in light and dark themes', (
    tester,
  ) async {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('nl'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildVrijdagTheme(brightness: brightness),
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Scaffold(
                body: Column(
                  children: [
                    DateHeader(
                      weekdayLabel: l10n.designGalleryWeekdaySample,
                      dateLabel: l10n.designGalleryDateSample,
                    ),
                    EventRow(
                      timeLabel: '09:00',
                      title: l10n.designGalleryEventTitle,
                    ),
                    QuietState(message: l10n.calendarEmptyToday),
                  ],
                ),
              );
            },
          ),
        ),
      );
      expect(find.text('3 september'), findsOneWidget);
      expect(find.text('Werkoverleg'), findsOneWidget);
      expect(find.text('Geen afspraken vandaag.'), findsOneWidget);
    }
  });
}
