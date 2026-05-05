import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/models/task_model.dart';
import '../../core/services/notification_service.dart';

class TaskState {
  final List<Task> tasks;
  final bool isLoading;

  const TaskState({this.tasks = const [], this.isLoading = false});

  List<Task> get activeTasks => tasks.where((t) => !t.isCompleted).toList();
  List<Task> get completedTasks => tasks.where((t) => t.isCompleted).toList();

  List<Task> get eventTasks =>
      activeTasks.where((t) => t.intent == TaskIntent.event).toList();

  List<Task> get todayTasks => _nonEventActive
      .where((t) => t.dueDate != null && _isOnDay(t.dueDate!, 0))
      .toList();

  List<Task> get tomorrowTasks => _nonEventActive
      .where((t) => t.dueDate != null && _isOnDay(t.dueDate!, 1))
      .toList();

  List<Task> get upcomingTasks => _nonEventActive.where((t) {
        if (t.dueDate == null) return false;
        final tomorrow = _dayStart(1);
        return t.dueDate!.isAfter(tomorrow.add(const Duration(days: 1) - const Duration(milliseconds: 1)));
      }).toList();

  List<Task> get somedayTasks =>
      _nonEventActive.where((t) => t.dueDate == null).toList();

  List<Task> get _nonEventActive =>
      activeTasks.where((t) => t.intent != TaskIntent.event).toList();

  static bool _isOnDay(DateTime dt, int dayOffset) {
    final target = _dayStart(dayOffset);
    return dt.year == target.year &&
        dt.month == target.month &&
        dt.day == target.day;
  }

  static DateTime _dayStart(int dayOffset) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + dayOffset);
  }

  TaskState copyWith({List<Task>? tasks, bool? isLoading}) => TaskState(
        tasks: tasks ?? this.tasks,
        isLoading: isLoading ?? this.isLoading,
      );
}

class TaskNotifier extends StateNotifier<TaskState> {
  final AppDatabase _db;
  final NotificationService _notif = NotificationService.instance;

  TaskNotifier(this._db) : super(const TaskState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final tasks = await _db.getTasks(includeCompleted: true);
    state = TaskState(tasks: tasks);
  }

  Future<void> addTask(Task task) async {
    final id = await _db.insertTask(task);
    final saved = task.copyWith(id: id);
    await _notif.scheduleReminder(saved);
    await load();
  }

  Future<void> toggleComplete(Task task) async {
    final updated = task.copyWith(isCompleted: !task.isCompleted);
    await _db.updateTask(updated);
    if (updated.isCompleted) {
      await _notif.cancelReminder(task.id!);
    } else {
      await _notif.scheduleReminder(updated);
    }
    await load();
  }

  Future<void> deleteTask(int id) async {
    await _notif.cancelReminder(id);
    await _db.deleteTask(id);
    await load();
  }

  Future<void> updateTask(Task task) async {
    await _db.updateTask(task);
    await _notif.scheduleReminder(task);
    await load();
  }
}

final taskProvider = StateNotifierProvider<TaskNotifier, TaskState>((ref) {
  return TaskNotifier(AppDatabase.instance);
});
