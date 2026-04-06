import 'dart:async';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

class RunPoint {
  RunPoint(this.lat, this.lng, this.time);
  final double lat;
  final double lng;
  final DateTime time;
}

class LocationRunService {
  StreamSubscription<Position>? _sub;
  final points = <RunPoint>[];
  double distanceMeters = 0;

  Future<bool> ensurePermission() async {
    var status = await Geolocator.checkPermission();
    if (status == LocationPermission.denied) {
      status = await Geolocator.requestPermission();
    }
    return status == LocationPermission.always ||
        status == LocationPermission.whileInUse;
  }

  Future<void> startTracking() async {
    await _sub?.cancel();
    points.clear();
    distanceMeters = 0;
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );
    _sub = Geolocator.getPositionStream(locationSettings: settings).listen(
      (pos) {
        final p = RunPoint(pos.latitude, pos.longitude, DateTime.now());
        if (points.isNotEmpty) {
          final prev = points.last;
          distanceMeters += Geolocator.distanceBetween(
            prev.lat,
            prev.lng,
            p.lat,
            p.lng,
          );
        }
        points.add(p);
      },
    );
  }

  Future<void> stopTracking() async {
    await _sub?.cancel();
    _sub = null;
  }

  /// Very rough kcal for a run: ~1 kcal per kg per km (order-of-magnitude).
  double estimateRunCalories(double weightKg) {
    if (weightKg <= 0) return 0;
    final km = distanceMeters / 1000.0;
    return weightKg * km;
  }

  double? paceMinPerKm() {
    if (points.length < 2 || distanceMeters < 50) return null;
    final secs = points.last.time.difference(points.first.time).inSeconds;
    if (secs <= 0) return null;
    final km = distanceMeters / 1000.0;
    final minPerKm = (secs / 60.0) / math.max(km, 0.001);
    return minPerKm;
  }
}
