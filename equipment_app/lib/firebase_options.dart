// lib/firebase_options.dart
// ⚠️  ไฟล์นี้สร้างโดย FlutterFire CLI
// สั่ง: flutterfire configure --project=equipment-system-f4cac
// แล้วไฟล์นี้จะถูกสร้างอัตโนมัติ

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  // ─── ดึงค่าจาก Firebase Console > Project Settings ─────────────────

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA8aE_GVEbWzNp0LAi4E_vJK7oFTvbiZO0',
    appId: '1:36065605768:web:87abb26c31d58beaefc73d',
    messagingSenderId: '36065605768',
    projectId: 'equipment-system-f4cac',
    authDomain: 'equipment-system-f4cac.firebaseapp.com',
    storageBucket: 'equipment-system-f4cac.firebasestorage.app',
    measurementId: 'G-V8KHSYNTN3',
  );

  // Web (ถ้าต้องการ)

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC6gVoqa7iQIPBxEXCq4nOBFK6_9VVnBwU',
    appId: '1:36065605768:android:d7d79f29a2a6bd65efc73d',
    messagingSenderId: '36065605768',
    projectId: 'equipment-system-f4cac',
    storageBucket: 'equipment-system-f4cac.firebasestorage.app',
  );

  // Android (ดูจาก google-services.json)

  // iOS (ดูจาก GoogleService-Info.plist)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: '36065605768',
    projectId: 'equipment-system-f4cac',
    storageBucket: 'equipment-system-f4cac.appspot.com',
    iosBundleId: 'com.example.equipmentApp',
  );
}
