import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/database/app_database.dart';
import '../../core/models/extracted_entity.dart';
import '../../core/models/screenshot_model.dart';
import '../../core/services/crop_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../shared/widgets/tag_badge.dart';
import '../home/home_provider.dart';
import '../stacks/stacks_provider.dart';
import '../task/task_provider.dart';
import '../task/widgets/add_to_tasks_sheet.dart';

final _screenshotDetailProvider =
    FutureProvider.family<Screenshot?, int>((ref, id) async {
  return AppDatabase.instance.getScreenshotById(id);
});

class ScreenshotDetailScreen extends ConsumerStatefulWidget {
  final int screenshotId;

  const ScreenshotDetailScreen({super.key, required this.screenshotId});

  @override
  ConsumerState<ScreenshotDetailScreen> createState() =>
      _ScreenshotDetailScreenState();
}

class _ScreenshotDetailScreenState
    extends ConsumerState<ScreenshotDetailScreen> {
  final _cropService = CropService();
  bool _isProcessing = false;
  String _processingLabel = '';

  Future<void> _runSmartCrop(Screenshot screenshot) async {
    await _runCrop(
      screenshot,
      label: 'Finding subject…',
      run: () => _cropService.smartCrop(screenshot.uri),
      onNoSubject: () => _showSnack(
          'No subject detected — try manual crop',
          isError: false),
    );
  }

  Future<void> _runManualCrop(Screenshot screenshot) async {
    await _runCrop(
      screenshot,
      label: 'Saving…',
      run: () => _cropService.manualCrop(screenshot.uri),
    );
  }

  Future<void> _runCrop(
    Screenshot screenshot, {
    required String label,
    required Future<CropResult> Function() run,
    VoidCallback? onNoSubject,
  }) async {
    setState(() {
      _isProcessing = true;
      _processingLabel = label;
    });

    final result = await run();

    if (!mounted) return;

    if (result == CropResult.success) {
      // Re-run OCR + entity extraction on the new image.
      setState(() => _processingLabel = 'Re-reading text…');
      final ocr = ref.read(ocrServiceProvider);
      final entityService = ref.read(entityServiceProvider);
      final newText = await ocr.extractText(screenshot.uri);
      final newEntities = await entityService.extract(newText);
      final newTag = ocr.autoTag(newText, entities: newEntities);

      await AppDatabase.instance.updateScreenshot(
        screenshot.copyWith(
          extractedText: newText,
          tag: newTag,
          entities: newEntities,
        ),
      );

      // Drop cached pixels so the new image renders.
      PaintingBinding.instance.imageCache.evict(FileImage(File(screenshot.uri)));
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      if (!mounted) return;

      ref.invalidate(_screenshotDetailProvider(widget.screenshotId));
      // Refresh home grid + downstream consumers (picker, suggestions).
      ref.read(homeProvider.notifier).loadScreenshots();
      ref.invalidate(allScreenshotsProvider);
      ref.invalidate(suggestionsProvider);
    } else if (result == CropResult.noSubjectDetected) {
      onNoSubject?.call();
    } else if (result == CropResult.failed) {
      _showSnack('Crop failed', isError: true);
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _processingLabel = '';
      });
    }
  }

  void _showAddToTasks(Screenshot screenshot) {
    final notifier = ref.read(taskProvider.notifier);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        side: BorderSide(color: AppColors.borderDefault, width: 1),
      ),
      builder: (_) => AddToTasksSheet(
        screenshot: screenshot,
        onCreate: notifier.addTask,
      ),
    );
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: AppTypography.bodySm.copyWith(color: Colors.white)),
        backgroundColor:
            isError ? AppColors.error : AppColors.bgElevated,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_screenshotDetailProvider(widget.screenshotId));

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Stack(
        children: [
          async.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.accent,
              ),
            ),
            error: (e, _) => Center(
              child: Text('Error: $e',
                  style:
                      AppTypography.bodyMd.copyWith(color: AppColors.error)),
            ),
            data: (screenshot) {
              if (screenshot == null) {
                return Center(
                  child: Text('Not found',
                      style: AppTypography.bodyMd
                          .copyWith(color: AppColors.textMuted)),
                );
              }
              return _DetailView(
                screenshot: screenshot,
                onSmartCrop: () => _runSmartCrop(screenshot),
                onManualCrop: () => _runManualCrop(screenshot),
                onAddToTasks: () => _showAddToTasks(screenshot),
              );
            },
          ),
          if (_isProcessing) _ProcessingOverlay(label: _processingLabel),
        ],
      ),
    );
  }
}

