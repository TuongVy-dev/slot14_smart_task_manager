class Task {
  final String id;
  String title;
  bool isDone;
  final int createdAt;

  Task({
    required this.id,
    required this.title,
    this.isDone = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'isDone': isDone,
        'createdAt': createdAt,
      };

  factory Task.fromMap(Map map) => Task(
        id: map['id'] as String,
        title: map['title'] as String,
        isDone: (map['isDone'] as bool?) ?? false,
        createdAt: (map['createdAt'] as int?) ?? 0,
      );
}
