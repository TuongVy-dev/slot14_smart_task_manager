import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/hive_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HiveService service = HiveService();
  final TextEditingController addController = TextEditingController();

  List<Task> tasks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    addController.dispose();
    super.dispose();
  }

  void _loadData() {
    // loadTasks() là sync (đọc local nhanh)
    final loaded = service.loadTasks();
    setState(() {
      tasks = loaded;
      isLoading = false;
    });
  }

  Future<void> _saveData() async {
    await service.saveTasks(tasks);
  }

  Future<void> _addTask() async {
    final title = addController.text.trim();
    if (title.isEmpty) return;

    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    setState(() {
      tasks.add(task);
      addController.clear();
    });

    await _saveData();
  }

  Future<void> _toggleDone(Task task) async {
    setState(() {
      task.isDone = !task.isDone;
    });
    await _saveData();
  }

  Future<void> _deleteTask(Task task) async {
    setState(() {
      tasks.removeWhere((t) => t.id == task.id);
    });
    await _saveData();
  }

  Future<void> _editTaskDialog(Task task) async {
    final controller = TextEditingController(text: task.title);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sửa task'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nhập tiêu đề mới',
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (result == null || !mounted) return;

    final newTitle = result.trim();
    if (newTitle.isEmpty) return;

    setState(() {
      task.title = newTitle;
    });
    await _saveData();
  }

  Future<void> _clearAllDialog() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tất cả?'),
        content:
            const Text('Bạn có chắc muốn xóa toàn bộ task không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Có'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    setState(() {
      tasks.clear();
    });
    await service.clearTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Task Manager (Hive)'),
        actions: [
          IconButton(
            onPressed: _clearAllDialog,
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Xóa tất cả',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: addController,
                          decoration: const InputDecoration(
                            labelText: 'Nhập task mới',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _addTask(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _addTask,
                        child: const Text('Thêm'),
                      )
                    ],
                  ),
                ),
                const Divider(height: 0),
                Expanded(
                  child: tasks.isEmpty
                      ? const Center(child: Text('Chưa có task nào.'))
                      : ListView.separated(
                          itemCount: tasks.length,
                          separatorBuilder: (_, _) => const Divider(height: 0),
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            return ListTile(
                              leading: Checkbox(
                                value: task.isDone,
                                onChanged: (_) => _toggleDone(task),
                              ),
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  decoration: task.isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              onTap: () => _editTaskDialog(task),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteTask(task),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
