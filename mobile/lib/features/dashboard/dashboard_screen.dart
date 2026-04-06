import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../utils/calories.dart';
import '../reminders/reminders_screen.dart';

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepsAsync = ref.watch(stepCountProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final workoutsAsync = ref.watch(workoutsProvider);
    final dailyBackend = ref.watch(dailyStatsBackendProvider);
    final weeklyBackend = ref.watch(weeklyStatsBackendProvider);

    final profile = profileAsync.asData?.value;
    final weight = profile?.weightKg ?? 70;

    final steps = stepsAsync.asData?.value ?? 0;
    final workouts = workoutsAsync.asData?.value ?? const [];
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final workoutsThisWeek =
        workouts.where((w) => !w.startedAt.isBefore(weekStart)).length;
    final todayWorkoutCal = workouts
        .where((w) => _sameDay(w.startedAt, now))
        .fold<double>(0, (a, w) => a + w.caloriesBurned);
    final stepsCal = caloriesFromSteps(steps, weight);
    final totalCal = stepsCal + todayWorkoutCal;

    return RefreshIndicator(
      color: AppColors.purple,
      onRefresh: () async {
        ref.invalidate(dailyStatsBackendProvider);
        ref.invalidate(weeklyStatsBackendProvider);
        final api = ref.read(backendApiProvider);
        final workoutsToday =
            workouts.where((w) => _sameDay(w.startedAt, now)).length;
        await api.syncDailyStats(
          steps: steps,
          workoutCalories: todayWorkoutCal,
          stepsCalories: stepsCal,
          workoutCount: workoutsToday,
        );
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _HeroCard(
            steps: steps,
            goal: profile?.dailyStepGoal ?? 8000,
            totalCal: totalCal,
          ),
          const SizedBox(height: 16),
          Text(
            'Today',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Steps kcal',
                  value: stepsCal.toStringAsFixed(0),
                  icon: Icons.local_fire_department_outlined,
                  tint: AppColors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  label: 'Workout kcal',
                  value: todayWorkoutCal.toStringAsFixed(0),
                  icon: Icons.sports_gymnastics_rounded,
                  tint: AppColors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'This week',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Workouts',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                              ),
                        ),
                        Text(
                          '$workoutsThisWeek',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  weeklyBackend.when(
                    data: (m) => Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Avg steps (server)',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                          Text(
                            m == null
                                ? '—'
                                : '${(m['avgSteps'] as num?)?.round() ?? '—'}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    loading: () => const Expanded(
                      child: Text('…'),
                    ),
                    error: (_, __) => const Expanded(
                      child: Text('—'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          dailyBackend.when(
            data: (m) {
              if (m == null) {
                return const _BackendHint();
              }
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.cloud_done_rounded,
                      color: AppColors.green),
                  title: const Text('PostgreSQL sync'),
                  subtitle: Text(
                    'Steps ${m['steps'] ?? '—'} · Total kcal ${m['totalCalories'] ?? '—'}',
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const _BackendHint(),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.auto_awesome, color: AppColors.purple),
              title: const Text('Smart reminders'),
              subtitle: const Text(
                'AI-style suggestions from your activity + optional server',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RemindersScreen(
                      stepsToday: steps,
                      stepGoal: profile?.dailyStepGoal ?? 8000,
                      workoutsThisWeek: workoutsThisWeek,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BackendHint extends StatelessWidget {
  const _BackendHint();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.lavenderSoft,
      child: ListTile(
        leading: Icon(Icons.info_outline, color: AppColors.purple.withValues(alpha: 0.8)),
        title: const Text('Backend stats'),
        subtitle: const Text(
          'Start the Node server and pull to refresh to see synced daily/weekly aggregates.',
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.steps,
    required this.goal,
    required this.totalCal,
  });

  final int steps;
  final int goal;
  final double totalCal;

  @override
  Widget build(BuildContext context) {
    final progress = (steps / goal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.purpleDeep, AppColors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$steps',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(
            'steps today · goal $goal',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.lavender,
                ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.white.withValues(alpha: 0.25),
              color: AppColors.greenLight,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Est. burn today: ${totalCal.toStringAsFixed(0)} kcal',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: tint),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
