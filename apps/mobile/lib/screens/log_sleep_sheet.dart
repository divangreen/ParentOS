import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/sleeps_provider.dart';
import '../services/api_client.dart';

Future<void> showLogSleepSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _LogSleepSheet(),
  );
}

class _LogSleepSheet extends ConsumerStatefulWidget {
  const _LogSleepSheet();

  @override
  ConsumerState<_LogSleepSheet> createState() => _LogSleepSheetState();
}

class _LogSleepSheetState extends ConsumerState<_LogSleepSheet> {
  String _type = 'nap';
  DateTime _startedAt = DateTime.now().subtract(const Duration(minutes: 30));
  DateTime _endedAt = DateTime.now();
  bool _isSubmitting = false;
  String? _error;

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart ? _startedAt : _endedAt;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) return;
    final combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startedAt = combined;
      } else {
        _endedAt = combined;
      }
    });
  }

  int get _durationMinutes => _endedAt.difference(_startedAt).inMinutes;

  Future<void> _submit() async {
    if (_durationMinutes <= 0) {
      setState(() => _error = 'End time must be after start time');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await ref.read(sleepsControllerProvider.notifier).logSleep(
            type: _type,
            startedAt: _startedAt,
            endedAt: _endedAt,
          );
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _fmt(DateTime dt) => dt.toLocal().toString().substring(0, 16);

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
          Text('Log Sleep', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'nap', label: Text('Nap')),
              ButtonSegment(value: 'night', label: Text('Night')),
            ],
            selected: {_type},
            onSelectionChanged: (selection) => setState(() => _type = selection.first),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Start: ${_fmt(_startedAt)}'),
            trailing: const Icon(Icons.edit),
            onTap: () => _pickTime(true),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('End: ${_fmt(_endedAt)}'),
            trailing: const Icon(Icons.edit),
            onTap: () => _pickTime(false),
          ),
          const SizedBox(height: 8),
          Text('Duration: $_durationMinutes minutes'),
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
