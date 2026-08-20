// GENERATED-STYLE FILE — REPLACE BEFORE BUILDING.
//
// This is a placeholder so the project compiles out of the box. Generate the
// real thing by running, from the project root:
//
//     dart pub global activate flutterfire_cli
//     flutterfire configure
//
// That command overwrites this file with your project's keys and drops
// `android/app/google-services.json` (and the iOS plist) into place.
// See README.md -> "Firebase setup" for the full checklist.
//
// ignore_for_file: type=lint

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  /// True while the placeholder values below are still in place. `main.dart`
  /// checks this so the app can show a setup screen instead of crashing.
  static bool get isPlaceholder => android.apiKey.startsWith('REPLACE_ME');

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Vybe Cabs targets Android and iOS. Run `flutterfire configure` to '
          'add support for ${defaultTargetPlatform.name}.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_ME_ANDROID_API_KEY',
    appId: 'REPLACE_ME_ANDROID_APP_ID',
    messagingSenderId: 'REPLACE_ME_SENDER_ID',
    projectId: 'REPLACE_ME_PROJECT_ID',
    storageBucket: 'REPLACE_ME_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_ME_IOS_API_KEY',
    appId: 'REPLACE_ME_IOS_APP_ID',
    messagingSenderId: 'REPLACE_ME_SENDER_ID',
    projectId: 'REPLACE_ME_PROJECT_ID',
    storageBucket: 'REPLACE_ME_PROJECT_ID.appspot.com',
    iosBundleId: 'com.vybecabs.rider',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_ME_WEB_API_KEY',
    appId: 'REPLACE_ME_WEB_APP_ID',
    messagingSenderId: 'REPLACE_ME_SENDER_ID',
    projectId: 'REPLACE_ME_PROJECT_ID',
    authDomain: 'REPLACE_ME_PROJECT_ID.firebaseapp.com',
    storageBucket: 'REPLACE_ME_PROJECT_ID.appspot.com',
  );
}
