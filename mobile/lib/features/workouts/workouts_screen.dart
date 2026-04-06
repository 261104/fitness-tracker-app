import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/workout_entry.dart';
import '../../providers/providers.dart';
import 'add_workout_sheet.dart';

class WorkoutsScreen extends ConsumerWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(workoutsProvider);
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: listAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Log strength, cardio, or a quick walk — workouts sync to Firestore.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final w = list[i];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.lavender,
                    child: Icon(
                      Icons.sports_rounded,
                      color: AppColors.purple,
                    ),
                  ),
                  title: Text(w.name),
                  subtitle: Text(
                    '${w.type} · ${w.durationMinutes} min · ${w.caloriesBurned.toStringAsFixed(0)} kcal',
                  ),
                  trailing: Text(
                    DateFormat.MMMd().format(w.startedAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 24,
          child: FloatingActionButton.extended(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;
              final profile = ref.read(userProfileProvider).asData?.value;
              final created = await showModalBottomSheet<WorkoutEntry>(
                context: context,
                isScrollControlled: true,
                builder: (ctx) =>
                    AddWorkoutSheet(weightKg: profile?.weightKg ?? 70),
              );
              if (created == null || !context.mounted) return;
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('workouts')
                  .doc(created.id)
                  .set(created.toFirestore());
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Log workout'),
          ),
        ),
      ],
    );
  }
}
