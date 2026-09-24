import 'package:vrijdag/features/calendar/domain/personal_event.dart';
import 'package:vrijdag/features/calendar/domain/recurrence_materializer.dart';

/// Title and notes only. A repeating event is one row: the next occurrence.
List<PersonalEvent> searchPersonalEvents({
  required List<PersonalEvent> masters,
  required String query,
  required DateTime now,
}) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) {
    return const [];
  }

  final hits = masters.where((event) {
    if (event.isDeleted) {
      return false;
    }
    final title = event.title.toLowerCase();
    final notes = event.notes?.toLowerCase() ?? '';
    return title.contains(needle) || notes.contains(needle);
  }).toList();

  final from = DateTime(now.year, now.month, now.day);
  final upcoming = RecurrenceMaterializer.materialize(
    hits.where((event) => event.isRecurring).toList(),
    from: from,
    to: from.add(const Duration(days: 400)),
  );

  final nextByMaster = <String, PersonalEvent>{};
  for (final occurrence in upcoming) {
    final id = occurrence.seriesMaster?.id ?? occurrence.id;
    final existing = nextByMaster[id];
    final start = occurrence.timed?.startsAt ?? occurrence.allDay!.startDate;
    final existingStart =
        existing?.timed?.startsAt ?? existing?.allDay?.startDate;
    if (existing == null ||
        (existingStart != null && start.isBefore(existingStart))) {
      nextByMaster[id] = occurrence;
    }
  }

  final results = <PersonalEvent>[];
  for (final event in hits) {
    if (event.isRecurring) {
      results.add(nextByMaster[event.id] ?? event);
    } else {
      results.add(event);
    }
  }
  results.sort((a, b) {
    final aStart = a.timed?.startsAt ?? a.allDay!.startDate;
    final bStart = b.timed?.startsAt ?? b.allDay!.startDate;
    return aStart.compareTo(bStart);
  });
  return results;
}
