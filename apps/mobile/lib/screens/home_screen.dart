import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/children_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _formatAge(int ageDays) {
    if (ageDays < 14) return '$ageDays day${ageDays == 1 ? '' : 's'} old';
    final weeks = ageDays ~/ 7;
    return '$weeks week${weeks == 1 ? '' : 's'} old';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    if (authState is AuthInitial) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final childrenState = ref.watch(childrenControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ParentOS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: switch (childrenState) {
        ChildrenLoading() => const Center(child: CircularProgressIndicator()),
        ChildrenError(:final message) => Center(child: Text('Error: $message')),
        ChildrenLoaded(:final activeChild) when activeChild == null => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No children added yet'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go('/add-child'),
                  child: const Text('Add Child'),
                ),
              ],
            ),
          ),
        ChildrenLoaded(:final activeChild) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(activeChild!.name, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(_formatAge(activeChild.ageDays)),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/child'),
                  child: const Text('View Profile'),
                ),
              ],
            ),
          ),
      },
    );
  }
}
