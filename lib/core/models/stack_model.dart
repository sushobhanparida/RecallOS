import 'screenshot_model.dart';

class Stack {
  final int? id;
  final String name;
  final DateTime createdAt;
  final List<Screenshot> screenshots;

  const Stack({
    this.id,
    required this.name,
    required this.createdAt,
    this.screenshots = const [],
  });

  Stack copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    List<Screenshot>? screenshots,
  }) {
    return Stack(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      screenshots: screenshots ?? this.screenshots,
    );
  }

  Screenshot? get coverImage =>
      screenshots.isNotEmpty ? screenshots.first : null;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory Stack.fromMap(Map<String, dynamic> map,
      {List<Screenshot> screenshots = const []}) =>
      Stack(
        id: map['id'] as int?,
        name: map['name'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
        screenshots: screenshots,
      );
}
