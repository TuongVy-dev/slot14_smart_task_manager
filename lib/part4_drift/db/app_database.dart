import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Tasks])
class AppDatabase extends _$AppDatabase {
  // driftDatabase() tự chọn thư mục lưu file trên Android/iOS/Windows
  AppDatabase() : super(driftDatabase(name: 'smart_task_manager_drift'));

  /// Dùng cho test với database trong RAM
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;
}
