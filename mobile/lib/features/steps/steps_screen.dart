import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../utils/calories.dart';

class StepsScreen extends ConsumerStatefulWidget {
  const StepsScreen({super.key});

  @override
  ConsumerState<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends ConsumerState<StepsScreen> {
  int? _healthSteps;
  bool _loadingHealth = false;
  bool _activityOn = false;

  Future<void> _pullHealth() async {
    setState(() => _loadingHealth = true);
    final h = ref.read(healthSyncServiceProvider);
    final n = await h.todayStepsFromHealth();
    if (mounted) {
      setState(() {
        _healthSteps = n;
        _loadingHealth = false;
      });
    }
  }

  Future<void> _toggleActivity() async {
    final svc = ref.read(activityRecognitionServiceProvider);
    final ok =
        await ref.read(healthSyncServiceProvider).ensureActivityRecognition();
    if (!ok || !mounted) return;
    if (_activityOn) {
      await svc.stop();
      setState(() => _activityOn = false);
    } else {
      await svc.start(foreground: true);
      setState(() => _activityOn = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepsAsync = ref.watch(stepCountProvider);
    final profile = ref.watch(userProfileProvider).asData?.value;
    final weight = profile?.weightKg ?? 70;
    final steps = stepsAsync.asData?.value ?? 0;
    final est = caloriesFromSteps(steps, weight);

    final activitySvc = ref.watch(activityRecognitionServiceProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  '$steps',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.purple,
                      ),
                ),
                Text(
                  'pedometer steps today',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  '≈ ${est.toStringAsFixed(0)} kcal from steps',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.green,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_healthSteps != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.favorite_outline, color: AppColors.purple),
              title: const Text('Health Connect'),
              subtitle: Text('$_healthSteps steps today (aggregated)'),
            ),
          ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _loadingHealth ? null : _pullHealth,
          icon: _loadingHealth
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync_rounded),
          label: Text(_loadingHealth ? 'Reading…' : 'Sync from Health Connect'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.purple,
            foregroundColor: AppColors.white,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Activity recognition',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          value: _activityOn,
          activeThumbColor: AppColors.green,
          title: const Text('Detect walking / running (foreground service)'),
          subtitle: Text(
            activitySvc.lastEvent?.toString() ?? 'Uses device motion APIs',
          ),
          onChanged: (_) => _toggleActivity(),
        ),
        const SizedBox(height: 12),
        StreamBuilder<ActivityEvent>(
          stream: activitySvc.events,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const SizedBox.shrink();
            }
            final e = snap.data!;
            return Card(
              color: AppColors.greenLight,
              child: ListTile(
                leading: const Icon(Icons.directions_run, color: AppColors.green),
                title: Text(e.typeString),
                subtitle: Text('Confidence ${e.confidence}%'),
              ),
            );
          },
        ),
      ],
    );
  }
}
