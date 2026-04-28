import 'dart:io';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../core/database/app_database.dart';
import '../../core/models/screenshot_model.dart';
import '../../core/services/entity_service.dart';
import '../../core/services/ocr_service.dart';
import '../../core/services/smart_actions_service.dart';
import '../../core/services/vision_service.dart';
import '../stacks/stacks_provider.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class HomeState {
  final List<Screenshot> screenshots;
  final String searchQuery;
  final String tagFilter;
  final bool isImporting;
  final int backfillRemaining;

  const HomeState({
    this.screenshots = const [],
    this.searchQuery = '',
    this.tagFilter = 'All',
    this.isImporting = false,
    this.backfillRemaining = 0,
  });

  HomeState copyWith({
    List<Screenshot>? screenshots,
    String? searchQuery,
    String? tagFilter,
    bool? isImporting,
    int? backfillRemaining,
  }) =>
      HomeState(
        screenshots: screenshots ?? this.screenshots,
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
  final Ref _ref;

  bool _backfillStarted = false;

  HomeNotifier(
      this._db, this._ocr, this._entities, this._vision, this._ref)
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
    final results = await _db.getScreenshots(
      tagFilter: state.tagFilter == 'All' ? null : state.tagFilter,
      query: state.searchQuery.isEmpty ? null : state.searchQuery,
    );
    state = state.copyWith(screenshots: results);
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

  Future<void> importFromCamera() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera);
    if (file == null) return;

    state = state.copyWith(isImporting: true);
    await _importFile(file.path);
    state = state.copyWith(isImporting: false);
    await loadScreenshots();
    _invalidateScreenshotConsumers();
  }

  Future<void> _importFile(String sourcePath) async {
    try {
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

      await _db.insertScreenshot(Screenshot(
        uri: destPath,
        extractedText: text,
        tag: tag,
        createdAt: DateTime.now(),
        entities: entities,
      ));
    } catch (_) {}
  }

  Future<void> deleteScreenshot(int id) async {
    await _db.deleteScreenshot(id);
    await loadScreenshots();
    _invalidateScreenshotConsumers();
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

final smartActionsServiceProvider =
    Provider<SmartActionsService>((_) => SmartActionsService());

/// Surface smart actions across all current screenshots — drives the home
/// "Actions" banner row.
final smartActionsProvider = Provider<List<SmartAction>>((ref) {
  final state = ref.watch(homeProvider);
  return ref.watch(smartActionsServiceProvider).actionsFor(state.screenshots);
});

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(
    AppDatabase.instance,
    ref.watch(ocrServiceProvider),
    ref.watch(entityServiceProvider),
    ref.watch(visionServiceProvider),
    ref,
  );
});
