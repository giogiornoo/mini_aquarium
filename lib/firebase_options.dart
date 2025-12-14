import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyApIwXwJG-WG61vfVXGkHl5elc0JViVrj8',
    authDomain: 'fishie-aquarium.firebaseapp.com',
    projectId: 'fishie-aquarium',
    storageBucket: 'fishie-aquarium.firebasestorage.app',
    messagingSenderId: '694218473644',
    appId: '1:694218473644:web:aec59361e505d4bc915f09',
    measurementId: 'G-ZL3FWKR81Q',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyApIwXwJG-WG61vfVXGkHl5elc0JViVrj8',
    appId: '1:694218473644:android:aec59361e505d4bc915f09',
    messagingSenderId: '694218473644',
    projectId: 'fishie-aquarium',
    storageBucket: 'fishie-aquarium.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyApIwXwJG-WG61vfVXGkHl5elc0JViVrj8',
    appId: '1:694218473644:ios:aec59361e505d4bc915f09',
    messagingSenderId: '694218473644',
    projectId: 'fishie-aquarium',
    storageBucket: 'fishie-aquarium.firebasestorage.app',
    iosBundleId: 'com.example.miniAquarium',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyApIwXwJG-WG61vfVXGkHl5elc0JViVrj8',
    appId: '1:694218473644:macos:aec59361e505d4bc915f09',
    messagingSenderId: '694218473644',
    projectId: 'fishie-aquarium',
    storageBucket: 'fishie-aquarium.firebasestorage.app',
    iosBundleId: 'com.example.miniAquarium',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyApIwXwJG-WG61vfVXGkHl5elc0JViVrj8',
    appId: '1:694218473644:web:aec59361e505d4bc915f09',
    messagingSenderId: '694218473644',
    projectId: 'fishie-aquarium',
    storageBucket: 'fishie-aquarium.firebasestorage.app',
  );
}
