import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../core/database/app_database.dart';
import '../../core/models/extracted_entity.dart';
import '../../core/models/screenshot_model.dart';
import '../../core/services/entity_service.dart';
import '../../core/services/ocr_service.dart';
import '../../core/services/screenshot_watcher_service.dart';
import '../../core/services/smart_actions_service.dart';
import '../../core/services/vision_service.dart';
import '../../core/services/ai_vision_service.dart';
import '../stacks/stacks_provider.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class HomeState {
  final List<Screenshot> screenshots;
  /// Unfiltered full library — always up-to-date regardless of active tag/search.
  final List<Screenshot> allScreenshots;
  final String searchQuery;
  final String tagFilter;
  final bool isImporting;
  final int backfillRemaining;

  const HomeState({
    this.screenshots = const [],
    this.allScreenshots = const [],
    this.searchQuery = '',
    this.tagFilter = 'All',
    this.isImporting = false,
    this.backfillRemaining = 0,
  });

  HomeState copyWith({
    List<Screenshot>? screenshots,
    List<Screenshot>? allScreenshots,
    String? searchQuery,
    String? tagFilter,
    bool? isImporting,
    int? backfillRemaining,
  }) =>
      HomeState(
        screenshots: screenshots ?? this.screenshots,
        allScreenshots: allScreenshots ?? this.allScreenshots,
        searchQuery: searchQuery ?? this.searchQuery,
        tagFilter: tagFilter ?? this.tagFilter,
        isImporting: isImporting ?? this.isImporting,
        backfillRemaining: backfillRemaining ?? this.backfillRemaining,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class HomeNotifier extends StateNotifier<HomeState> {
  final AppDatabase _db;
  final OcrService _ocr;
  final EntityService _entities;
  final VisionService _vision;
  final AiVisionService _aiVision;
  final Ref _ref;

  bool _backfillStarted = false;

  HomeNotifier(
      this._db, this._ocr, this._entities, this._vision, this._aiVision, this._ref)
      : super(const HomeState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    await loadScreenshots();
    // Kick off the one-shot entity backfill in the background. The first run
    // also pays the cost of downloading the entity-extraction model.
    unawaited(_backfillEntities());
  }

  void _invalidateScreenshotConsumers() {
    _ref.invalidate(allScreenshotsProvider);
    _ref.invalidate(suggestionsProvider);
  }

  Future<void> _backfillEntities() async {
    if (_backfillStarted) return;
    _backfillStarted = true;
    try {
      var remaining = await _db.getEntityBackfillRemaining();
      if (remaining == 0) return;
      state = state.copyWith(backfillRemaining: remaining);

      while (true) {
        final batch = await _db.getScreenshotsNeedingEntityBackfill(limit: 20);
        if (batch.isEmpty) break;

        for (final s in batch) {
          final results = await Future.wait([
            _entities.extract(s.extractedText),
            _vision.scan(s.uri),
          ]);
          final merged = [...results[0], ...results[1]];
          // Re-tag with full entity set so legacy "General"/"Read" rows land
          // in the correct new bucket (Notes/Links/QRs/Events/Shopping).
          final newTag = _ocr.autoTag(s.extractedText, entities: merged);
          await _db.updateScreenshot(
              s.copyWith(entities: merged, tag: newTag));
        }

        remaining = await _db.getEntityBackfillRemaining();
        state = state.copyWith(backfillRemaining: remaining);

        await loadScreenshots();
        _invalidateScreenshotConsumers();

        // Yield to keep the UI responsive between batches.
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }
    } catch (_) {
      // Best-effort — failures here just mean the next launch tries again.
    } finally {
      state = state.copyWith(backfillRemaining: 0);
    }
  }

  Future<void> loadScreenshots() async {
    final filtered = await _db.getScreenshots(
      tagFilter: state.tagFilter == 'All' ? null : state.tagFilter,
      query: state.searchQuery.isEmpty ? null : state.searchQuery,
    );
    final isFiltered =
        state.tagFilter != 'All' || state.searchQuery.isNotEmpty;
    final all = isFiltered ? await _db.getScreenshots() : filtered;
    state = state.copyWith(screenshots: filtered, allScreenshots: all);
  }

  void setFilter(String filter) {
    state = state.copyWith(tagFilter: filter);
    loadScreenshots();
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
    loadScreenshots();
  }

  Future<void> importFromGallery() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage();
    if (files.isEmpty) return;

    state = state.copyWith(isImporting: true);

    for (final file in files) {
      await _importFile(file.path);
    }

    state = state.copyWith(isImporting: false);
    await loadScreenshots();
    _invalidateScreenshotConsumers();
  }

  Future<void> _importFile(String sourcePath) async {
    try {
      final hash = await _contentHash(sourcePath);
      if (await _db.existsByContentHash(hash)) return;

      final appDir = await getApplicationDocumentsDirectory();
      final destDir = Directory(p.join(appDir.path, 'screenshots'));
      await destDir.create(recursive: true);

      final filename = p.basename(sourcePath);
      final destPath = p.join(destDir.path, filename);
      await File(sourcePath).copy(destPath);

      final text = await _ocr.extractText(destPath);
      final results = await Future.wait([
        _entities.extract(text),
        _vision.scan(destPath),
      ]);
      final entities = [...results[0], ...results[1]];
      // Tag AFTER entities — QR/portrait entities (vision) and money/date/url
      // entities (text) all feed the priority-ordered classifier.
      final tag = _ocr.autoTag(text, entities: entities);

      final id = await _db.insertScreenshot(Screenshot(
        uri: destPath,
        extractedText: text,
        tag: tag,
        createdAt: DateTime.now(),
        entities: entities,
        contentHash: hash,
      ));

      // Asynchronously fetch rich AI data
      unawaited(_enrichWithAi(id, destPath, text));
    } catch (_) {}
  }

  Future<void> _enrichWithAi(int id, String path, String text) async {
    try {
      final aiResult = await _aiVision.analyzeScreenshot(path, text);
      if (aiResult != null) {
        final existing = await _db.getScreenshotById(id);
        if (existing != null) {
          final payloadStr = aiResult['payload'] as String?;
          List<ExtractedEntity> newEntities = [];
          ScreenshotTag? newTag;

          if (payloadStr != null) {
            try {
              final payload = jsonDecode(payloadStr);
              
              // 1. Merge semantic entities
              if (payload['semantic_entities'] is List) {
                for (final e in payload['semantic_entities']) {
                  final type = e['type'] as String?;
                  final value = e['value'] as String?;
                  if (type != null && value != null) {
                    newEntities.add(ExtractedEntity(type: type, rawText: value));
                  }
                }
              }

              // 2. Override tag if AI is confident
              final aiTagStr = payload['suggested_tag'] as String?;
              if (aiTagStr != null) {
                newTag = ScreenshotTagExt.fromString(aiTagStr);
              }
            } catch (_) {}
          }

          final updated = existing.copyWith(
            aiSummary: aiResult['summary'] as String?,
            aiAnalysisPayload: payloadStr,
            entities: [...existing.entities, ...newEntities],
            tag: newTag ?? existing.tag,
          );
          await _db.updateScreenshot(updated);
          await loadScreenshots();
          _invalidateScreenshotConsumers();
          _ref.invalidate(screenshotDetailProvider(id));
        }
      }
    } catch (e) {
      print('AI enrichment failed: $e');
    }
  }

  /// Lightweight fingerprint: file size + hex of first 64 bytes.
  /// Collision probability between two distinct screenshots is negligible.
  Future<String> _contentHash(String path) async {
    final file = File(path);
    final size = (await file.stat()).size;
    final raf = await file.open();
    final bytes = await raf.read(64);
    await raf.close();
    final hex =
        bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${size}_$hex';
  }

  Future<void> deleteScreenshot(int id) async {
    await _db.deleteScreenshot(id);
    await loadScreenshots();
    _invalidateScreenshotConsumers();
  }

  /// Imports a screenshot directly from [sourcePath] (e.g. from the native
  /// MediaStore path delivered by a notification action). Returns the inserted
  /// [Screenshot] with its DB id, or null on failure.
  Future<Screenshot?> importFromPath(String sourcePath) async {
    state = state.copyWith(isImporting: true);
    try {
      final hash = await _contentHash(sourcePath);
      if (await _db.existsByContentHash(hash)) return null;

      final appDir = await getApplicationDocumentsDirectory();
      final destDir = Directory(p.join(appDir.path, 'screenshots'));
      await destDir.create(recursive: true);

      // Prefix with timestamp to avoid name collisions.
      final filename =
          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(sourcePath)}';
      final destPath = p.join(destDir.path, filename);
      await File(sourcePath).copy(destPath);

      final text = await _ocr.extractText(destPath);
      final results = await Future.wait([
        _entities.extract(text),
        _vision.scan(destPath),
      ]);
      final entities = [...results[0], ...results[1]];
      final tag = _ocr.autoTag(text, entities: entities);

      final id = await _db.insertScreenshot(Screenshot(
        uri: destPath,
        extractedText: text,
        tag: tag,
        createdAt: DateTime.now(),
        entities: entities,
        contentHash: hash,
      ));

      // Asynchronously fetch rich AI data
      unawaited(_enrichWithAi(id, destPath, text));

      await loadScreenshots();
      _invalidateScreenshotConsumers();

      return state.screenshots
          .where((s) => s.uri == destPath)
          .firstOrNull;
    } catch (_) {
      return null;
    } finally {
      state = state.copyWith(isImporting: false);
    }
  }
}

