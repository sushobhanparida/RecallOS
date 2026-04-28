import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/suggestion_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../shared/widgets/empty_state.dart';
import 'stacks_provider.dart';
import 'widgets/stack_card.dart';
import 'widgets/suggestion_card.dart';

class StacksScreen extends ConsumerWidget {
  const StacksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stacksProvider);
    final notifier = ref.read(stacksProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Stacks', style: AppTypography.displayMd),
                      const SizedBox(height: 2),
                      Text('Your collections',
                          style: AppTypography.bodyMd
                              .copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const _SuggestionsSection(),
            Expanded(
              child: state.error != null
                  ? _ErrorState(
                      message: state.error!,
                      onRetry: notifier.load,
                    )
                  : state.isLoading && state.stacks.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppColors.accent,
                          ),
                        )
                      : state.stacks.isEmpty
                          ? const EmptyState(
                              icon: Icons.layers_outlined,
                              title: 'No stacks yet',
                              subtitle:
                                  'Create a stack to organize your screenshots',
                            )
                          : GridView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(22, 0, 22, 100),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: state.stacks.length,
                      itemBuilder: (context, i) {
                        final s = state.stacks[i];
                        return StackCard(
                          stack: s,
                          onTap: () =>
                              context.push('/stack/${s.id}'),
                          onDelete: () =>
                              notifier.deleteStack(s.id!),
                          onRename: () =>
                              _showRenameDialog(context, ref, s.id!, s.name),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add_rounded, size: 22),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    _showNameDialog(
      context: context,
      title: 'New Stack',
      hint: 'Stack name',
      actionLabel: 'Create',
      onConfirm: (name) =>
          ref.read(stacksProvider.notifier).createStack(name),
    );
  }

  void _showRenameDialog(
      BuildContext context, WidgetRef ref, int id, String current) {
    _showNameDialog(
      context: context,
      title: 'Rename Stack',
      hint: current,
      actionLabel: 'Save',
      onConfirm: (name) =>
          ref.read(stacksProvider.notifier).renameStack(id, name),
    );
  }

  void _showNameDialog({
    required BuildContext context,
    required String title,
    required String hint,
    required String actionLabel,
    required void Function(String) onConfirm,
  }) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderDefault, width: 1),
        ),
        title: Text(title, style: AppTypography.headingMd),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary),
          cursorColor: AppColors.accent,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.textMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: AppTypography.labelLg
                    .copyWith(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                onConfirm(name);
                Navigator.pop(context);
              }
            },
            child: Text(actionLabel,
                style: AppTypography.labelLg
                    .copyWith(color: AppColors.accentText)),
          ),
        ],
      ),
    ).whenComplete(ctrl.dispose);
  }
}

class _SuggestionsSection extends ConsumerWidget {
  const _SuggestionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(suggestionsProvider);
    final suggestions = async.value ?? const <StackSuggestion>[];
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_outlined,
                    size: 14, color: AppColors.accentText),
                const SizedBox(width: 6),
                Text('Suggested for you',
                    style: AppTypography.labelLg
                        .copyWith(color: AppColors.textPrimary)),
                const SizedBox(width: 6),
                Text('${suggestions.length}',
                    style: AppTypography.monoSm
                        .copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          SizedBox(
            height: 196,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final s = suggestions[i];
                return SuggestionCard(
                  suggestion: s,
                  onAccept: () async {
                    final id = await ref
                        .read(stacksProvider.notifier)
                        .acceptSuggestion(s);
                    if (id != null && context.mounted) {
                      context.push('/stack/$id');
                    }
                  },
                  onDismiss: () =>
                      ref.read(stacksProvider.notifier).dismissSuggestion(s),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 32),
            const SizedBox(height: 12),
            Text("Couldn't load stacks",
                style: AppTypography.headingSm
                    .copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTypography.bodySm
                    .copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: Text('Retry',
                  style: AppTypography.labelLg
                      .copyWith(color: AppColors.accentText)),
            ),
          ],
        ),
      ),
    );
  }
}
