import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/features/birthdays/data/supabase_birthdays_repository.dart';
import 'package:vrijdag/features/birthdays/domain/birthday.dart';
import 'package:vrijdag/features/birthdays/domain/birthdays_repository.dart';

final birthdaysRepositoryProvider = Provider<BirthdaysRepository>((ref) {
  return SupabaseBirthdaysRepository();
});

final birthdaysListProvider = FutureProvider.autoDispose<List<Birthday>>((ref) {
  return ref.watch(birthdaysRepositoryProvider).listAll();
});
