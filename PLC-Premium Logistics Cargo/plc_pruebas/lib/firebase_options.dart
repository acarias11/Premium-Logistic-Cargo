// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        return windows;
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
    apiKey: 'AIzaSyB_QwC-3Bcr9i6NZYKI9uGZhw9mlg8wPlA',
    appId: '1:309994557690:web:0484360863dc12542cb943',
    messagingSenderId: '309994557690',
    projectId: 'premium-logistics',
    authDomain: 'premium-logistics.firebaseapp.com',
    storageBucket: 'premium-logistics.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBerPa69Ue3hao5N9x7j6OacsZsTJAcWts',
    appId: '1:309994557690:android:00ce29695430ed682cb943',
    messagingSenderId: '309994557690',
    projectId: 'premium-logistics',
    storageBucket: 'premium-logistics.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD1STxe0ydMDdA5ed7MOx_Flf_1azCrlEo',
    appId: '1:309994557690:ios:4d91b13969cf66882cb943',
    messagingSenderId: '309994557690',
    projectId: 'premium-logistics',
    storageBucket: 'premium-logistics.firebasestorage.app',
    iosBundleId: 'com.example.plcPruebas',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD1STxe0ydMDdA5ed7MOx_Flf_1azCrlEo',
    appId: '1:309994557690:ios:4d91b13969cf66882cb943',
    messagingSenderId: '309994557690',
    projectId: 'premium-logistics',
    storageBucket: 'premium-logistics.firebasestorage.app',
    iosBundleId: 'com.example.plcPruebas',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB_QwC-3Bcr9i6NZYKI9uGZhw9mlg8wPlA',
    appId: '1:309994557690:web:527e4781856786412cb943',
    messagingSenderId: '309994557690',
    projectId: 'premium-logistics',
    authDomain: 'premium-logistics.firebaseapp.com',
    storageBucket: 'premium-logistics.firebasestorage.app',
  );
}
