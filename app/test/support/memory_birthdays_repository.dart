import 'package:vrijdag/features/birthdays/domain/birthday.dart';
import 'package:vrijdag/features/birthdays/domain/birthdays_repository.dart';

class MemoryBirthdaysRepository implements BirthdaysRepository {
  final _items = <String, Birthday>{};

  @override
  Future<List<Birthday>> listAll() async {
    return _items.values.where((b) => !b.isDeleted).toList()..sort((a, b) {
      final byMonth = a.month.compareTo(b.month);
      return byMonth != 0 ? byMonth : a.day.compareTo(b.day);
    });
  }

  @override
  Future<Birthday> create({
    required String name,
    required int month,
    required int day,
    int? year,
    String? notes,
  }) async {
    final now = DateTime.now().toUtc();
    final birthday = Birthday(
      id: 'b-${_items.length + 1}',
      userId: 'user',
      name: name,
      month: month,
      day: day,
      year: year,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
    birthday.validate();
    _items[birthday.id] = birthday;
    return birthday;
  }

  @override
  Future<Birthday> update(Birthday birthday) async {
    birthday.validate();
    _items[birthday.id] = birthday;
    return birthday;
  }

  @override
  Future<void> softDelete(String id) async {
    final existing = _items[id];
    if (existing == null) {
      return;
    }
    _items[id] = Birthday(
      id: existing.id,
      userId: existing.userId,
      name: existing.name,
      month: existing.month,
      day: existing.day,
      year: existing.year,
      notes: existing.notes,
      deletedAt: DateTime.now().toUtc(),
      createdAt: existing.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
  }
}
