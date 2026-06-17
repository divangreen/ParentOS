import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/feedings_provider.dart';
import '../services/api_client.dart';

Future<void> showLogFeedSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _LogFeedSheet(),
  );
}

class _LogFeedSheet extends ConsumerStatefulWidget {
  const _LogFeedSheet();

  @override
  ConsumerState<_LogFeedSheet> createState() => _LogFeedSheetState();
}

class _LogFeedSheetState extends ConsumerState<_LogFeedSheet> {
  String _type = 'breast';
  String _side = 'left';
  final _durationController = TextEditingController(text: '15');
  final _volumeController = TextEditingController(text: '90');
  String _milkType = 'breast_milk';
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _durationController.dispose();
    _volumeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await ref.read(feedingsControllerProvider.notifier).logFeeding(
            type: _type,
            side: _type == 'breast' ? _side : null,
            durationMinutes: _type == 'breast' ? int.tryParse(_durationController.text) : null,
            volumeMl: _type == 'bottle' ? int.tryParse(_volumeController.text) : null,
            milkType: _type == 'bottle' ? _milkType : null,
          );
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Log Feed', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'breast', label: Text('Breast')),
              ButtonSegment(value: 'bottle', label: Text('Bottle')),
            ],
            selected: {_type},
            onSelectionChanged: (selection) => setState(() => _type = selection.first),
          ),
          const SizedBox(height: 16),
          if (_type == 'breast') ...[
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'left', label: Text('Left')),
                ButtonSegment(value: 'right', label: Text('Right')),
                ButtonSegment(value: 'both', label: Text('Both')),
              ],
              selected: {_side},
              onSelectionChanged: (selection) => setState(() => _side = selection.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Duration (minutes)'),
            ),
          ] else ...[
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'breast_milk', label: Text('Breast Milk')),
                ButtonSegment(value: 'formula', label: Text('Formula')),
              ],
              selected: {_milkType},
              onSelectionChanged: (selection) => setState(() => _milkType = selection.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _volumeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Volume (ml)'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
