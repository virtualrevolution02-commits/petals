// File generated based on Firebase project: petals-dairy
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBpF0FWCuKDIAoReHOgmjHzvF06JHR5hAA',
    appId: '1:147657058804:web:74376f2434973bd43331a1',
    messagingSenderId: '147657058804',
    projectId: 'petals-dairy',
    authDomain: 'petals-dairy.firebaseapp.com',
    storageBucket: 'petals-dairy.firebasestorage.app',
    measurementId: 'G-95PB536FR7',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDjCPaDRr5BUBYUlouIYt9ss7ScpzEHNQA',
    appId: '1:147657058804:android:162e1a1c601f2b8a3331a1',
    messagingSenderId: '147657058804',
    projectId: 'petals-dairy',
    storageBucket: 'petals-dairy.firebasestorage.app',
  );
}
