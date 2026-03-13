// File này được tạo từ google-services.json của project chamcong-1d7b9.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web. '
        'Please run flutterfire configure to generate options for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS. '
          'Please add GoogleService-Info.plist and run flutterfire configure.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDTDCTGvRarEBfCBW-jjgR_QTUJREcz9V8',
    appId: '1:25469593651:android:08bb20dec099296c0ddb46',
    messagingSenderId: '25469593651',
    projectId: 'chamcong-1d7b9',
    storageBucket: 'chamcong-1d7b9.firebasestorage.app',
  );
}
