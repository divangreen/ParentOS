import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/children_provider.dart';

class ChildProfileScreen extends ConsumerWidget {
  const ChildProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenState = ref.watch(childrenControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Child Profile')),
      body: switch (childrenState) {
        ChildrenLoading() => const Center(child: CircularProgressIndicator()),
        ChildrenError(:final message) => Center(child: Text('Error: $message')),
        ChildrenLoaded(:final activeChild) when activeChild == null =>
          const Center(child: Text('No child added yet')),
        ChildrenLoaded(:final activeChild) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${activeChild!.name}'),
                const SizedBox(height: 8),
                Text('Date of birth: ${activeChild.dateOfBirth.toLocal().toString().split(' ').first}'),
                const SizedBox(height: 8),
                Text('Age: ${activeChild.ageDays} days'),
                if (activeChild.birthWeightKg != null) ...[
                  const SizedBox(height: 8),
                  Text('Birth weight: ${activeChild.birthWeightKg} kg'),
                ],
              ],
            ),
          ),
      },
    );
  }
}
