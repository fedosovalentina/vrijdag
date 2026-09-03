/// Domain stub for birthday records (F-006).
class Birthday {
  const Birthday({
    required this.id,
    required this.userId,
    required this.name,
    required this.month,
    required this.day,
    this.year,
    this.notes,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final int month;
  final int day;
  final int? year;
  final String? notes;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isDeleted => deletedAt != null;

  /// Age in full years on [onDate] when [year] is known; otherwise null.
  int? ageOn(DateTime onDate) {
    final birthYear = year;
    if (birthYear == null) {
      return null;
    }
    var age = onDate.year - birthYear;
    final hadBirthday =
        onDate.month > month || (onDate.month == month && onDate.day >= day);
    if (!hadBirthday) {
      age -= 1;
    }
    return age < 0 ? null : age;
  }

  /// Display day for [year] honouring DEC-013 for 29 Feb.
  static DateTime occurrenceDate({
    required int year,
    required int month,
    required int day,
  }) {
    if (month == 2 && day == 29 && !_isLeap(year)) {
      return DateTime(year, 2, 28);
    }
    return DateTime(year, month, day);
  }

  void validate() {
    if (name.trim().isEmpty) {
      throw ArgumentError('name must not be empty');
    }
    if (month < 1 || month > 12) {
      throw ArgumentError('month out of range');
    }
    if (day < 1 || day > 31) {
      throw ArgumentError('day out of range');
    }
    if (year != null && year! < 1) {
      throw ArgumentError('year out of range');
    }
    // Reject impossible civil dates (except 29 Feb which is allowed as stored).
    if (!(month == 2 && day == 29)) {
      final probe = DateTime(2001, month, day);
      if (probe.month != month || probe.day != day) {
        throw ArgumentError('invalid month/day');
      }
    }
  }

  static bool _isLeap(int year) =>
      (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0));
}
