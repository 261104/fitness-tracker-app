import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutEntry {
  WorkoutEntry({
    required this.id,
    required this.name,
    required this.type,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.startedAt,
    this.notes,
  });

  final String id;
  final String name;
  final String type;
  final int durationMinutes;
  final double caloriesBurned;
  final DateTime startedAt;
  final String? notes;

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'type': type,
        'durationMinutes': durationMinutes,
        'caloriesBurned': caloriesBurned,
        'startedAt': Timestamp.fromDate(startedAt),
        'notes': notes,
      };

  factory WorkoutEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final started = d['startedAt'];
    DateTime when;
    if (started is Timestamp) {
      when = started.toDate();
    } else {
      when = DateTime.tryParse(started?.toString() ?? '') ?? DateTime.now();
    }
    return WorkoutEntry(
      id: doc.id,
      name: d['name'] as String? ?? 'Workout',
      type: d['type'] as String? ?? 'general',
      durationMinutes: (d['durationMinutes'] as num?)?.toInt() ?? 0,
      caloriesBurned: (d['caloriesBurned'] as num?)?.toDouble() ?? 0,
      startedAt: when,
      notes: d['notes'] as String?,
    );
  }
}