// ── Providers ──────────────────────────────────────────────────────────────────

final ocrServiceProvider = Provider<OcrService>((ref) {
  final service = OcrService();
  ref.onDispose(service.dispose);
  return service;
});

final entityServiceProvider = Provider<EntityService>((ref) {
  final service = EntityService();
  ref.onDispose(service.dispose);
  return service;
});

final visionServiceProvider = Provider<VisionService>((ref) {
  final service = VisionService();
  ref.onDispose(service.dispose);
  return service;
});

final aiVisionServiceProvider = Provider<AiVisionService>((ref) {
  return AiVisionService();
});

final smartActionsServiceProvider =
    Provider<SmartActionsService>((_) => SmartActionsService());

final screenshotDetailProvider =
    FutureProvider.family<Screenshot?, int>((ref, id) async {
  return AppDatabase.instance.getScreenshotById(id);
});

/// Tracks screenshot IDs whose action cards have been dismissed by the user.
final dismissedActionsProvider = StateProvider<Set<int>>((ref) => {});

/// Surface smart actions across all current screenshots — drives the home
/// "Actions" banner row. Filters out dismissed actions.
final smartActionsProvider = Provider<List<SmartAction>>((ref) {
  final state = ref.watch(homeProvider);
  final dismissed = ref.watch(dismissedActionsProvider);
  final all = ref.watch(smartActionsServiceProvider).actionsFor(state.screenshots);
  return all.where((a) => !dismissed.contains(a.screenshot.id)).toList();
});

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(
    AppDatabase.instance,
    ref.watch(ocrServiceProvider),
    ref.watch(entityServiceProvider),
    ref.watch(visionServiceProvider),
    ref.watch(aiVisionServiceProvider),
    ref,
  );
});

