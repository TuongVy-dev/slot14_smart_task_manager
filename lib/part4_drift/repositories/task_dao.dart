import 'package:drift/drift.dart';

import '../db/app_database.dart';

class TaskDao {
  final AppDatabase db;
  TaskDao(this.db);

  // CREATE
  Future<void> insertTask({
    required String id,
    required String title,
    required int createdAt,
  }) async {
    await db.into(db.tasks).insert(
          TasksCompanion.insert(
            id: id,
            title: title,
            createdAt: createdAt,
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  // READ (all)
  Future<List<Task>> getAllTasks() {
    return (db.select(db.tasks)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  // UPDATE (toggle done)
  Future<void> toggleDone(Task task) async {
    await (db.update(db.tasks)..where((t) => t.id.equals(task.id))).write(
      TasksCompanion(
        isDone: Value(!task.isDone),
      ),
    );
  }

  // UPDATE (edit title)
  Future<void> updateTitle({
    required String id,
    required String newTitle,
  }) async {
    await (db.update(db.tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        title: Value(newTitle),
      ),
    );
  }

  // DELETE
  Future<void> deleteTask(String id) async {
    await (db.delete(db.tasks)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteAll() async {
    await db.delete(db.tasks).go();
  }

  // (Tuỳ chọn) WATCH: UI tự cập nhật khi DB đổi
  Stream<List<Task>> watchAllTasks() {
    return (db.select(db.tasks)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }
}
