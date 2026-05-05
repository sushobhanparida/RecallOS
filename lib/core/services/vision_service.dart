import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/extracted_entity.dart';

/// Wraps barcode + face detection. Runs both on a file in parallel and
/// returns entities in the same shape as text-derived entities.
class VisionService {
  BarcodeScanner? _barcodeScanner;
  FaceDetector? _faceDetector;

  BarcodeScanner _ensureBarcode() =>
      _barcodeScanner ??= BarcodeScanner(formats: const [BarcodeFormat.all]);

  FaceDetector _ensureFace() => _faceDetector ??= FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          enableContours: false,
          enableLandmarks: false,
          enableClassification: false,
        ),
      );

  Future<List<ExtractedEntity>> scan(String filePath) async {
    final input = InputImage.fromFilePath(filePath);
    final results = await Future.wait<List<ExtractedEntity>>([
      _scanBarcodes(input),
      _detectFaces(input),
    ]);
    return [...results[0], ...results[1]];
  }

  Future<List<ExtractedEntity>> _scanBarcodes(InputImage input) async {
    try {
      final barcodes = await _ensureBarcode().processImage(input);
      final out = <ExtractedEntity>[];
      for (final b in barcodes) {
        final raw = (b.rawValue ?? b.displayValue ?? '').trim();
        if (raw.isEmpty) continue;
        out.add(_classify(raw, b));
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  ExtractedEntity _classify(String raw, Barcode b) {
    final lower = raw.toLowerCase();
    final upper = raw.toUpperCase();

    if (lower.startsWith('upi://')) {
      return ExtractedEntity(
        type: 'qr_payment',
        rawText: raw,
        value: _parseUpi(raw),
      );
    }
    if (upper.startsWith('WIFI:')) {
      return ExtractedEntity(
        type: 'qr_wifi',
        rawText: raw,
        value: _parseWifi(raw),
      );
    }
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return ExtractedEntity(type: 'qr_url', rawText: raw);
    }
    if (upper.startsWith('BEGIN:VCARD') || upper.startsWith('MECARD:')) {
      return ExtractedEntity(type: 'qr_contact', rawText: raw);
    }
    if (upper.startsWith('TEL:')) {
      return ExtractedEntity(type: 'qr_phone', rawText: raw);
    }
    if (upper.startsWith('MAILTO:') || upper.startsWith('SMTP:')) {
      return ExtractedEntity(type: 'qr_email', rawText: raw);
    }
    return ExtractedEntity(
      type: 'qr',
      rawText: raw,
      value: {'format': b.format.name},
    );
  }

  Map<String, dynamic> _parseUpi(String uri) {
    final u = Uri.tryParse(uri);
    if (u == null) return const {};
    return {
      'pa': u.queryParameters['pa'] ?? '',
      'pn': u.queryParameters['pn'] ?? '',
      'am': u.queryParameters['am'] ?? '',
      'cu': u.queryParameters['cu'] ?? '',
      'tn': u.queryParameters['tn'] ?? '',
    };
  }

  Map<String, dynamic> _parseWifi(String s) {
    // WIFI:T:WPA;S:NetworkName;P:Password;;
    final fields = <String, String>{};
    final body = s.substring(5).trim();
    final cleaned =
        body.endsWith(';;') ? body.substring(0, body.length - 2) : body;
    for (final part in cleaned.split(';')) {
      final i = part.indexOf(':');
      if (i > 0) {
        fields[part.substring(0, i).toUpperCase()] = part.substring(i + 1);
      }
    }
    return {
      'ssid': fields['S'] ?? '',
      'password': fields['P'] ?? '',
      'security': fields['T'] ?? '',
      'hidden': fields['H'] ?? '',
    };
  }

  Future<List<ExtractedEntity>> _detectFaces(InputImage input) async {
    try {
      final faces = await _ensureFace().processImage(input);
      if (faces.isEmpty) return const [];
      return [
        ExtractedEntity(
          type: 'portrait',
          rawText: '${faces.length} face${faces.length == 1 ? '' : 's'}',
          value: {'count': faces.length},
        ),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> dispose() async {
    await _barcodeScanner?.close();
    await _faceDetector?.close();
    _barcodeScanner = null;
    _faceDetector = null;
  }
}
