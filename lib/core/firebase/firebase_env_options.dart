import 'package:firebase_core/firebase_core.dart';

/// Centralized FirebaseOptions per environment.
///
/// Keep these in sync with the Firebase Console web app configs.
class FirebaseEnvOptions {
  static const FirebaseOptions dev = FirebaseOptions(
    apiKey: 'AIzaSyCoCq0kBhhWFVhjTtT7e2bEGsivwmo3v9M',
    authDomain: 'glmoi-dev.firebaseapp.com',
    projectId: 'glmoi-dev',
    storageBucket: 'glmoi-dev.firebasestorage.app',
    messagingSenderId: '916757331367',
    appId: '1:916757331367:web:2d403023be467123bd4a82',
    measurementId: 'G-YS0QT1X2DB',
  );

  static const FirebaseOptions stg = FirebaseOptions(
    apiKey: 'AIzaSyDP7ba5fSpB3c_OzO01BZeO5veBeJt0CmE',
    authDomain: 'glmoi-stg.firebaseapp.com',
    projectId: 'glmoi-stg',
    storageBucket: 'glmoi-stg.firebasestorage.app',
    messagingSenderId: '170878502777',
    appId: '1:170878502777:web:d3a437f10890f0101d11a8',
    measurementId: 'G-F1E2TDNTE0',
  );

  static const FirebaseOptions prod = FirebaseOptions(
    apiKey: 'AIzaSyCPbAOWCmwMVRCiO9Kp_TBBeMZ2R7NLpPI',
    authDomain: 'glmoi-prod.firebaseapp.com',
    projectId: 'glmoi-prod',
    storageBucket: 'glmoi-prod.firebasestorage.app',
    messagingSenderId: '352429434218',
    appId: '1:352429434218:web:03e85df51c63e7af883113',
    measurementId: 'G-GG93YBNWQQ',
  );
}
