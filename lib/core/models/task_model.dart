enum TaskIntent { task, event, visitLater, payLater, readLater, buyLater }

extension TaskIntentExt on TaskIntent {
  String get label {
    switch (this) {
      case TaskIntent.task:
        return '';
      case TaskIntent.event:
        return 'Event';
      case TaskIntent.visitLater:
        return 'Visit later';
      case TaskIntent.payLater:
        return 'Pay later';
      case TaskIntent.readLater:
        return 'Read later';
      case TaskIntent.buyLater:
        return 'Buy later';
    }
  }

  String get dbValue {
    switch (this) {
      case TaskIntent.task:
        return 'task';
      case TaskIntent.event:
        return 'event';
      case TaskIntent.visitLater:
        return 'visit_later';
      case TaskIntent.payLater:
        return 'pay_later';
      case TaskIntent.readLater:
        return 'read_later';
      case TaskIntent.buyLater:
        return 'buy_later';
    }
  }

  static TaskIntent fromString(String s) {
    switch (s) {
      case 'event':
        return TaskIntent.event;
      case 'visit_later':
        return TaskIntent.visitLater;
      case 'pay_later':
        return TaskIntent.payLater;
      case 'read_later':
        return TaskIntent.readLater;
      case 'buy_later':
        return TaskIntent.buyLater;
      default:
        return TaskIntent.task;
    }
  }
}

enum NotifyOption { none, onTheDay, nightBefore, oneHourBefore, thirtyMinBefore }

extension NotifyOptionExt on NotifyOption {
  String get label {
    switch (this) {
      case NotifyOption.none:
        return 'None';
      case NotifyOption.onTheDay:
        return 'On the day';
      case NotifyOption.nightBefore:
        return 'Night before';
      case NotifyOption.oneHourBefore:
        return '1 hour before';
      case NotifyOption.thirtyMinBefore:
        return '30 min before';
    }
  }

  static NotifyOption fromString(String s) {
    switch (s) {
      case 'On the day':
        return NotifyOption.onTheDay;
      case 'Night before':
        return NotifyOption.nightBefore;
      case '1 hour before':
        return NotifyOption.oneHourBefore;
      case '30 min before':
        return NotifyOption.thirtyMinBefore;
      default:
        return NotifyOption.none;
    }
  }
}

class Task {
  final int? id;
  final int screenshotId;
  final String screenshotUri;
  final String title;
  final TaskIntent intent;
  final DateTime? dueDate;
  final bool isCompleted;
  final bool isReminded;
  final NotifyOption notifyOption;
  final DateTime createdAt;

  const Task({
    this.id,
    required this.screenshotId,
    required this.screenshotUri,
    required this.title,
    this.intent = TaskIntent.task,
    this.dueDate,
    this.isCompleted = false,
    this.isReminded = false,
    this.notifyOption = NotifyOption.none,
    required this.createdAt,
  });

  Task copyWith({
    int? id,
    int? screenshotId,
    String? screenshotUri,
    String? title,
    TaskIntent? intent,
    DateTime? dueDate,
    bool? isCompleted,
    bool? isReminded,
    NotifyOption? notifyOption,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      screenshotId: screenshotId ?? this.screenshotId,
      screenshotUri: screenshotUri ?? this.screenshotUri,
      title: title ?? this.title,
      intent: intent ?? this.intent,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      isReminded: isReminded ?? this.isReminded,
      notifyOption: notifyOption ?? this.notifyOption,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'screenshotId': screenshotId,
        'screenshotUri': screenshotUri,
        'title': title,
        'intent': intent.dbValue,
        'dueDate': dueDate?.millisecondsSinceEpoch,
        'isCompleted': isCompleted ? 1 : 0,
        'isReminded': isReminded ? 1 : 0,
        'notifyOption': notifyOption.label,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory Task.fromMap(Map<String, dynamic> map) => Task(
        id: map['id'] as int?,
        screenshotId: map['screenshotId'] as int,
        screenshotUri: map['screenshotUri'] as String,
        title: map['title'] as String,
        intent: TaskIntentExt.fromString(map['intent'] as String? ?? 'task'),
        dueDate: map['dueDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['dueDate'] as int)
            : null,
        isCompleted: (map['isCompleted'] as int) == 1,
        isReminded: (map['isReminded'] as int) == 1,
        notifyOption:
            NotifyOptionExt.fromString(map['notifyOption'] as String? ?? 'None'),
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      );
}
