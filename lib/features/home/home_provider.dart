import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../core/database/app_database.dart';
import '../../core/models/screenshot_model.dart';
import '../../core/services/ocr_service.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class HomeState {
  final List<Screenshot> screenshots;
  final String searchQuery;
  final String tagFilter;
  final bool isImporting;

  const HomeState({
    this.screenshots = const [],
    this.searchQuery = '',
    this.tagFilter = 'All',
    this.isImporting = false,
  });

  HomeState copyWith({
    List<Screenshot>? screenshots,
    String? searchQuery,
    String? tagFilter,
    bool? isImporting,
  }) =>
      HomeState(
        screenshots: screenshots ?? this.screenshots,
        searchQuery: searchQuery ?? this.searchQuery,
        tagFilter: tagFilter ?? this.tagFilter,
        isImporting: isImporting ?? this.isImporting,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class HomeNotifier extends StateNotifier<HomeState> {
  final AppDatabase _db;
  final OcrService _ocr;

  HomeNotifier(this._db, this._ocr) : super(const HomeState()) {
    loadScreenshots();
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
  }

  Future<void> importFromCamera() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera);
    if (file == null) return;

    state = state.copyWith(isImporting: true);
    await _importFile(file.path);
    state = state.copyWith(isImporting: false);
    await loadScreenshots();
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
      final tag = _ocr.autoTag(text);

      await _db.insertScreenshot(Screenshot(
        uri: destPath,
        extractedText: text,
        tag: tag,
        createdAt: DateTime.now(),
      ));
    } catch (_) {}
  }

  Future<void> deleteScreenshot(int id) async {
    await _db.deleteScreenshot(id);
    await loadScreenshots();
  }
}

// ── Providers ──────────────────────────────────────────────────────────────────

final ocrServiceProvider = Provider<OcrService>((ref) {
  final service = OcrService();
  ref.onDispose(service.dispose);
  return service;
});

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(AppDatabase.instance, ref.watch(ocrServiceProvider));
});
