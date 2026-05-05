import 'extracted_entity.dart';

enum ScreenshotTag { note, link, qr, event, shopping }

extension ScreenshotTagExt on ScreenshotTag {
  String get label {
    switch (this) {
      case ScreenshotTag.note:
        return 'Notes';
      case ScreenshotTag.link:
        return 'Links';
      case ScreenshotTag.qr:
        return 'QRs';
      case ScreenshotTag.event:
        return 'Events';
      case ScreenshotTag.shopping:
        return 'Shopping';
    }
  }

  static ScreenshotTag fromString(String s) {
    switch (s.toLowerCase()) {
      case 'shopping':
        return ScreenshotTag.shopping;
      case 'link':
      case 'links':
        return ScreenshotTag.link;
      case 'event':
      case 'events':
        return ScreenshotTag.event;
      case 'qr':
      case 'qrs':
        return ScreenshotTag.qr;
      // Legacy tags fall back to Notes (the catch-all category).
      case 'note':
      case 'notes':
      case 'read':
      case 'general':
      default:
        return ScreenshotTag.note;
    }
  }
}

class Screenshot {
  final int? id;
  final String uri;
  final String extractedText;
  final ScreenshotTag tag;
  final DateTime createdAt;
  final List<ExtractedEntity> entities;
  /// User-edited note title.
  final String? noteTitle;
  /// User-edited note text. When non-null, this screenshot has been "converted
  /// to a note" — it appears in the Notes tab's saved-notes grid.
  final String? noteText;
  /// File fingerprint used to detect duplicates on import.
  final String? contentHash;
  /// NVIDIA NIM AI Generated Summary
  final String? aiSummary;
  /// Full AI JSON analysis payload containing stacks, entities, and actions
  final String? aiAnalysisPayload;

  const Screenshot({
    this.id,
    required this.uri,
    this.extractedText = '',
    this.tag = ScreenshotTag.note,
    required this.createdAt,
    this.entities = const [],
    this.noteTitle,
    this.noteText,
    this.contentHash,
    this.aiSummary,
    this.aiAnalysisPayload,
  });

  bool get isNote => noteText != null;

  Screenshot copyWith({
    int? id,
    String? uri,
    String? extractedText,
    ScreenshotTag? tag,
    DateTime? createdAt,
    List<ExtractedEntity>? entities,
    String? noteTitle,
    String? noteText,
    String? contentHash,
    String? aiSummary,
    String? aiAnalysisPayload,
    bool clearNote = false,
  }) {
    return Screenshot(
      id: id ?? this.id,
      uri: uri ?? this.uri,
      extractedText: extractedText ?? this.extractedText,
      tag: tag ?? this.tag,
      createdAt: createdAt ?? this.createdAt,
      entities: entities ?? this.entities,
      noteTitle: clearNote ? null : (noteTitle ?? this.noteTitle),
      noteText: clearNote ? null : (noteText ?? this.noteText),
      contentHash: contentHash ?? this.contentHash,
      aiSummary: aiSummary ?? this.aiSummary,
      aiAnalysisPayload: aiAnalysisPayload ?? this.aiAnalysisPayload,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'uri': uri,
        'extractedText': extractedText,
        'tag': tag.label,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'entities': ExtractedEntity.encodeList(entities),
        'noteTitle': noteTitle,
        'noteText': noteText,
        'contentHash': contentHash,
        'aiSummary': aiSummary,
        'aiAnalysisPayload': aiAnalysisPayload,
      };

  factory Screenshot.fromMap(Map<String, dynamic> map) => Screenshot(
        id: map['id'] as int?,
        uri: map['uri'] as String,
        extractedText: (map['extractedText'] as String?) ?? '',
        tag: ScreenshotTagExt.fromString((map['tag'] as String?) ?? ''),
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
        entities: ExtractedEntity.decodeList(map['entities'] as String?),
        noteTitle: map['noteTitle'] as String?,
        noteText: map['noteText'] as String?,
        contentHash: map['contentHash'] as String?,
        aiSummary: map['aiSummary'] as String?,
        aiAnalysisPayload: map['aiAnalysisPayload'] as String?,
      );
}
