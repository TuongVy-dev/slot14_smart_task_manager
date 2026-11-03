import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:slot14_smart_task_manager/part1_shared_prefs/models/task.dart'
    as p1;
import 'package:slot14_smart_task_manager/part1_shared_prefs/screens/home_screen.dart'
    as p1;
import 'package:slot14_smart_task_manager/part1_shared_prefs/services/preferences_service.dart';
import 'package:slot14_smart_task_manager/part2_sqlite/models/task.dart' as p2;
import 'package:slot14_smart_task_manager/part2_sqlite/repositories/task_repository.dart';
import 'package:slot14_smart_task_manager/part3_hive/models/task.dart' as p3;
import 'package:slot14_smart_task_manager/part3_hive/services/hive_service.dart';
import 'package:slot14_smart_task_manager/part4_drift/db/app_database.dart';
import 'package:slot14_smart_task_manager/part4_drift/repositories/task_dao.dart';

void main() {
  group('Phần 1 – SharedPreferences', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('save → load giữ nguyên title và isDone', () async {
      final service = PreferencesService();
      await service.saveTasks([
        p1.Task(id: '1', title: 'A'),
        p1.Task(id: '2', title: 'B', isDone: true),
      ]);
      final loaded = await service.loadTasks();
      expect(loaded.map((t) => t.title), ['A', 'B']);
      expect(loaded[1].isDone, isTrue);
    });

    testWidgets('thêm task trên UI → được lưu xuống storage', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: p1.HomeScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Chưa có task nào.'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Học Flutter');
      await tester.tap(find.text('Thêm'));
      await tester.pumpAndSettle();

      expect(find.text('Học Flutter'), findsOneWidget);
      final saved = await PreferencesService().loadTasks();
      expect(saved.single.title, 'Học Flutter');
    });
  });

  group('Phần 2 – SQLite', () {
    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    test('insert / update / delete', () async {
      final repo = TaskRepository();
      await repo.deleteAll();

      await repo.insertTask(p2.Task(id: 'a', title: 'Cũ', createdAt: 1));
      await repo.insertTask(p2.Task(id: 'b', title: 'Mới', createdAt: 2));
      var all = await repo.getAllTasks();
      expect(all.map((t) => t.id), ['b', 'a']); // created_at DESC

      final a = all.last
        ..isDone = true
        ..title = 'Đã sửa';
      await repo.updateTask(a);
      all = await repo.getAllTasks();
      expect(all.last.title, 'Đã sửa');
      expect(all.last.isDone, isTrue); // INTEGER 1 → true

      await repo.deleteTask('b');
      expect((await repo.getAllTasks()).single.id, 'a');
      await repo.deleteAll();
    });
  });

  group('Phần 3 – Hive', () {
    late Directory dir;

    setUpAll(() async {
      dir = await Directory.systemTemp.createTemp('hive_test');
      Hive.init(dir.path); // test không có path_provider nên dùng init(path)
      await Hive.openBox(HiveService.boxName);
    });

    tearDownAll(() async {
      await Hive.close();
      await dir.delete(recursive: true);
    });

    test('save → load → clear', () async {
      final service = HiveService();
      expect(service.loadTasks(), isEmpty);

      await service.saveTasks([
        p3.Task(id: '1', title: 'Hive', isDone: true, createdAt: 5),
      ]);
      final loaded = service.loadTasks().single;
      expect(loaded.title, 'Hive');
      expect(loaded.isDone, isTrue);
      expect(loaded.createdAt, 5);

      await service.clearTasks();
      expect(service.loadTasks(), isEmpty);
    });
  });

  group('Phần 4 – Drift', () {
    late AppDatabase db;
    late TaskDao dao;

    setUp(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      db = AppDatabase.forTesting(NativeDatabase.memory());
      dao = TaskDao(db);
    });

    tearDown(() => db.close());

    test('CRUD + watch() phát dữ liệu mới khi DB đổi', () async {
      final emissions = <List<String>>[];
      final sub = dao
          .watchAllTasks()
          .listen((tasks) => emissions.add(tasks.map((t) => t.title).toList()));

      await dao.insertTask(id: '1', title: 'Một', createdAt: 1);
      await dao.insertTask(id: '2', title: 'Hai', createdAt: 2);

      var all = await dao.getAllTasks();
      expect(all.map((t) => t.title), ['Hai', 'Một']);
      expect(all.first.isDone, isFalse); // giá trị default

      await dao.toggleDone(all.first);
      await dao.updateTitle(id: '1', newTitle: 'Một (sửa)');
      all = await dao.getAllTasks();
      expect(all.first.isDone, isTrue);
      expect(all.last.title, 'Một (sửa)');

      await dao.deleteTask('2');
      expect((await dao.getAllTasks()).single.id, '1');

      await pumpEventQueue();
      expect(emissions.last, ['Một (sửa)']);
      await sub.cancel();
    });
  });
}
