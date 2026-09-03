import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/core/database/app_database.dart';
import 'package:vrijdag/core/database/drift_write_queue.dart';
import 'package:vrijdag/core/database/write_queue.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final writeQueueProvider = Provider<WriteQueue>((ref) {
  return DriftWriteQueue(ref.watch(appDatabaseProvider));
});
