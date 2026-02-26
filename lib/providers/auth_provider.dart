import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool _isTrialMode = true;
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isTrialMode => _isTrialMode;
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get firebaseAvailable => Firebase.apps.isNotEmpty;

  /// 맛보기 모드로 시작
  void startTrialMode() {
    _isTrialMode = true;
    _user = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Google 로그인 (Firebase 필요)
  Future<bool> signInWithGoogle() async {
    if (!firebaseAvailable) {
      _errorMessage = 'Firebase 설정이 필요합니다.\nfirebase_options.dart 파일을 설정해주세요.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      final UserCredential credential =
          await FirebaseAuth.instance.signInWithPopup(googleProvider);
      _user = credential.user;
      _isTrialMode = false;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '로그인에 실패했습니다. 다시 시도해주세요.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    if (firebaseAvailable) {
      await FirebaseAuth.instance.signOut();
    }
    _user = null;
    _isTrialMode = true;
    _errorMessage = null;
    notifyListeners();
  }
}
