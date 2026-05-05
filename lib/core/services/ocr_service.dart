import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/extracted_entity.dart';
import '../models/screenshot_model.dart';

class OcrService {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> extractText(String filePath) async {
    try {
      final inputImage = InputImage.fromFile(File(filePath));
      final result = await _recognizer.processImage(inputImage);
      return result.text;
    } catch (_) {
      return '';
    }
  }

  /// Tag priority: QRs → Events → Shopping → Links → Notes (fallback).
  /// Pass entities when available — they upgrade precision dramatically.
  /// Without entities (initial scan, before extraction completes) the
  /// function falls back to text-only heuristics.
  ScreenshotTag autoTag(String text, {List<ExtractedEntity> entities = const []}) {
    final types = entities.map((e) => e.type).toSet();
    final lower = text.toLowerCase();

    // 1. QRs — vision-detected barcodes (entity-only signal).
    if (types.any((t) => t == 'qr' || t.startsWith('qr_'))) {
      return ScreenshotTag.qr;
    }

    // 2. Events — flight entity, OR date entity + event vocabulary,
    //    OR text-only date pattern + event vocabulary.
    final hasDateEntity = types.contains('date');
    final hasDateText = text.contains(RegExp(
        r'\b\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4}\b|\b202\d\b'));
    if (types.contains('flight') ||
        ((hasDateEntity || hasDateText) && _hasEventKeywords(lower))) {
      return ScreenshotTag.event;
    }

    // 3. Shopping — money entity, OR currency + purchase vocabulary.
    final hasMoneyEntity = types.contains('money');
    final hasCurrencyText = text.contains(RegExp(r'[₹$€£¥]'));
    if (hasMoneyEntity ||
        (hasCurrencyText && _hasShoppingKeywords(lower))) {
      return ScreenshotTag.shopping;
    }

    // 4. Links — url entity, OR raw URL in text.
    if (types.contains('url') || text.contains(RegExp(r'https?://'))) {
      return ScreenshotTag.link;
    }

    // 5. Notes — fallback.
    return ScreenshotTag.note;
  }

  static final _eventKeywords = RegExp(
    r'\b(ticket|admission|gate|boarding|concert|show|venue|seat|row|'
    r'event|festival|conference|seminar|match|game|cinema|movie|screening|'
    r'depart|arrival|terminal|pnr|flight|train|platform)\b',
  );

  static final _shoppingKeywords = RegExp(
    r'\b(cart|order|orders|checkout|receipt|invoice|total|subtotal|'
    r'discount|coupon|buy|price|payment|paid|delivery|shipping|'
    r'product|item|qty|quantity|amount|amazon|flipkart|myntra|meesho)\b',
  );

  bool _hasEventKeywords(String lower) => _eventKeywords.hasMatch(lower);
  bool _hasShoppingKeywords(String lower) => _shoppingKeywords.hasMatch(lower);

  void dispose() => _recognizer.close();
}
