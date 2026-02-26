import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError('이 플랫폼은 현재 지원되지 않습니다.');
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDhsx1f8xZOI32Jwjog_oe_fH4mnFwJ6a8',
    appId: '1:582952052910:web:877899311bbdab1581e53f',
    messagingSenderId: '582952052910',
    projectId: 'k-academy-app-data',
    authDomain: 'k-academy-app-data.firebaseapp.com',
    storageBucket: 'k-academy-app-data.firebasestorage.app',
  );
}
