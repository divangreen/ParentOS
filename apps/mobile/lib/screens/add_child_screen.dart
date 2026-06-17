import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/children_provider.dart';
import '../services/api_client.dart';

class AddChildScreen extends ConsumerStatefulWidget {
  const AddChildScreen({super.key});

  @override
  ConsumerState<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends ConsumerState<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  DateTime? _dateOfBirth;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 366)),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateOfBirth == null) {
      setState(() => _error = 'Date of birth is required');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final weightText = _weightController.text.trim();
      await ref.read(childrenControllerProvider.notifier).addChild(
            name: _nameController.text.trim(),
            dateOfBirth: _dateOfBirth!,
            birthWeightKg: weightText.isEmpty ? null : double.tryParse(weightText),
          );
      if (mounted) context.go('/');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Child')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _dateOfBirth == null
                      ? 'Select date of birth'
                      : 'Date of birth: ${_dateOfBirth!.toLocal().toString().split(' ').first}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDateOfBirth,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Birth weight (kg, optional)',
                  hintText: '0.5 - 6.0',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null || parsed < 0.5 || parsed > 6.0) {
                    return 'Enter a weight between 0.5 and 6.0 kg';
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Add Child'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
