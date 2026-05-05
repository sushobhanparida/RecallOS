import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task_model.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _channelId = 'recall_task_reminders';
  static const _channelName = 'Task Reminders';

  Future<void> init() async {
    if (_ready) return;

    tz.initializeTimeZones();

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();

    _ready = true;
  }

  Future<void> scheduleReminder(Task task) async {
    if (task.id == null) return;

    // Always cancel any existing reminder first to avoid duplicates.
    await cancelReminder(task.id!);

    if (task.notifyOption == NotifyOption.none) return;
    if (task.dueDate == null) return;
    if (task.isCompleted) return;

    final fireAt = _fireTime(task.dueDate!, task.notifyOption);
    if (fireAt == null || !fireAt.isAfter(DateTime.now())) return;

    await _plugin.zonedSchedule(
      task.id!,
      task.title,
      _body(task),
      tz.TZDateTime.from(fireAt, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Reminders for your tasks and events',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelReminder(int taskId) async {
    await _plugin.cancel(taskId);
  }

  DateTime? _fireTime(DateTime due, NotifyOption option) {
    switch (option) {
      case NotifyOption.none:
        return null;
      case NotifyOption.onTheDay:
        return DateTime(due.year, due.month, due.day, 9, 0);
      case NotifyOption.nightBefore:
        final prev = due.subtract(const Duration(days: 1));
        return DateTime(prev.year, prev.month, prev.day, 21, 0);
      case NotifyOption.oneHourBefore:
        return due.subtract(const Duration(hours: 1));
      case NotifyOption.thirtyMinBefore:
        return due.subtract(const Duration(minutes: 30));
    }
  }

  String _body(Task task) {
    final parts = <String>[];
    if (task.intent.label.isNotEmpty) parts.add(task.intent.label);
    if (task.dueDate != null) {
      parts.add(DateFormat('MMM d · HH:mm').format(task.dueDate!));
    }
    return parts.isEmpty ? 'Reminder' : parts.join(' · ');
  }
}
