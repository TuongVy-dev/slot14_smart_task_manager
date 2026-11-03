import 'package:hive_flutter/hive_flutter.dart';

import '../models/task.dart';

class HiveService {
  static const String boxName = 'taskBox';
  static const String keyTaskList = 'task_list';

  Box get _box => Hive.box(boxName);

  /// Load danh sách Task từ Hive
  List<Task> loadTasks() {
    final raw = _box.get(keyTaskList);

    if (raw == null) return [];

    // raw kỳ vọng là List<Map>
    final List list = raw as List;
    return list.map((e) => Task.fromMap(e as Map)).toList();
  }

  /// Save danh sách Task xuống Hive
  Future<void> saveTasks(List<Task> tasks) async {
    final listMap = tasks.map((t) => t.toMap()).toList();
    await _box.put(keyTaskList, listMap);
  }

  Future<void> clearTasks() async {
    await _box.delete(keyTaskList);
  }
}
