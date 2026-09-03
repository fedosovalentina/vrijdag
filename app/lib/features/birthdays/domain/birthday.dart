/// Domain stub for birthday records (F-006). Full UI comes later.
class Birthday {
  const Birthday({
    required this.id,
    required this.userId,
    required this.name,
    required this.month,
    required this.day,
    this.year,
    this.notes,
  });

  final String id;
  final String userId;
  final String name;
  final int month;
  final int day;
  final int? year;
  final String? notes;

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
  }
}

/// Placeholder repository until F-006 UI lands.
abstract class BirthdaysRepository {
  Future<List<Birthday>> listAll();
}
