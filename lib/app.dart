import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/colors.dart';
import 'core/theme/typography.dart';
import 'features/home/home_screen.dart';
import 'features/task/task_screen.dart';
import 'features/stacks/stacks_screen.dart';
import 'features/screenshot_detail/screenshot_detail_screen.dart';
import 'features/stack_detail/stack_detail_screen.dart';
import 'features/notes/note_picker_screen.dart';
import 'features/notes/note_editor_screen.dart';

final _router = GoRouter(
  initialLocation: '/home',
  redirect: (context, state) {
    if (state.uri.path == '/todo') return '/tasks';
    return null;
  },
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _AppShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const HomeScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/tasks',
            builder: (_, __) => const TaskScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/stacks',
            builder: (_, __) => const StacksScreen(),
          ),
        ]),
      ],
    ),
    GoRoute(
      path: '/screenshot/:id',
      builder: (_, state) => ScreenshotDetailScreen(
        screenshotId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/stack/:id',
      builder: (_, state) => StackDetailScreen(
        stackId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/notes/picker',
      builder: (_, __) => const NotePickerScreen(),
    ),
    GoRoute(
      path: '/notes/edit/:id',
      builder: (_, state) => NoteEditorScreen(
        screenshotId: int.parse(state.pathParameters['id']!),
      ),
    ),
  ],
);

class RecallOSApp extends StatelessWidget {
  const RecallOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RecallOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: _router,
    );
  }
}

class _AppShell extends StatelessWidget {
  final StatefulNavigationShell shell;

  const _AppShell({required this.shell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: _LinearNavBar(
        currentIndex: shell.currentIndex,
        onTap: (i) => shell.goBranch(
          i,
          initialLocation: i == shell.currentIndex,
        ),
      ),
    );
  }
}

class _LinearNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.grid_view_rounded, Icons.grid_view_rounded, 'Home'),
    (Icons.check_circle_outline_rounded, Icons.check_circle_rounded, 'Tasks'),
    (Icons.layers_outlined, Icons.layers_rounded, 'Stacks'),
  ];

  const _LinearNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(
          top: BorderSide(color: AppColors.borderDefault, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: List.generate(_items.length, (i) {
              final (outlinedIcon, filledIcon, label) = _items[i];
              final isSelected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        child: Icon(
                          isSelected ? filledIcon : outlinedIcon,
                          key: ValueKey(isSelected),
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        style: AppTypography.labelSm.copyWith(
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
