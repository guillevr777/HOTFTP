import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  // OAuth client used by Google Sign-In on native platforms.
  static const String googleWebClientId = '1053228365631-o83pv4rhu45gqs0f1ptgr4th2q18fpj9.apps.googleusercontent.com';
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
      case TargetPlatform.linux:
        return linux;
      case TargetPlatform.fuchsia:
        throw UnsupportedError('Firebase no soporta Fuchsia');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBAiHUsfEsdGvw4oHFfWTFCUJSOQIjUGtw',
    appId: '1:1053228365631:android:6f643200e910fe7f3d058a',
    messagingSenderId: '1053228365631',
    projectId: 'tfgftp',
    storageBucket: 'tfgftp.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD6tuiSgOZKHsfaAkLgZvbhpBhFmV4eXb0',
    appId: '1:1053228365631:ios:a4dcf2095540c3843d058a',
    messagingSenderId: '1053228365631',
    projectId: 'tfgftp',
    storageBucket: 'tfgftp.firebasestorage.app',
    iosClientId:
        '1053228365631-l059rpe4d3jmc5ahbbi0a0d993l4al00.apps.googleusercontent.com',
    iosBundleId: 'com.example.ftpTfg',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD6tuiSgOZKHsfaAkLgZvbhpBhFmV4eXb0',
    appId: '1:1053228365631:ios:a4dcf2095540c3843d058a',
    messagingSenderId: '1053228365631',
    projectId: 'tfgftp',
    storageBucket: 'tfgftp.firebasestorage.app',
    iosClientId:
        '1053228365631-l059rpe4d3jmc5ahbbi0a0d993l4al00.apps.googleusercontent.com',
    iosBundleId: 'com.example.ftpTfg',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBAiHUsfEsdGvw4oHFfWTFCUJSOQIjUGtw',
    appId: '1:1053228365631:web:d7b23f96026816b23d058a',
    messagingSenderId: '1053228365631',
    projectId: 'tfgftp',
    authDomain: 'tfgftp.firebaseapp.com',
    storageBucket: 'tfgftp.firebasestorage.app',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyBAiHUsfEsdGvw4oHFfWTFCUJSOQIjUGtw',
    appId: '1:1053228365631:web:d7b23f96026816b23d058a',
    messagingSenderId: '1053228365631',
    projectId: 'tfgftp',
    authDomain: 'tfgftp.firebaseapp.com',
    storageBucket: 'tfgftp.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBAiHUsfEsdGvw4oHFfWTFCUJSOQIjUGtw',
    appId: '1:1053228365631:web:05f0929856ed50c63d058a',
    messagingSenderId: '1053228365631',
    projectId: 'tfgftp',
    authDomain: 'tfgftp.firebaseapp.com',
    storageBucket: 'tfgftp.firebasestorage.app',
  );
}



