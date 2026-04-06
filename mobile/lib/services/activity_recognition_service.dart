import 'dart:async';

import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';

class ActivityRecognitionService {
  StreamSubscription<ActivityEvent>? _sub;
  final _latest = StreamController<ActivityEvent>.broadcast();

  Stream<ActivityEvent> get events => _latest.stream;

  ActivityEvent? lastEvent;

  Future<void> start({bool foreground = true}) async {
    await _sub?.cancel();
    final ar = ActivityRecognition();
    _sub = ar.activityStream(runForegroundService: foreground).listen(
      (event) {
        lastEvent = event;
        if (!_latest.isClosed) _latest.add(event);
      },
    );
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    await ActivityRecognition().stopActivityUpdates();
  }

  void dispose() {
    _sub?.cancel();
    _latest.close();
  }
}
