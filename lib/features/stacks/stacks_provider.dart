import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/models/stack_model.dart';
import '../../core/models/screenshot_model.dart';

class StacksState {
  final List<Stack> stacks;
  final bool isLoading;

  const StacksState({this.stacks = const [], this.isLoading = false});

  StacksState copyWith({List<Stack>? stacks, bool? isLoading}) => StacksState(
        stacks: stacks ?? this.stacks,
        isLoading: isLoading ?? this.isLoading,
      );
}

class StacksNotifier extends StateNotifier<StacksState> {
  final AppDatabase _db;

  StacksNotifier(this._db) : super(const StacksState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final stacks = await _db.getStacks();
    state = StacksState(stacks: stacks);
  }

  Future<void> createStack(String name) async {
    await _db.insertStack(Stack(name: name, createdAt: DateTime.now()));
    await load();
  }

  Future<void> deleteStack(int id) async {
    await _db.deleteStack(id);
    await load();
  }

  Future<void> renameStack(int id, String name) async {
    await _db.renameStack(id, name);
    await load();
  }

  Future<void> addScreenshot(int stackId, int screenshotId) async {
    await _db.addScreenshotToStack(stackId, screenshotId);
    await load();
  }

  Future<void> removeScreenshot(int stackId, int screenshotId) async {
    await _db.removeScreenshotFromStack(stackId, screenshotId);
    await load();
  }
}

// Provider for a single stack by ID (for stack detail screen)
final stackDetailProvider =
    FutureProvider.family<Stack?, int>((ref, stackId) async {
  return AppDatabase.instance.getStackById(stackId);
});

// Provider for all screenshots (used in stack picker)
final allScreenshotsProvider = FutureProvider<List<Screenshot>>((ref) async {
  return AppDatabase.instance.getScreenshots();
});

final stacksProvider = StateNotifierProvider<StacksNotifier, StacksState>(
  (ref) => StacksNotifier(AppDatabase.instance),
);
