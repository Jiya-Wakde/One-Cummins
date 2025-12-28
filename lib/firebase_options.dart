// GENERATED CODE - DO NOT MODIFY BY HAND
//
// Placeholder Firebase options for development.
// Run `flutterfire configure` to generate a real `firebase_options.dart` with
// the correct values for your Firebase project.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
      apiKey: 'AIzaSyBj7kOhBPAdBrdgcOTw0pFO_bgqht0StJQ',
      authDomain: 'REPLACE_WITH_AUTH_DOMAIN',
      projectId: 'ornate-producer-468017-a8',
      storageBucket: 'ornate-producer-468017-a8.firebasestorage.app',
      messagingSenderId: '490604378251',
      appId: '1:490604378251:android:83b47a1c9a293c12117c8e',
      measurementId: 'REPLACE_WITH_MEASUREMENT_ID',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_API_KEY',
    appId: 'REPLACE_WITH_APP_ID',
    messagingSenderId: 'REPLACE_WITH_MESSAGING_SENDER_ID',
    projectId: 'REPLACE_WITH_PROJECT_ID',
    storageBucket: 'REPLACE_WITH_STORAGE_BUCKET',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_API_KEY',
    appId: 'REPLACE_WITH_APP_ID',
    messagingSenderId: 'REPLACE_WITH_MESSAGING_SENDER_ID',
    projectId: 'REPLACE_WITH_PROJECT_ID',
    storageBucket: 'REPLACE_WITH_STORAGE_BUCKET',
    iosClientId: 'REPLACE_WITH_IOS_CLIENT_ID',
    iosBundleId: 'REPLACE_WITH_IOS_BUNDLE_ID',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'REPLACE_WITH_API_KEY',
    appId: 'REPLACE_WITH_APP_ID',
    messagingSenderId: 'REPLACE_WITH_MESSAGING_SENDER_ID',
    projectId: 'REPLACE_WITH_PROJECT_ID',
    storageBucket: 'REPLACE_WITH_STORAGE_BUCKET',
    iosClientId: 'REPLACE_WITH_IOS_CLIENT_ID',
    iosBundleId: 'REPLACE_WITH_IOS_BUNDLE_ID',
  );
}
