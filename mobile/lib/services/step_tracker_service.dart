import 'dart:async';

import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StepTrackerService {
  StepTrackerService._();
  static final StepTrackerService instance = StepTrackerService._();

  static const _kDate = 'ff_step_baseline_date';
  static const _kBaseline = 'ff_step_baseline_raw';

  StreamSubscription<StepCount>? _sub;
  final _controller = StreamController<int>.broadcast();
  int _todaySteps = 0;

  Stream<int> get stepsStream => _controller.stream;
  int get todaySteps => _todaySteps;

  Future<void> start() async {
    await _sub?.cancel();
    final prefs = await SharedPreferences.getInstance();

    _sub = Pedometer.stepCountStream.listen(
      (StepCount event) async {
        final raw = event.steps;
        final today = _todayKey();
        var savedDate = prefs.getString(_kDate);
        var baseline = prefs.getInt(_kBaseline) ?? 0;

        if (savedDate != today) {
          savedDate = today;
          baseline = raw;
          await prefs.setString(_kDate, today);
          await prefs.setInt(_kBaseline, baseline);
        }

        if (raw < baseline) {
          baseline = raw;
          await prefs.setInt(_kBaseline, baseline);
        }

        _todaySteps = (raw - baseline).clamp(0, 200000);
        if (!_controller.isClosed) _controller.add(_todaySteps);
      },
      onError: (_) {
        if (!_controller.isClosed) _controller.add(0);
      },
    );
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
