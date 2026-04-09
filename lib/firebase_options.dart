// Firebase configuration - KMS Fleet
// القيم الحقيقية من Firebase Console ✅

import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  /// Firebase مُعد ومفعّل ✅
  static const bool isConfigured = true;

  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        return android;
    }
  }

  // === القيم الحقيقية من Firebase Console ===
  // Project: kms-fleet

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCIK4ixL4zh-MxE9WQKQDQtHj1T8VtIZOY',
    appId: '1:992482878554:android:36dcd16b8c1542d35c2463',
    messagingSenderId: '992482878554',
    projectId: 'kms-fleet',
    storageBucket: 'kms-fleet.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCIK4ixL4zh-MxE9WQKQDQtHj1T8VtIZOY',
    appId: '1:992482878554:web:17cb81fc05ec50405c2463',
    messagingSenderId: '992482878554',
    projectId: 'kms-fleet',
    storageBucket: 'kms-fleet.firebasestorage.app',
    authDomain: 'kms-fleet.firebaseapp.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCIK4ixL4zh-MxE9WQKQDQtHj1T8VtIZOY',
    appId: '1:992482878554:web:17cb81fc05ec50405c2463',
    messagingSenderId: '992482878554',
    projectId: 'kms-fleet',
    storageBucket: 'kms-fleet.firebasestorage.app',
    authDomain: 'kms-fleet.firebaseapp.com',
    iosClientId: '',
    iosBundleId: 'com.example.kmsFleet',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCIK4ixL4zh-MxE9WQKQDQtHj1T8VtIZOY',
    appId: '1:992482878554:web:17cb81fc05ec50405c2463',
    messagingSenderId: '992482878554',
    projectId: 'kms-fleet',
    storageBucket: 'kms-fleet.firebasestorage.app',
    authDomain: 'kms-fleet.firebaseapp.com',
    iosClientId: '',
    iosBundleId: 'com.example.kmsFleet',
  );
}
