// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'dart:io' show Platform, PlatformException;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get web {
    // Using the same API key and app ID for web as provided in .env
    final apiKey = const String.fromEnvironment('WEB_API_KEY');
    final appId = const String.fromEnvironment('WEB_APP_ID');
    
    // These values are hardcoded for now but can be moved to .env if needed
    final projectId = 'ev-navigation-2e1b6';
    
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: '337687220694',
      projectId: projectId,
      authDomain: '$projectId.firebaseapp.com',
      storageBucket: '$projectId.appspot.com',
    );
  }

  static FirebaseOptions get android {
    // Reusing the same API key and app ID for Android as provided in .env
    final apiKey = const String.fromEnvironment('WEB_API_KEY');
    final appId = const String.fromEnvironment('WEB_APP_ID');
    final projectId = 'ev-navigation-2e1b6';
    
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: '337687220694',
      projectId: projectId,
      storageBucket: '$projectId.appspot.com',
    );
  }

  static FirebaseOptions get ios {
    // For iOS, we'll use the same credentials as Android for now
    // You can add separate iOS credentials to .env later if needed
    final apiKey = const String.fromEnvironment('WEB_API_KEY');
    final appId = const String.fromEnvironment('WEB_APP_ID');
    final projectId = 'ev-navigation-2e1b6';
    
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: '337687220694',
      projectId: projectId,
      storageBucket: '$projectId.appspot.com',
      iosBundleId: 'com.easyvahan.easyvahan',
    );
  }

  static FirebaseOptions get macos {
    // Using the same credentials as other platforms for simplicity
    final apiKey = const String.fromEnvironment('WEB_API_KEY');
    final appId = const String.fromEnvironment('WEB_APP_ID');
    final projectId = 'ev-navigation-2e1b6';
    
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: '337687220694',
      projectId: projectId,
      storageBucket: '$projectId.appspot.com',
      iosBundleId: 'com.easyvahan.easyvahan',
    );
  }
}
