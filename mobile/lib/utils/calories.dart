double caloriesFromSteps(int steps, double weightKg) {
  if (steps <= 0 || weightKg <= 0) return 0;
  const refWeight = 70.0;
  return steps * 0.04 * (weightKg / refWeight);
}

double metForWorkoutType(String type) {
  switch (type.toLowerCase()) {
    case 'running':
      return 9.8;
    case 'walking':
      return 3.5;
    case 'cycling':
      return 7.5;
    case 'hiit':
      return 8.0;
    case 'strength':
      return 5.0;
    case 'yoga':
      return 2.5;
    default:
      return 5.0;
  }
}

double caloriesFromWorkoutMinutes({
  required String type,
  required int minutes,
  required double weightKg,
}) {
  if (minutes <= 0 || weightKg <= 0) return 0;
  final met = metForWorkoutType(type);
  return met * weightKg * (minutes / 60.0);
}
