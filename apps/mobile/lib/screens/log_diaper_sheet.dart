import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/diapers_provider.dart';
import '../services/api_client.dart';

Future<void> showLogDiaperSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    builder: (context) => const _LogDiaperSheet(),
  );
}

class _LogDiaperSheet extends ConsumerStatefulWidget {
  const _LogDiaperSheet();

  @override
  ConsumerState<_LogDiaperSheet> createState() => _LogDiaperSheetState();
}

class _LogDiaperSheetState extends ConsumerState<_LogDiaperSheet> {
  DateTime _loggedAt = DateTime.now();
  bool _isSubmitting = false;
  String? _error;

  Future<void> _editTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _loggedAt,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_loggedAt));
    if (time == null) return;
    setState(() {
      _loggedAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _logType(String type) async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await ref.read(diapersControllerProvider.notifier).logDiaper(type, loggedAt: _loggedAt);
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
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Log Diaper', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Time: ${_fmt(_loggedAt)}'),
            trailing: const Icon(Icons.edit),
            onTap: _editTime,
          ),
          const SizedBox(height: 8),
          Text('Tap a type to save immediately', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _DiaperButton(label: 'Wet', icon: Icons.water_drop, onTap: () => _logType('wet')),
              _DiaperButton(label: 'Dirty', icon: Icons.warning_amber, onTap: () => _logType('dirty')),
              _DiaperButton(label: 'Both', icon: Icons.all_inclusive, onTap: () => _logType('both')),
            ],
          ),
          if (_isSubmitting) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    );
  }
}

class _DiaperButton extends StatelessWidget {
  const _DiaperButton({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton.filledTonal(icon: Icon(icon), iconSize: 32, onPressed: onTap),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }
}
