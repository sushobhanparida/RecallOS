import 'dart:convert';

/// A typed entity extracted from OCR text by ML Kit Entity Extraction.
class ExtractedEntity {
  /// Normalized type: 'url', 'money', 'date', 'phone', 'flight', 'email',
  /// 'address', 'tracking', 'iban', 'isbn', 'payment_card'.
  final String type;

  /// The exact substring of the OCR text that matched.
  final String rawText;

  /// Optional structured fields (amount/currency, timestamp, airline+number,
  /// carrier+number, etc.). May be null for entities with no extra data.
  final Map<String, dynamic>? value;

  const ExtractedEntity({
    required this.type,
    required this.rawText,
    this.value,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'rawText': rawText,
        if (value != null) 'value': value,
      };

  factory ExtractedEntity.fromJson(Map<String, dynamic> json) =>
      ExtractedEntity(
        type: json['type'] as String,
        rawText: json['rawText'] as String,
        value: (json['value'] as Map?)?.cast<String, dynamic>(),
      );

  static String encodeList(List<ExtractedEntity> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<ExtractedEntity> decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((m) => ExtractedEntity.fromJson(m.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
