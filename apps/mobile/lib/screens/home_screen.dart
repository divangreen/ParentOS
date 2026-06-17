import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    if (authState is AuthInitial) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final userId = authState is AuthAuthenticated ? authState.userId : null;

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
      body: Center(
        child: Text(userId == null ? 'Not signed in' : 'Signed in as $userId'),
      ),
    );
  }
}
