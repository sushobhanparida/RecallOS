import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/services/smart_actions_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

class SmartActionsBanner extends StatelessWidget {
  final List<SmartAction> actions;
  final void Function(SmartAction) onExecute;
  final void Function(SmartAction) onOpen;

  const SmartActionsBanner({
    super.key,
    required this.actions,
    required this.onExecute,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
            child: Text('Actions',
                style: AppTypography.labelLg
                    .copyWith(color: AppColors.textSecondary)),
          ),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              itemCount: actions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final a = actions[i];
                return _ActionCard(
                  action: a,
                  onExecute: () => onExecute(a),
                  onOpen: () => onOpen(a),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final SmartAction action;
  final VoidCallback onExecute;
  final VoidCallback onOpen;

  const _ActionCard({
    required this.action,
    required this.onExecute,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        width: 290,
        padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderDefault, width: 1),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 76,
                child: _Thumb(uri: action.screenshot.uri),
              ),
            ),
            const SizedBox(width: 12),
            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    action.title,
                    style: AppTypography.labelLg
                        .copyWith(color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    action.subtitle,
                    style: AppTypography.labelSm
                        .copyWith(color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onExecute,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(action.icon, size: 12, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(action.label,
                              style: AppTypography.labelSm
                                  .copyWith(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
      return Image.network(uri,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Container(color: AppColors.bgElevated));
    }
    return Image.file(File(uri),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: AppColors.bgElevated));
  }
}
