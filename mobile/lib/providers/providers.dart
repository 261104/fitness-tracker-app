import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../models/workout_entry.dart';
import '../services/activity_recognition_service.dart';
import '../services/auth_service.dart';
import '../services/backend_api.dart';
import '../services/health_sync_service.dart';
import '../services/location_run_service.dart';
import '../services/step_tracker_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final backendApiProvider = Provider<BackendApi>((ref) => BackendApi());

final healthSyncServiceProvider = Provider<HealthSyncService>((ref) {
  return HealthSyncService();
});

final activityRecognitionServiceProvider =
    Provider<ActivityRecognitionService>((ref) {
  final svc = ActivityRecognitionService();
  ref.onDispose(svc.dispose);
  return svc;
});

final locationRunServiceProvider = Provider<LocationRunService>((ref) {
  final s = LocationRunService();
  ref.onDispose(() {
    s.stopTracking();
  });
  return s;
});

final stepCountProvider = StreamProvider<int>((ref) {
  return StepTrackerService.instance.stepsStream;
});

final userProfileProvider = StreamProvider<UserProfile>((ref) {
  final asyncUser = ref.watch(authStateProvider);
  return asyncUser.when(
    data: (user) {
      if (user == null) {
        return Stream.value(UserProfile.guest);
      }
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((snap) {
            final data = snap.data();
            final name =
                user.displayName ?? data?['displayName'] as String? ?? 'Athlete';
            if (data == null) {
              return UserProfile.guest.copyWith(displayName: name);
            }
            return UserProfile.fromMap(data);
          });
    },
    loading: () => Stream.value(UserProfile.guest),
    error: (_, __) => Stream.value(UserProfile.guest),
  );
});

final workoutsProvider = StreamProvider<List<WorkoutEntry>>((ref) {
  final asyncUser = ref.watch(authStateProvider);
  return asyncUser.when(
    data: (user) {
      if (user == null) {
        return Stream.value(const <WorkoutEntry>[]);
      }
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('workouts')
          .orderBy('startedAt', descending: true)
          .limit(50)
          .snapshots()
          .map((q) => q.docs.map(WorkoutEntry.fromDoc).toList());
    },
    loading: () => Stream.value(const <WorkoutEntry>[]),
    error: (_, __) => Stream.value(const <WorkoutEntry>[]),
  );
});

final dailyStatsBackendProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final api = ref.watch(backendApiProvider);
  return api.fetchDailyStats();
});

final weeklyStatsBackendProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final api = ref.watch(backendApiProvider);
  return api.fetchWeeklyStats();
});
