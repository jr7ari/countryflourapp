// Generated Firebase options — matches google-services.json for Android.
// Run `flutterfire configure` to regenerate if the Firebase project changes.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'Add GoogleService-Info.plist to ios/Runner and run '
          '`flutterfire configure` to enable iOS support.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBnu4pc3jIgr0A4f3aWFHvxMVXEwxvQ9Fo',
    appId: '1:837334476210:android:aa018cd27e698a47d870ab',
    messagingSenderId: '837334476210',
    projectId: 'countryflour-c34ea',
    storageBucket: 'countryflour-c34ea.firebasestorage.app',
    measurementId: 'G-NMQWEEF18K',
  );
}
