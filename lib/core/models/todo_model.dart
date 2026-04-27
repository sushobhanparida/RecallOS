enum TodoCategory { morning, afternoon, anytime, event }

enum TodoDuration { fiveMin, fifteenMin, thirtyMin, oneHour, twoHours }

enum NotifyOption { none, onTheDay, nightBefore, oneHourBefore, thirtyMinBefore }

extension TodoCategoryExt on TodoCategory {
  String get label {
    switch (this) {
      case TodoCategory.morning:
        return 'Morning';
      case TodoCategory.afternoon:
        return 'Afternoon';
      case TodoCategory.anytime:
        return 'Anytime';
      case TodoCategory.event:
        return 'Event';
    }
  }

  static TodoCategory fromString(String s) {
    switch (s.toLowerCase()) {
      case 'morning':
        return TodoCategory.morning;
      case 'afternoon':
        return TodoCategory.afternoon;
      case 'event':
        return TodoCategory.event;
      default:
        return TodoCategory.anytime;
    }
  }
}

extension TodoDurationExt on TodoDuration {
  String get label {
    switch (this) {
      case TodoDuration.fiveMin:
        return '5m';
      case TodoDuration.fifteenMin:
        return '15m';
      case TodoDuration.thirtyMin:
        return '30m';
      case TodoDuration.oneHour:
        return '1h';
      case TodoDuration.twoHours:
        return '2h';
    }
  }

  static TodoDuration fromString(String s) {
    switch (s) {
      case '5m':
        return TodoDuration.fiveMin;
      case '15m':
        return TodoDuration.fifteenMin;
      case '30m':
        return TodoDuration.thirtyMin;
      case '1h':
        return TodoDuration.oneHour;
      case '2h':
        return TodoDuration.twoHours;
      default:
        return TodoDuration.fifteenMin;
    }
  }
}

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

class Todo {
  final int? id;
  final int screenshotId;
  final String screenshotUri;
  final String title;
  final TodoCategory category;
  final DateTime? dueDate;
  final TodoDuration duration;
  final bool isCompleted;
  final bool isReminded;
  final bool isEvent;
  final NotifyOption notifyOption;
  final DateTime createdAt;

  const Todo({
    this.id,
    required this.screenshotId,
    required this.screenshotUri,
    required this.title,
    this.category = TodoCategory.anytime,
    this.dueDate,
    this.duration = TodoDuration.fifteenMin,
    this.isCompleted = false,
    this.isReminded = false,
    this.isEvent = false,
    this.notifyOption = NotifyOption.none,
    required this.createdAt,
  });

  Todo copyWith({
    int? id,
    int? screenshotId,
    String? screenshotUri,
    String? title,
    TodoCategory? category,
    DateTime? dueDate,
    TodoDuration? duration,
    bool? isCompleted,
    bool? isReminded,
    bool? isEvent,
    NotifyOption? notifyOption,
    DateTime? createdAt,
  }) {
    return Todo(
      id: id ?? this.id,
      screenshotId: screenshotId ?? this.screenshotId,
      screenshotUri: screenshotUri ?? this.screenshotUri,
      title: title ?? this.title,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      duration: duration ?? this.duration,
      isCompleted: isCompleted ?? this.isCompleted,
      isReminded: isReminded ?? this.isReminded,
      isEvent: isEvent ?? this.isEvent,
      notifyOption: notifyOption ?? this.notifyOption,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'screenshotId': screenshotId,
        'screenshotUri': screenshotUri,
        'title': title,
        'category': category.label,
        'dueDate': dueDate?.millisecondsSinceEpoch,
        'duration': duration.label,
        'isCompleted': isCompleted ? 1 : 0,
        'isReminded': isReminded ? 1 : 0,
        'isEvent': isEvent ? 1 : 0,
        'notifyOption': notifyOption.label,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory Todo.fromMap(Map<String, dynamic> map) => Todo(
        id: map['id'] as int?,
        screenshotId: map['screenshotId'] as int,
        screenshotUri: map['screenshotUri'] as String,
        title: map['title'] as String,
        category: TodoCategoryExt.fromString(map['category'] as String),
        dueDate: map['dueDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['dueDate'] as int)
            : null,
        duration: TodoDurationExt.fromString(map['duration'] as String),
        isCompleted: (map['isCompleted'] as int) == 1,
        isReminded: (map['isReminded'] as int) == 1,
        isEvent: (map['isEvent'] as int) == 1,
        notifyOption: NotifyOptionExt.fromString(map['notifyOption'] as String),
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      );
}
