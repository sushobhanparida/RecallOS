import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../secrets/app_secrets.dart';

class AiVisionService {
  static const String _apiKey = AppSecrets.nvidiaApiKey;
  static const String _endpoint = 'https://integrate.api.nvidia.com/v1/chat/completions';

  /// Analyzes a screenshot using NVIDIA NIM Vision model
  /// Returns a JSON string payload that can be stored in [Screenshot.aiAnalysisPayload]
  /// and the short summary for [Screenshot.aiSummary]
  Future<Map<String, dynamic>?> analyzeScreenshot(String imagePath, String ocrText) async {
    try {
      if (_apiKey.isEmpty || _apiKey == 'YOUR_NVIDIA_API_KEY') return null;

      final file = File(imagePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      
      // Decode and downscale image to save bandwidth and API limits
      final originalImage = img.decodeImage(bytes);
      if (originalImage == null) return null;

      // Downscale to max 1024px width/height while maintaining aspect ratio
      int width = originalImage.width;
      int height = originalImage.height;
      if (width > 1024 || height > 1024) {
        if (width > height) {
          height = (height * 1024 / width).round();
          width = 1024;
        } else {
          width = (width * 1024 / height).round();
          height = 1024;
        }
      }
      
      final resizedImage = img.copyResize(originalImage, width: width, height: height);
      final compressedBytes = img.encodeJpg(resizedImage, quality: 80);
      final base64Image = base64Encode(compressedBytes);

      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          "model": "meta/llama-3.2-90b-vision-instruct",
          "messages": [
            {
              "role": "system",
              "content": "You are an AI assistant for a screenshot organizer app. You analyze screenshots and OCR text to categorize and extract structured data. You MUST return ONLY a valid JSON object with the following schema, with no markdown formatting or extra text:\n"
                  "{\n"
                  "  \"summary\": \"A short 2-3 sentence description of what this screenshot is about.\",\n"
                  "  \"suggested_tag\": \"Note | Link | QR | Event | Shopping\",\n"
                  "  \"suggested_stacks\": [\"Stack 1\", \"Stack 2\"],\n"
                  "  \"semantic_entities\": [{\"type\": \"label\", \"value\": \"extracted value\"}],\n"
                  "  \"smart_actions\": [{\"intent\": \"action_name\", \"title\": \"Action Title\", \"data\": \"relevant data\"}]\n"
                  "}"
            },
            {
              "role": "user",
              "content": [
                {
                  "type": "text", 
                  "text": "OCR Text: $ocrText\n\nAnalyze this screenshot and extract the requested JSON data."
                },
                {
                  "type": "image_url", 
                  "image_url": {"url": "data:image/jpeg;base64,$base64Image"}
                }
              ]
            }
          ],
          "temperature": 0.2,
          "max_tokens": 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        
        // Clean up potential markdown formatting block if the model ignores the prompt
        final cleanedContent = content.replaceAll(RegExp(r'```json\n|\n```|```'), '').trim();
        final payload = jsonDecode(cleanedContent) as Map<String, dynamic>;
        
        return {
          'summary': payload['summary'],
          'payload': jsonEncode(payload),
        };
      } else {
        // Fallback or log error
        print('NVIDIA API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('AiVisionService Error: $e');
      return null;
    }
  }
}
