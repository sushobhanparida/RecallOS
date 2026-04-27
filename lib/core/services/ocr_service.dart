import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
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

  ScreenshotTag autoTag(String text) {
    if (text.contains(RegExp(r'[₹$]'))) return ScreenshotTag.shopping;
    if (text.contains(RegExp(r'https?://'))) return ScreenshotTag.link;
    if (text.contains(RegExp(
        r'\b\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4}\b|\b202\d\b'))) {
      return ScreenshotTag.event;
    }
    if (text.length > 100) return ScreenshotTag.read;
    return ScreenshotTag.general;
  }

  void dispose() => _recognizer.close();
}
