import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('WK Operações MVP está configurado apenas para Android.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('WK Operações MVP está configurado apenas para Android.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDp-o4S8Atgwud68gmXM3dYMKKr9rs0Ha4',
    appId: '1:818781431862:android:56279760a278749709d097',
    messagingSenderId: '818781431862',
    projectId: 'app-wk',
    storageBucket: 'app-wk.firebasestorage.app',
  );
}