class _DetailView extends StatelessWidget {
  final Screenshot screenshot;
  final VoidCallback onSmartCrop;
  final VoidCallback onManualCrop;
  final VoidCallback onAddToTasks;

  const _DetailView({
    required this.screenshot,
    required this.onSmartCrop,
    required this.onManualCrop,
    required this.onAddToTasks,
  });

  static const _topRowHeight = 52.0;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    final imageHeight = screenHeight - topInset - _topRowHeight;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: topInset),

          // Top row — back + note + crop actions
          SizedBox(
            height: _topRowHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
              child: Row(
                children: [
                  _CircleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => context.pop(),
                  ),
                  const Spacer(),
                  _CircleButton(
                    icon: screenshot.isNote
                        ? Icons.edit_note_rounded
                        : Icons.notes_rounded,
                    tooltip: screenshot.isNote ? 'Edit note' : 'Convert to note',
                    onTap: () =>
                        context.push('/notes/edit/${screenshot.id}'),
                  ),
                  const SizedBox(width: 8),
                  _CircleButton(
                    icon: Icons.playlist_add_rounded,
                    tooltip: 'Add to Tasks',
                    onTap: onAddToTasks,
                  ),
                  const SizedBox(width: 8),
                  _CircleButton(
                    icon: Icons.auto_awesome_outlined,
                    tooltip: 'Smart crop',
                    onTap: onSmartCrop,
                  ),
                  const SizedBox(width: 8),
                  _CircleButton(
                    icon: Icons.crop_rounded,
                    tooltip: 'Crop',
                    onTap: onManualCrop,
                  ),
                ],
              ),
            ),
          ),

          // Image — fills the remaining viewport with horizontal padding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: SizedBox(
              height: imageHeight,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _DetailImage(uri: screenshot.uri),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Info panel — content-sized, slides up with the scroll
          _InfoPanel(screenshot: screenshot),

          SizedBox(height: bottomInset + 24),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderDefault, width: 1),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 18),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: button) : button;
  }
}

class _ProcessingOverlay extends StatelessWidget {
  final String label;
  const _ProcessingOverlay({required this.label});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderDefault, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Text(label,
                    style: AppTypography.bodyMd
                        .copyWith(color: AppColors.textPrimary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final Screenshot screenshot;

  const _InfoPanel({required this.screenshot});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.bgBase,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(26, 12, 26, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 3,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.borderEmphasis,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          _InfoRow(
            icon: Icons.sell_outlined,
            label: 'Category',
            child: TagBadge(tag: screenshot.tag),
          ),
          _divider(),

          _InfoRow(
            icon: Icons.access_time_rounded,
            label: 'Captured',
            child: Text(
              DateFormat('MMM d, yyyy · HH:mm').format(screenshot.createdAt),
              style: AppTypography.monoMd,
            ),
          ),

          if (screenshot.entities.isNotEmpty) ...[
            _divider(),
            _EntitiesSection(entities: screenshot.entities),
          ],

          if (screenshot.extractedText.isNotEmpty) ...[
            _divider(),
            _ExtractedTextSection(text: screenshot.extractedText),
          ],
        ],
      ),
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 2),
        child: Divider(color: AppColors.borderSubtle, height: 1),
      );
}

class _EntitiesSection extends StatelessWidget {
  final List<ExtractedEntity> entities;
  const _EntitiesSection({required this.entities});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_outlined,
                  color: AppColors.textMuted, size: 16),
              const SizedBox(width: 12),
              Text('Detected',
                  style: AppTypography.labelMd
                      .copyWith(color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final e in entities) _EntityChip(entity: e),
            ],
          ),
        ],
      ),
    );
  }
}

