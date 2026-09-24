import 'package:vrijdag/features/calendar/domain/personal_event.dart';

/// Sentence for the system sheet. Title and time only, no notes, no link.
String eventShareText(
  PersonalEvent event, {
  required String allDayLabel,
  required String untitled,
}) {
  final title = event.title.trim().isEmpty ? untitled : event.title.trim();
  if (event.isAllDay) {
    final start = _date(event.allDay!.startDate);
    final end = _date(event.allDay!.endDate);
    final when = start == end ? start : '$start – $end';
    return '$title\n$when\n$allDayLabel';
  }
  final start = event.timed!.startsAt.toLocal();
  final end = event.timed!.endsAt.toLocal();
  return '$title\n${_date(start)} ${_clock(start)}–${_clock(end)}';
}

/// One VEVENT. A repeating event keeps its rule. No URL.
String eventToIcs(PersonalEvent event) {
  final rule = event.seriesMaster?.recurrenceRule ?? event.recurrenceRule;
  final title = _escape(
    event.title.trim().isEmpty ? 'Untitled' : event.title.trim(),
  );
  final buffer = StringBuffer()
    ..writeln('BEGIN:VCALENDAR')
    ..writeln('VERSION:2.0')
    ..writeln('PRODID:-//Vrijdag//EN')
    ..writeln('BEGIN:VEVENT')
    ..writeln('UID:${event.seriesMaster?.id ?? event.id}@vrijdag')
    ..writeln('SUMMARY:$title');
  if (event.isAllDay) {
    buffer
      ..writeln('DTSTART;VALUE=DATE:${_icsDate(event.allDay!.startDate)}')
      ..writeln(
        'DTEND;VALUE=DATE:${_icsDate(event.allDay!.endDate.add(const Duration(days: 1)))}',
      );
  } else {
    buffer
      ..writeln('DTSTART:${_icsInstant(event.timed!.startsAt)}')
      ..writeln('DTEND:${_icsInstant(event.timed!.endsAt)}');
  }
  if (rule != null) {
    buffer.writeln('RRULE:${rule.toRrule()}');
  }
  buffer
    ..writeln('END:VEVENT')
    ..writeln('END:VCALENDAR');
  return buffer.toString();
}

String _date(DateTime value) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${value.year}-${two(value.month)}-${two(value.day)}';
}

String _clock(DateTime value) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(value.hour)}:${two(value.minute)}';
}

String _icsDate(DateTime value) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${value.year}${two(value.month)}${two(value.day)}';
}

String _icsInstant(DateTime value) {
  final utc = value.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${utc.year}${two(utc.month)}${two(utc.day)}T${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z';
}

String _escape(String value) {
  return value
      .replaceAll('\\', '\\\\')
      .replaceAll('\n', '\\n')
      .replaceAll(',', '\\,')
      .replaceAll(';', '\\;');
}
