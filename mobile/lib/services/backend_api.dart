import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../core/constants.dart';

class BackendApi {
  BackendApi({String? baseUrl, FirebaseAuth? auth})
      : baseUrl = baseUrl ?? kApiBaseUrl,
        _auth = auth ?? FirebaseAuth.instance;

  final String baseUrl;
  final FirebaseAuth _auth;

  Future<Map<String, dynamic>?> postJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final token = await _auth.currentUser?.getIdToken();
    final uri = Uri.parse('$baseUrl$path');
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: body == null ? null : jsonEncode(body),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return {};
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> syncDailyStats({
    required int steps,
    required double workoutCalories,
    required double stepsCalories,
    int workoutCount = 0,
  }) async {
    await postJson('/api/v1/stats/sync', body: {
      'steps': steps,
      'workoutCalories': workoutCalories,
      'stepsCalories': stepsCalories,
      'workoutCount': workoutCount,
      'date': DateTime.now().toIso8601String().split('T').first,
    });
  }

  Future<Map<String, dynamic>?> fetchDailyStats() async {
    final token = await _auth.currentUser?.getIdToken();
    final uri = Uri.parse('$baseUrl/api/v1/stats/daily');
    final res = await http.get(
      uri,
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode != 200) return null;
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> fetchWeeklyStats() async {
    final token = await _auth.currentUser?.getIdToken();
    final uri = Uri.parse('$baseUrl/api/v1/stats/weekly');
    final res = await http.get(
      uri,
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode != 200) return null;
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> suggestReminders({
    required int stepsToday,
    required int stepGoal,
    required int workoutsThisWeek,
  }) async {
    return postJson('/api/v1/reminders/suggest', body: {
      'stepsToday': stepsToday,
      'stepGoal': stepGoal,
      'workoutsThisWeek': workoutsThisWeek,
    });
  }
}