/// One-shot MediaStore query: total screenshots on device.
/// Cached for the app lifetime; only runs again if the provider is invalidated.
final deviceScreenshotCountProvider = FutureProvider<int>((ref) {
  return ScreenshotWatcherService.countDeviceScreenshots();
});

/// Derives 2–3 dynamic insight strings from the full unfiltered library.
/// Drives the typewriter text shown beneath "RecallOS" in the home header.
final homeInsightsProvider = Provider<List<String>>((ref) {
  final shots = ref.watch(homeProvider).allScreenshots;
  final deviceCount = ref.watch(deviceScreenshotCountProvider).valueOrNull;
  return _buildInsights(shots, deviceTotal: deviceCount);
});

// ── Insight helpers ────────────────────────────────────────────────────────────

List<String> _buildInsights(
  List<Screenshot> screenshots, {
  int? deviceTotal,
}) {
  if (screenshots.isEmpty) {
    return [
      'Turn screenshots into actions.',
      'Never miss what matters.',
      'Capture your first screenshot.',
    ];
  }

  final lines = <String>[];
  final now = DateTime.now();
  final imported = screenshots.length;

  // 1. New since yesterday
  final recent = screenshots
      .where((s) => now.difference(s.createdAt).inHours < 24)
      .length;
  if (recent > 0) {
    lines.add(recent == 1
        ? '1 new screenshot since yesterday.'
        : '$recent new screenshots since yesterday.');
  }

  // 2. Device ratio or total count
  if (deviceTotal != null && deviceTotal > imported) {
    lines.add('${_fmt(imported)} of ${_fmt(deviceTotal)} screenshots added.');
  } else {
    lines.add('You have a total of ${_fmt(imported)}'
        ' screenshot${imported == 1 ? '' : 's'}.');
  }

  if (lines.length < 2) lines.insert(0, 'Your visual memory, organised.');

  return lines.take(3).toList();
}

/// Formats an integer with thousands separators: 4777 → "4,777".
String _fmt(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );

