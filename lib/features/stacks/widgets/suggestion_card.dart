import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/services/suggestion_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

class SuggestionCard extends StatelessWidget {
  final StackSuggestion suggestion;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  const SuggestionCard({
    super.key,
    required this.suggestion,
    required this.onAccept,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final previews = suggestion.screenshots.take(3).toList();

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderDefault, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Preview strip + dismiss button
          Stack(
            children: [
              SizedBox(
                height: 90,
                child: Row(
                  children: List.generate(3, (i) {
                    final isLast = i == 2;
                    if (i >= previews.length) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: isLast ? 0 : 1),
                          child: Container(color: AppColors.bgElevated),
                        ),
                      );
                    }
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: isLast ? 0 : 1),
                        child: _Thumb(uri: previews[i].uri),
                      ),
                    );
                  }),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: onDismiss,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 12, color: Colors.white),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome_outlined,
                          size: 10, color: Colors.white),
                      const SizedBox(width: 3),
                      Text('Suggested',
                          style: AppTypography.labelSm
                              .copyWith(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.name,
                  style: AppTypography.labelLg
                      .copyWith(color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${suggestion.screenshots.length} screenshots',
                  style: AppTypography.labelSm
                      .copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: onAccept,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Create stack',
                      style: AppTypography.labelMd
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String uri;
  const _Thumb({required this.uri});

  @override
  Widget build(BuildContext context) {
    if (uri.startsWith('http')) {
      return Image.network(
        uri,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: AppColors.bgElevated),
      );
    }
    return Image.file(
      File(uri),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: AppColors.bgElevated),
    );
  }
}
