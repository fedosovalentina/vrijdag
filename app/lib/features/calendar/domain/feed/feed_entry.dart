import 'package:vrijdag/features/calendar/domain/personal_event.dart';
import 'package:vrijdag/features/calendar/domain/recurrence_materializer.dart';
import 'package:vrijdag/features/calendar/domain/recurrence_rule.dart';

/// One occurrence on the feed. [frequency] survives materialization, which
/// clears the rule on the event itself.
class FeedEntry {
  const FeedEntry({required this.event, this.frequency});

  final PersonalEvent event;
  final RecurrenceFrequency? frequency;
}

List<FeedEntry> projectFeedEntries(
  List<PersonalEvent> masters, {
  required DateTime from,
  required DateTime to,
}) {
  final out = <FeedEntry>[];
  for (final master in masters) {
    final frequency = master.recurrenceRule?.frequency;
    final occurrences = RecurrenceMaterializer.materialize(
      [master],
      from: from,
      to: to,
    );
    for (final event in occurrences) {
      out.add(FeedEntry(event: event, frequency: frequency));
    }
  }
  return out;
}
