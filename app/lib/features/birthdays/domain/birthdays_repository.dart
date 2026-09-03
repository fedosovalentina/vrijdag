import 'package:vrijdag/features/birthdays/domain/birthday.dart';

abstract class BirthdaysRepository {
  Future<List<Birthday>> listAll();

  Future<Birthday> create({
    required String name,
    required int month,
    required int day,
    int? year,
    String? notes,
  });

  Future<Birthday> update(Birthday birthday);

  Future<void> softDelete(String id);
}