class _EntityChip extends StatelessWidget {
  final ExtractedEntity entity;
  const _EntityChip({required this.entity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderDefault, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(entity.type),
              size: 12, color: AppColors.accentText),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              _displayText(entity),
              style: AppTypography.labelSm
                  .copyWith(color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'money':
        return Icons.payments_outlined;
      case 'date':
        return Icons.calendar_today_outlined;
      case 'url':
      case 'qr_url':
        return Icons.link_rounded;
      case 'phone':
      case 'qr_phone':
        return Icons.phone_outlined;
      case 'flight':
        return Icons.flight_takeoff_outlined;
      case 'email':
      case 'qr_email':
        return Icons.alternate_email_rounded;
      case 'address':
        return Icons.location_on_outlined;
      case 'tracking':
        return Icons.local_shipping_outlined;
      case 'iban':
      case 'payment_card':
        return Icons.credit_card_rounded;
      case 'isbn':
        return Icons.menu_book_outlined;
      case 'portrait':
        return Icons.person_outline_rounded;
      case 'qr_payment':
        return Icons.payments_rounded;
      case 'qr_wifi':
        return Icons.wifi_rounded;
      case 'qr_contact':
        return Icons.person_add_rounded;
      case 'qr':
        return Icons.qr_code_rounded;
    }
    return Icons.label_outline_rounded;
  }

  String _displayText(ExtractedEntity e) {
    switch (e.type) {
      case 'flight':
        final airline = e.value?['airline'] as String?;
        final number = e.value?['number'] as String?;
        if (airline != null && number != null) return '$airline$number';
        return e.rawText;
      case 'date':
        final ts = e.value?['timestamp'] as int?;
        if (ts != null) {
          final dt = DateTime.fromMillisecondsSinceEpoch(ts);
          return DateFormat('MMM d, yyyy').format(dt);
        }
        return e.rawText;
    }
    return e.rawText;
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 16),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(label,
                style: AppTypography.labelMd
                    .copyWith(color: AppColors.textMuted)),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _ExtractedTextSection extends StatefulWidget {
  final String text;
  const _ExtractedTextSection({required this.text});

  @override
  State<_ExtractedTextSection> createState() => _ExtractedTextSectionState();
}

class _ExtractedTextSectionState extends State<_ExtractedTextSection> {
  bool _expanded = false;
  bool _justCopied = false;

  Future<void> _copyAll() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;
    setState(() => _justCopied = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _justCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final preview = widget.text.length > 200
        ? '${widget.text.substring(0, 200)}…'
        : widget.text;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.text_snippet_outlined,
                  color: AppColors.textMuted, size: 16),
              const SizedBox(width: 12),
              Text('Extracted text',
                  style: AppTypography.labelMd
                      .copyWith(color: AppColors.textMuted)),
              const Spacer(),
              _IconAction(
                icon: _justCopied ? Icons.check_rounded : Icons.copy_rounded,
                label: _justCopied ? 'Copied' : 'Copy',
                onTap: _copyAll,
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded ? 'Show less' : 'Show more',
                  style: AppTypography.labelSm
                      .copyWith(color: AppColors.accentText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SelectableTextBox(text: _expanded ? widget.text : preview),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.accentText),
          const SizedBox(width: 4),
          Text(label,
              style: AppTypography.labelSm
                  .copyWith(color: AppColors.accentText)),
        ],
      ),
    );
  }
}

class _SelectableTextBox extends StatelessWidget {
  final String text;
  const _SelectableTextBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderDefault, width: 1),
      ),
      child: SelectableText(
        text,
        style: AppTypography.monoMd,
        cursorColor: AppColors.accent,
        selectionControls: MaterialTextSelectionControls(),
      ),
    );
  }
}

class _DetailImage extends StatelessWidget {
  final String uri;
  const _DetailImage({required this.uri});

  @override
  Widget build(BuildContext context) {
    final isLocal = !uri.startsWith('http');
    if (isLocal) {
      return Image.file(
        File(uri),
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => Container(color: AppColors.bgSurface),
      );
    }
    return Image.network(
      uri,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => Container(color: AppColors.bgSurface),
    );
  }
}
