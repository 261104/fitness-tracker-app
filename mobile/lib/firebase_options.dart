// Replace with output from: dart pub global activate flutterfire_cli && flutterfire configure
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Fitness Freak is Android-only in this MVP.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('Fitness Freak targets Android for this MVP.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCLoE4wXme-yYhkVKZWL6IK-jaZ8XAK1ws',
    appId: '1:173628615479:android:1577c3fbf859f5c64988b2',
    messagingSenderId: '173628615479',
    projectId: 'fitness-freak-8c343',
    storageBucket: 'fitness-freak-8c343.firebasestorage.app',
  );

}