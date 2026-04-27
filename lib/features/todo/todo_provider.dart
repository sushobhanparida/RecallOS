import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/models/todo_model.dart';

class TodoState {
  final List<Todo> todos;
  final bool isLoading;

  const TodoState({this.todos = const [], this.isLoading = false});

  List<Todo> get morning =>
      todos.where((t) => t.category == TodoCategory.morning).toList();
  List<Todo> get afternoon =>
      todos.where((t) => t.category == TodoCategory.afternoon).toList();
  List<Todo> get anytime =>
      todos.where((t) => t.category == TodoCategory.anytime).toList();
  List<Todo> get events =>
      todos.where((t) => t.category == TodoCategory.event).toList();

  TodoState copyWith({List<Todo>? todos, bool? isLoading}) => TodoState(
        todos: todos ?? this.todos,
        isLoading: isLoading ?? this.isLoading,
      );
}

class TodoNotifier extends StateNotifier<TodoState> {
  final AppDatabase _db;

  TodoNotifier(this._db) : super(const TodoState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final todos = await _db.getTodos();
    state = TodoState(todos: todos);
  }

  Future<void> addTodo(Todo todo) async {
    await _db.insertTodo(todo);
    await load();
  }

  Future<void> toggleComplete(Todo todo) async {
    final updated = todo.copyWith(isCompleted: !todo.isCompleted);
    await _db.updateTodo(updated);
    await load();
  }

  Future<void> deleteTodo(int id) async {
    await _db.deleteTodo(id);
    await load();
  }

  Future<void> updateTodo(Todo todo) async {
    await _db.updateTodo(todo);
    await load();
  }
}

final todoProvider = StateNotifierProvider<TodoNotifier, TodoState>((ref) {
  return TodoNotifier(AppDatabase.instance);
});
