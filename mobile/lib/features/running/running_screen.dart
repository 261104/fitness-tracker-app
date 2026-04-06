import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../models/workout_entry.dart';
import '../../providers/providers.dart';

class RunningScreen extends ConsumerStatefulWidget {
  const RunningScreen({super.key});

  @override
  ConsumerState<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends ConsumerState<RunningScreen> {
  bool _active = false;
  DateTime? _started;
  Timer? _pulse;

  @override
  void dispose() {
    _pulse?.cancel();
    super.dispose();
  }

  Future<void> _toggle() async {
    final run = ref.read(locationRunServiceProvider);
    if (!_active) {
      final ok = await run.ensurePermission();
      if (!ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Location permission needed for running')),
          );
        }
        return;
      }
      await run.startTracking();
      _pulse?.cancel();
      _pulse = Timer.periodic(const Duration(milliseconds: 800), (_) {
        if (mounted) setState(() {});
      });
      setState(() {
        _active = true;
        _started = DateTime.now();
      });
    } else {
      _pulse?.cancel();
      _pulse = null;
      await run.stopTracking();
      final weight =
          ref.read(userProfileProvider).asData?.value.weightKg ?? 70;
      final kcal = run.estimateRunCalories(weight);
      final km = run.distanceMeters / 1000;
      final pace = run.paceMinPerKm();
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Run summary'),
            content: Text(
              '${km.toStringAsFixed(2)} km\n'
              '${kcal.toStringAsFixed(0)} kcal (estimate)\n'
              '${pace != null ? '${pace.toStringAsFixed(1)} min/km' : 'Pace: n/a'}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
              FilledButton(
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null && km > 0.05) {
                    final mins = _started != null
                        ? DateTime.now().difference(_started!).inMinutes
                        : 1;
                    final id = const Uuid().v4();
                    final w = WorkoutEntry(
                      id: id,
                      name: 'Outdoor run',
                      type: 'running',
                      durationMinutes: mins.clamp(1, 600),
                      caloriesBurned: kcal,
                      startedAt: _started ?? DateTime.now(),
                    );
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('workouts')
                        .doc(id)
                        .set(w.toFirestore());
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save run'),
              ),
            ],
          ),
        );
      }
      setState(() {
        _active = false;
        _started = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final run = ref.watch(locationRunServiceProvider);
    final km = run.distanceMeters / 1000;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    '${km.toStringAsFixed(2)} km',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.purple,
                        ),
                  ),
                  Text(
                    _active ? 'Tracking GPS…' : 'Ready when you are',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _toggle,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: _active ? AppColors.green : AppColors.purple,
            ),
            icon: Icon(_active ? Icons.stop_rounded : Icons.play_arrow_rounded),
            label: Text(_active ? 'Stop & review' : 'Start run'),
          ),
          const SizedBox(height: 16),
          Text(
            'Fine location is used only while you track a run. Distance uses GPS points between updates.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        ],
      ),
    );
  }
}
