import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 이제 AuthService 객체 자체를 관리하는 ChangeNotifierProvider를 사용합니다.
final authProvider = ChangeNotifierProvider<AuthService>((ref) {
  return AuthService();
});

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoggedIn = false;

  // 외부에서 로그인 여부를 확인할 수 있는 getter
  bool get isLoggedIn => _isLoggedIn;

  AuthService() {
    _checkCurrentUser();
  }

  void _checkCurrentUser() {
    _auth.authStateChanges().listen((User? user) {
      _isLoggedIn = user != null;
      // 상태가 변경되었음을 GoRouter와 위젯들에게 알립니다.
      notifyListeners();
    });
  }

  Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    // authStateChanges() will also emit, but proactively refresh UI/router.
    _isLoggedIn = false;
    notifyListeners();
  }
}
