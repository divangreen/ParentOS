import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/children_provider.dart';
import '../providers/diapers_provider.dart';
import '../providers/feedings_provider.dart';
import '../providers/sleeps_provider.dart';
import 'log_diaper_sheet.dart';
import 'log_feed_sheet.dart';
import 'log_sleep_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

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
        ChildrenLoaded(:final activeChild) => _Dashboard(childName: activeChild!.name, ageDays: activeChild.ageDays),
      },
    );
  }
}

class _Dashboard extends ConsumerWidget {
  const _Dashboard({required this.childName, required this.ageDays});

  final String childName;
  final int ageDays;

  String _formatAge(int ageDays) {
    if (ageDays < 14) return '$ageDays day${ageDays == 1 ? '' : 's'} old';
    final weeks = ageDays ~/ 7;
    return '$weeks week${weeks == 1 ? '' : 's'} old';
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedingsState = ref.watch(feedingsControllerProvider);
    final sleepsState = ref.watch(sleepsControllerProvider);
    final diapersState = ref.watch(diapersControllerProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Column(
            children: [
              Text(childName, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(_formatAge(ageDays)),
              TextButton(
                onPressed: () => context.go('/child'),
                child: const Text('View Profile'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.local_drink),
            title: const Text('Feedings'),
            subtitle: switch (feedingsState) {
              FeedingsLoading() => const Text('Loading...'),
              FeedingsError(:final message) => Text('Error: $message'),
              FeedingsLoaded(:final lastFeeding, :final todayCount) => Text(
                  lastFeeding == null
                      ? 'No feedings logged today'
                      : 'Last: ${_formatTime(lastFeeding.loggedAt)} • Today: $todayCount',
                ),
            },
            trailing: FilledButton.tonal(
              onPressed: () => showLogFeedSheet(context),
              child: const Text('Log'),
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.bedtime),
            title: const Text('Sleep'),
            subtitle: switch (sleepsState) {
              SleepsLoading() => const Text('Loading...'),
              SleepsError(:final message) => Text('Error: $message'),
              SleepsLoaded(:final lastSleep, :final totalMinutesToday) => Text(
                  lastSleep == null
                      ? 'No sleep logged today'
                      : 'Last: ${_formatTime(lastSleep.startedAt)} • Today: ${totalMinutesToday}min',
                ),
            },
            trailing: FilledButton.tonal(
              onPressed: () => showLogSleepSheet(context),
              child: const Text('Log'),
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.baby_changing_station),
            title: const Text('Diapers'),
            subtitle: switch (diapersState) {
              DiapersLoading() => const Text('Loading...'),
              DiapersError(:final message) => Text('Error: $message'),
              DiapersLoaded(:final wetCount, :final dirtyCount) => Text('Wet: $wetCount • Dirty: $dirtyCount'),
            },
            trailing: FilledButton.tonal(
              onPressed: () => showLogDiaperSheet(context),
              child: const Text('Log'),
            ),
          ),
        ),
      ],
    );
  }
}
