enum ScreenshotTag { shopping, link, event, read, general }

extension ScreenshotTagExt on ScreenshotTag {
  String get label {
    switch (this) {
      case ScreenshotTag.shopping:
        return 'Shopping';
      case ScreenshotTag.link:
        return 'Link';
      case ScreenshotTag.event:
        return 'Event';
      case ScreenshotTag.read:
        return 'Read';
      case ScreenshotTag.general:
        return 'General';
    }
  }

  static ScreenshotTag fromString(String s) {
    switch (s.toLowerCase()) {
      case 'shopping':
        return ScreenshotTag.shopping;
      case 'link':
        return ScreenshotTag.link;
      case 'event':
        return ScreenshotTag.event;
      case 'read':
        return ScreenshotTag.read;
      default:
        return ScreenshotTag.general;
    }
  }
}

class Screenshot {
  final int? id;
  final String uri;
  final String extractedText;
  final ScreenshotTag tag;
  final DateTime createdAt;

  const Screenshot({
    this.id,
    required this.uri,
    this.extractedText = '',
    this.tag = ScreenshotTag.general,
    required this.createdAt,
  });

  Screenshot copyWith({
    int? id,
    String? uri,
    String? extractedText,
    ScreenshotTag? tag,
    DateTime? createdAt,
  }) {
    return Screenshot(
      id: id ?? this.id,
      uri: uri ?? this.uri,
      extractedText: extractedText ?? this.extractedText,
      tag: tag ?? this.tag,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'uri': uri,
        'extractedText': extractedText,
        'tag': tag.label,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory Screenshot.fromMap(Map<String, dynamic> map) => Screenshot(
        id: map['id'] as int?,
        uri: map['uri'] as String,
        extractedText: (map['extractedText'] as String?) ?? '',
        tag: ScreenshotTagExt.fromString((map['tag'] as String?) ?? ''),
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      );
}
