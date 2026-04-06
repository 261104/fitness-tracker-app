import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../models/workout_entry.dart';
import '../../utils/calories.dart';

class AddWorkoutSheet extends StatefulWidget {
  const AddWorkoutSheet({super.key, required this.weightKg});

  final double weightKg;

  @override
  State<AddWorkoutSheet> createState() => _AddWorkoutSheetState();
}

class _AddWorkoutSheetState extends State<AddWorkoutSheet> {
  final _name = TextEditingController(text: 'Morning session');
  final _minutes = TextEditingController(text: '30');
  String _type = 'strength';

  @override
  void dispose() {
    _name.dispose();
    _minutes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mins = int.tryParse(_minutes.text) ?? 0;
    final cal = caloriesFromWorkoutMinutes(
      type: _type,
      minutes: mins,
      weightKg: widget.weightKg,
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Log workout',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _type,
            decoration: const InputDecoration(
              labelText: 'Type',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'strength', child: Text('Strength')),
              DropdownMenuItem(value: 'running', child: Text('Running')),
              DropdownMenuItem(value: 'walking', child: Text('Walking')),
              DropdownMenuItem(value: 'cycling', child: Text('Cycling')),
              DropdownMenuItem(value: 'hiit', child: Text('HIIT')),
              DropdownMenuItem(value: 'yoga', child: Text('Yoga')),
            ],
            onChanged: (v) => setState(() => _type = v ?? _type),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _minutes,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Minutes',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Text(
            'Est. ${cal.toStringAsFixed(0)} kcal (MET-based)',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.green,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              final id = const Uuid().v4();
              final entry = WorkoutEntry(
                id: id,
                name: _name.text.trim().isEmpty ? 'Workout' : _name.text.trim(),
                type: _type,
                durationMinutes: mins,
                caloriesBurned: cal,
                startedAt: DateTime.now(),
              );
              Navigator.pop(context, entry);
            },
            child: const Text('Save to Firestore'),
          ),
        ],
      ),
    );
  }
}
