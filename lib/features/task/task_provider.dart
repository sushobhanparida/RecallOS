import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/models/task_model.dart';

class TaskState {
  final List<Task> tasks;
  final bool isLoading;

  const TaskState({this.tasks = const [], this.isLoading = false});

  List<Task> get eventTasks =>
      tasks.where((t) => t.intent == TaskIntent.event).toList();
  List<Task> get simpleTasks =>
      tasks.where((t) => t.intent != TaskIntent.event).toList();

  TaskState copyWith({List<Task>? tasks, bool? isLoading}) => TaskState(
        tasks: tasks ?? this.tasks,
        isLoading: isLoading ?? this.isLoading,
      );
}

class TaskNotifier extends StateNotifier<TaskState> {
  final AppDatabase _db;

  TaskNotifier(this._db) : super(const TaskState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final tasks = await _db.getTasks();
    state = TaskState(tasks: tasks);
  }

  Future<void> addTask(Task task) async {
    await _db.insertTask(task);
    await load();
  }

  Future<void> toggleComplete(Task task) async {
    final updated = task.copyWith(isCompleted: !task.isCompleted);
    await _db.updateTask(updated);
    await load();
  }

  Future<void> deleteTask(int id) async {
    await _db.deleteTask(id);
    await load();
  }

  Future<void> updateTask(Task task) async {
    await _db.updateTask(task);
    await load();
  }
}

final taskProvider = StateNotifierProvider<TaskNotifier, TaskState>((ref) {
  return TaskNotifier(AppDatabase.instance);
});
