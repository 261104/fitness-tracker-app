import 'dart:io';

import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

/// Optional Google Health Connect sync (Android). Falls back silently if unavailable.
class HealthSyncService {
  HealthSyncService() : _health = Health();

  final Health _health;
  bool _configured = false;

  Future<void> configureIfNeeded() async {
    if (!Platform.isAndroid || _configured) return;
    await _health.configure();
    _configured = true;
  }

  Future<int?> todayStepsFromHealth() async {
    if (!Platform.isAndroid) return null;
    try {
      await configureIfNeeded();
      final available = await _health.isHealthConnectAvailable();
      if (!available) return null;

      final types = [HealthDataType.STEPS];
      final granted = await _health.requestAuthorization(types);
      if (!granted) return null;

      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final total = await _health.getTotalStepsInInterval(start, now);
      return total;
    } catch (_) {
      return null;
    }
  }

  Future<bool> ensureActivityRecognition() async {
    final status = await Permission.activityRecognition.request();
    return status.isGranted;
  }
}
