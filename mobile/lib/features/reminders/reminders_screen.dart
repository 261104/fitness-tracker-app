import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../services/notification_service.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({
    super.key,
    required this.stepsToday,
    required this.stepGoal,
    required this.workoutsThisWeek,
  });

  final int stepsToday;
  final int stepGoal;
  final int workoutsThisWeek;

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  Map<String, dynamic>? _suggestion;
  bool _loading = false;
  int _hour = 18;
  int _minute = 30;

  Future<void> _fetchAi() async {
    setState(() => _loading = true);
    final api = ref.read(backendApiProvider);
    final res = await api.suggestReminders(
      stepsToday: widget.stepsToday,
      stepGoal: widget.stepGoal,
      workoutsThisWeek: widget.workoutsThisWeek,
    );
    if (mounted) {
      setState(() {
        _suggestion = res;
        _loading = false;
        final h = res?['suggestedHour'];
        final m = res?['suggestedMinute'];
        if (h is int) _hour = h;
        if (h is num) _hour = h.toInt();
        if (m is int) _minute = m;
        if (m is num) _minute = m.toInt();
      });
    }
  }

  Future<void> _schedule() async {
    final title = _suggestion?['title'] as String? ?? 'Fitness Freak';
    final body = _suggestion?['body'] as String? ?? 'Time to move — small wins count.';
    await scheduleReminder(
      id: 901,
      title: title,
      body: body,
      hour: _hour,
      minute: _minute,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminder set for $_hour:${_minute.toString().padLeft(2, '0')} daily'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart reminders'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            color: AppColors.lavenderSoft,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Context',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text('Steps today: ${widget.stepsToday} / ${widget.stepGoal}'),
                  Text('Workouts this week: ${widget.workoutsThisWeek}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loading ? null : _fetchAi,
            style: FilledButton.styleFrom(backgroundColor: AppColors.purple),
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : const Icon(Icons.psychology_outlined),
            label: Text(_loading ? 'Thinking…' : 'Get suggestion (server / heuristic)'),
          ),
          if (_suggestion != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _suggestion!['title'] as String? ?? 'Move',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(_suggestion!['body'] as String? ?? ''),
                    if (_suggestion!['source'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Source: ${_suggestion!['source']}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Schedule daily notification',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Time'),
              subtitle: Text(
                '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.schedule_rounded),
              onTap: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: _hour, minute: _minute),
                );
                if (t != null) {
                  setState(() {
                    _hour = t.hour;
                    _minute = t.minute;
                  });
                }
              },
            ),
            FilledButton.icon(
              onPressed: _schedule,
              style: FilledButton.styleFrom(backgroundColor: AppColors.green),
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Enable daily reminder'),
            ),
          ],
        ],
      ),
    );
  }
}
