import 'package:google_mlkit_entity_extraction/google_mlkit_entity_extraction.dart';
import '../models/extracted_entity.dart';

/// Wraps ML Kit Entity Extraction. Lazily downloads the English model on
/// first use and caches the extractor for the app's lifetime.
class EntityService {
  EntityExtractor? _extractor;
  bool _modelReady = false;

  Future<bool> _ensureReady() async {
    try {
      _extractor ??=
          EntityExtractor(language: EntityExtractorLanguage.english);
      if (_modelReady) return true;
      final manager = EntityExtractorModelManager();
      final downloaded = await manager
          .isModelDownloaded(EntityExtractorLanguage.english.name);
      if (!downloaded) {
        await manager.downloadModel(
          EntityExtractorLanguage.english.name,
          isWifiRequired: false,
        );
      }
      _modelReady = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<ExtractedEntity>> extract(String text) async {
    if (text.trim().isEmpty) return const [];
    final ready = await _ensureReady();
    if (!ready) return const [];
    try {
      final annotations = await _extractor!.annotateText(text);
      final out = <ExtractedEntity>[];
      for (final ann in annotations) {
        for (final entity in ann.entities) {
          final mapped = _toExtracted(ann.text, entity);
          if (mapped != null) out.add(mapped);
        }
      }
      return _dedupe(out);
    } catch (_) {
      return const [];
    }
  }

  List<ExtractedEntity> _dedupe(List<ExtractedEntity> entities) {
    final seen = <String>{};
    final out = <ExtractedEntity>[];
    for (final e in entities) {
      final key = '${e.type}::${e.rawText.toLowerCase()}';
      if (seen.add(key)) out.add(e);
    }
    return out;
  }

  ExtractedEntity? _toExtracted(String text, Entity entity) {
    if (entity is MoneyEntity) {
      final amount = entity.integerPart + entity.fractionPart / 100.0;
      return ExtractedEntity(
        type: 'money',
        rawText: text,
        value: {
          'amount': amount,
          'currency': entity.unnormalizedCurrency,
        },
      );
    }
    if (entity is DateTimeEntity) {
      return ExtractedEntity(
        type: 'date',
        rawText: text,
        value: {'timestamp': entity.timestamp},
      );
    }
    if (entity is UrlEntity) {
      return ExtractedEntity(type: 'url', rawText: text);
    }
    if (entity is PhoneEntity) {
      return ExtractedEntity(type: 'phone', rawText: text);
    }
    if (entity is FlightNumberEntity) {
      return ExtractedEntity(
        type: 'flight',
        rawText: text,
        value: {
          'airline': entity.airlineCode,
          'number': entity.flightNumber,
        },
      );
    }
    if (entity is EmailEntity) {
      return ExtractedEntity(type: 'email', rawText: text);
    }
    if (entity is AddressEntity) {
      return ExtractedEntity(type: 'address', rawText: text);
    }
    if (entity is TrackingNumberEntity) {
      return ExtractedEntity(
        type: 'tracking',
        rawText: text,
        value: {
          'carrier': entity.carrier.name,
          'number': entity.number,
        },
      );
    }
    if (entity is IbanEntity) {
      return ExtractedEntity(type: 'iban', rawText: text);
    }
    if (entity is IsbnEntity) {
      return ExtractedEntity(type: 'isbn', rawText: text);
    }
    if (entity is PaymentCardEntity) {
      return ExtractedEntity(type: 'payment_card', rawText: text);
    }
    return null;
  }

  Future<void> dispose() async {
    await _extractor?.close();
    _extractor = null;
  }
}
