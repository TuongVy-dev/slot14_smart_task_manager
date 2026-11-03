import 'package:drift/drift.dart';

class Tasks extends Table {
  TextColumn get id => text()(); // primary key dạng text
  TextColumn get title => text()();

  /// bool trong drift có thể dùng boolean()
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();

  /// thời gian tạo (millisecondsSinceEpoch)
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
