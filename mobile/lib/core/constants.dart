/// Android emulator: use 10.0.2.2 to reach host machine.
/// Override: `flutter run --dart-define=API_BASE=http://192.168.1.5:3000`
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://10.0.2.2:3000',
);

const String kAppName = 'Fitness Freak';
