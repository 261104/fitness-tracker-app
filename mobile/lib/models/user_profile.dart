class UserProfile {
  const UserProfile({
    required this.displayName,
    required this.heightCm,
    required this.weightKg,
    required this.dailyStepGoal,
  });

  final String displayName;
  final double heightCm;
  final double weightKg;
  final int dailyStepGoal;

  static const UserProfile guest = UserProfile(
    displayName: 'Athlete',
    heightCm: 170,
    weightKg: 70,
    dailyStepGoal: 8000,
  );

  UserProfile copyWith({
    String? displayName,
    double? heightCm,
    double? weightKg,
    int? dailyStepGoal,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      dailyStepGoal: dailyStepGoal ?? this.dailyStepGoal,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'displayName': displayName,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'dailyStepGoal': dailyStepGoal,
        'updatedAt': DateTime.now().toIso8601String(),
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      displayName: map['displayName'] as String? ?? 'Athlete',
      heightCm: (map['heightCm'] as num?)?.toDouble() ?? 170,
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 70,
      dailyStepGoal: (map['dailyStepGoal'] as num?)?.toInt() ?? 8000,
    );
  }
}
