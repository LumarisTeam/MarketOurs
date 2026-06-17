import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions? get currentPlatform {
    if (kIsWeb) {
      return null;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: 'MISSING_ANDROID_API_KEY',
          appId: 'MISSING_ANDROID_APP_ID',
          messagingSenderId: 'MISSING_ANDROID_MESSAGING_SENDER_ID',
          projectId: 'MISSING_ANDROID_PROJECT_ID',
          storageBucket: 'MISSING_ANDROID_STORAGE_BUCKET',
        );
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return null;
    }
  }

  static bool get isConfigured {
    final options = currentPlatform;
    if (options == null) {
      return false;
    }

    return !options.apiKey.startsWith('MISSING_') &&
        !options.appId.startsWith('MISSING_') &&
        !options.messagingSenderId.startsWith('MISSING_') &&
        !options.projectId.startsWith('MISSING_');
  }
}
