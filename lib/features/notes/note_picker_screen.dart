import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/app_database.dart';
import '../../core/models/screenshot_model.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';

/// All-screenshots grid for picking which one to convert into a note.
class NotePickerScreen extends ConsumerStatefulWidget {
  const NotePickerScreen({super.key});

  @override
  ConsumerState<NotePickerScreen> createState() => _NotePickerScreenState();
}

class _NotePickerScreenState extends ConsumerState<NotePickerScreen> {
  late Future<List<Screenshot>> _future;

  @override
  void initState() {
    super.initState();
    _future = AppDatabase.instance.getScreenshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.borderDefault, width: 1),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.textPrimary, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pick a screenshot',
                          style: AppTypography.headingSm
                              .copyWith(color: AppColors.textPrimary)),
                      Text('Tap to convert it into a note',
                          style: AppTypography.bodySm
                              .copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Screenshot>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppColors.accent,
                      ),
                    );
                  }
                  final list = snap.data ?? const [];
                  if (list.isEmpty) {
                    return Center(
                      child: Text('No screenshots',
                          style: AppTypography.bodyMd
                              .copyWith(color: AppColors.textMuted)),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.62,
                    ),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final s = list[i];
                      return _PickTile(
                        screenshot: s,
                        onTap: () {
                          context.go('/notes/edit/${s.id}');
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickTile extends StatelessWidget {
  final Screenshot screenshot;
  final VoidCallback onTap;

  const _PickTile({required this.screenshot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: screenshot.uri.startsWith('http')
                  ? Image.network(screenshot.uri, fit: BoxFit.cover)
                  : Image.file(File(screenshot.uri), fit: BoxFit.cover),
            ),
          ),
          if (screenshot.isNote)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.tagNoteMuted,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: AppColors.tagNote.withValues(alpha: 0.4),
                      width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notes_rounded,
                        size: 10, color: AppColors.tagNote),
                    const SizedBox(width: 3),
                    Text('Note',
                        style: AppTypography.labelSm
                            .copyWith(color: AppColors.tagNote)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
