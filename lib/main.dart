import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'part1_shared_prefs/screens/home_screen.dart' as part1;
import 'part2_sqlite/screens/home_screen.dart' as part2;
import 'part3_hive/screens/home_screen.dart' as part3;
import 'part4_drift/screens/home_screen.dart' as part4;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // sqflite chỉ chạy sẵn trên Android/iOS/macOS; Windows/Linux cần bản FFI
  if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Phần 3: bắt buộc init Hive + mở box trước khi dùng
  await Hive.initFlutter();
  await Hive.openBox('taskBox');

  runApp(const SmartTaskManagerApp());
}

class SmartTaskManagerApp extends StatelessWidget {
  const SmartTaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Task Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MenuScreen(),
    );
  }
}

/// Chọn 1 trong 4 phần của bài tập tổng hợp Slot 14
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final parts = <(String, String, Widget Function())>[
      ('Phần 1 – SharedPreferences', 'Lưu cả list dạng JSON string',
          () => const part1.HomeScreen()),
      ('Phần 2 – SQLite (sqflite)', 'Mỗi task là 1 row trong bảng tasks',
          () => const part2.HomeScreen()),
      ('Phần 3 – Hive', 'Lưu List<Map> vào box taskBox',
          () => const part3.HomeScreen()),
      ('Phần 4 – Drift', 'SQLite ORM, code sinh bằng build_runner',
          () => const part4.HomeScreen()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Smart Task Manager (Offline-first)')),
      body: ListView(
        children: [
          for (final (title, subtitle, builder) in parts)
            ListTile(
              title: Text(title),
              subtitle: Text(subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => builder()),
              ),
            ),
        ],
      ),
    );
  }
}
