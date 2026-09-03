/// Minimal RRULE support for F-005 foundation (no expansion UI yet).
///
/// Accepts a subset of iCalendar RRULE: FREQ, INTERVAL, COUNT, UNTIL, BYDAY.
class RecurrenceRule {
  const RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.count,
    this.until,
    this.byDay = const [],
  });

  final RecurrenceFrequency frequency;
  final int interval;
  final int? count;
  final DateTime? until;
  final List<String> byDay;

  void validate() {
    if (interval < 1) {
      throw ArgumentError('interval must be >= 1');
    }
    if (count != null && count! < 1) {
      throw ArgumentError('count must be >= 1');
    }
    if (count != null && until != null) {
      throw ArgumentError('count and until are mutually exclusive');
    }
    for (final day in byDay) {
      if (!_validByDay.contains(day)) {
        throw ArgumentError('invalid BYDAY: $day');
      }
    }
  }

  /// Serialize to a compact RRULE string (no `RRULE:` prefix).
  String toRrule() {
    validate();
    final parts = <String>[
      'FREQ=${frequency.name.toUpperCase()}',
      if (interval != 1) 'INTERVAL=$interval',
      if (count != null) 'COUNT=$count',
      if (until != null) 'UNTIL=${_formatUntil(until!.toUtc())}',
      if (byDay.isNotEmpty) 'BYDAY=${byDay.join(',')}',
    ];
    return parts.join(';');
  }

  /// Parse a compact RRULE string (with or without `RRULE:` prefix).
  static RecurrenceRule parse(String raw) {
    final body = raw.trim().replaceFirst(
      RegExp(r'^RRULE:', caseSensitive: false),
      '',
    );
    if (body.isEmpty) {
      throw const FormatException('empty RRULE');
    }

    final map = <String, String>{};
    for (final part in body.split(';')) {
      final idx = part.indexOf('=');
      if (idx <= 0) {
        throw FormatException('malformed RRULE part: $part');
      }
      map[part.substring(0, idx).toUpperCase()] = part.substring(idx + 1);
    }

    final freqRaw = map['FREQ'];
    if (freqRaw == null) {
      throw const FormatException('FREQ is required');
    }
    final frequency = RecurrenceFrequency.values.firstWhere(
      (f) => f.name.toUpperCase() == freqRaw.toUpperCase(),
      orElse: () => throw FormatException('unsupported FREQ: $freqRaw'),
    );

    final interval = int.tryParse(map['INTERVAL'] ?? '1') ?? 1;
    final count = map.containsKey('COUNT') ? int.parse(map['COUNT']!) : null;
    final until = map.containsKey('UNTIL') ? _parseUntil(map['UNTIL']!) : null;
    final byDay = (map['BYDAY'] ?? '')
        .split(',')
        .map((s) => s.trim().toUpperCase())
        .where((s) => s.isNotEmpty)
        .toList();

    final rule = RecurrenceRule(
      frequency: frequency,
      interval: interval,
      count: count,
      until: until,
      byDay: byDay,
    );
    rule.validate();
    return rule;
  }

  static const _validByDay = {'MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'};

  static String _formatUntil(DateTime utc) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${utc.year}${two(utc.month)}${two(utc.day)}T'
        '${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z';
  }

  static DateTime _parseUntil(String raw) {
    // YYYYMMDDTHHMMSSZ
    if (raw.length >= 15 && raw.endsWith('Z')) {
      final y = int.parse(raw.substring(0, 4));
      final m = int.parse(raw.substring(4, 6));
      final d = int.parse(raw.substring(6, 8));
      final h = int.parse(raw.substring(9, 11));
      final min = int.parse(raw.substring(11, 13));
      final s = int.parse(raw.substring(13, 15));
      return DateTime.utc(y, m, d, h, min, s);
    }
    return DateTime.parse(raw).toUtc();
  }
}

enum RecurrenceFrequency { daily, weekly, monthly, yearly }
