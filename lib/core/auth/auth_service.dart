import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao;

// State tracks "Is Logged In"
final authProvider = StateNotifierProvider<AuthService, bool>((ref) {
  return AuthService();
});

final authUidProvider = StreamProvider<String?>((ref) {
  return FirebaseAuth.instance.authStateChanges().map((u) => u?.uid);
});

class AuthService extends StateNotifier<bool> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthService() : super(false) {
    _bindAuthState();
  }

  void _bindAuthState() {
    // Member-only actions require Firebase Auth user.
    state = _auth.currentUser != null;
    _auth.authStateChanges().listen((user) {
      state = user != null;
      if (user != null) {
        // Best-effort: ensure a user doc exists even when the session is restored.
        () async {
          try {
            await _upsertUserProfile(
              uid: user.uid,
              provider: null,
              providerUserId: null,
              displayName: user.displayName,
              photoUrl: user.photoURL,
            );
          } catch (e) {
            if (kDebugMode) {
              debugPrint('User profile upsert failed: $e');
            }
          }
        }();
      }
    });
  }

  Future<void> _upsertUserProfile({
    required String uid,
    required String? provider,
    required String? providerUserId,
    required String? displayName,
    required String? photoUrl,
  }) async {
    final name = (displayName ?? '').trim();
    final photo = (photoUrl ?? '').trim();

    // Get email from Firebase Auth user
    final user = _auth.currentUser;
    final email = user?.email?.trim() ?? '';

    final ref = _db.collection('users').doc(uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final now = FieldValue.serverTimestamp();

      final base = <String, Object?>{
        'uid': uid,
        'updatedAt': now,
        'last_login_at': now,
      };

      if (provider != null && provider.trim().isNotEmpty) {
        base['provider'] = provider.trim();
      }
      if (providerUserId != null && providerUserId.trim().isNotEmpty) {
        base['provider_user_id'] = providerUserId.trim();
      }
      if (name.isNotEmpty) {
        base['display_name'] = name;
      }
      if (photo.isNotEmpty) {
        base['photo_url'] = photo;
      }
      if (email.isNotEmpty) {
        base['email'] = email;
      }

      if (snap.exists) {
        tx.set(ref, base, SetOptions(merge: true));
      } else {
        tx.set(ref, {
          ...base,
          'createdAt': now,
        });
      }
    });
  }

  // Login with Kakao
  Future<void> loginWithKakao() async {
    try {
      final bool isInstalled = await kakao.isKakaoTalkInstalled();
      if (isInstalled) {
        try {
          await kakao.UserApi.instance.loginWithKakaoTalk();
        } on PlatformException catch (e) {
          final code = e.code.trim();
          final msg = (e.message ?? '').toLowerCase();
          final notConnected = code == 'NotSupportError' ||
              msg.contains('not connected to kakao');

          // When KakaoTalk is installed but not logged in, show a friendly
          // action-required message instead of a raw platform error.
          if (notConnected) {
            throw StateError('카카오톡앱 로그인을 먼저 진행하세요');
          }

          rethrow;
        }
      } else {
        await kakao.UserApi.instance.loginWithKakaoAccount();
      }

      final me = await kakao.UserApi.instance.me();
      final kakaoUserId = me.id.toString();
      final nickname = me.kakaoAccount?.profile?.nickname;
      final profileImageUrl = me.kakaoAccount?.profile?.profileImageUrl;
      final thumbImageUrl = me.kakaoAccount?.profile?.thumbnailImageUrl;
      final resolvedProfileImageUrl =
          ((profileImageUrl ?? '').trim().isNotEmpty)
              ? profileImageUrl
              : thumbImageUrl;

      // Exchange Kakao access token -> Firebase Custom Token.
      final kakaoToken =
          await kakao.TokenManagerProvider.instance.manager.getToken();
      final accessToken = kakaoToken?.accessToken;
      if (accessToken == null || accessToken.trim().isEmpty) {
        throw StateError('Kakao access token missing');
      }

      final functions =
          FirebaseFunctions.instanceFor(region: 'asia-northeast3');
      final callable = functions.httpsCallable('kakaoCustomToken');
      final result = await callable.call({'accessToken': accessToken});
      final data = result.data;
      final customToken = data is Map ? (data['customToken'] as String?) : null;
      if (customToken == null || customToken.trim().isEmpty) {
        throw StateError('Firebase custom token missing');
      }

      await _auth.signInWithCustomToken(customToken);

      final user = _auth.currentUser;
      if (user != null) {
        final name = (nickname ?? '').trim();
        final photo = (resolvedProfileImageUrl ?? '').trim();

        // Update Firebase Auth profile first (needed for immediate UI)
        await Future.wait([
          if (name.isNotEmpty && (user.displayName ?? '').trim() != name)
            user.updateDisplayName(name),
          if (photo.isNotEmpty && (user.photoURL ?? '').trim() != photo)
            user.updatePhotoURL(photo),
        ]);

        await _upsertUserProfile(
          uid: user.uid,
          provider: 'kakao',
          providerUserId: kakaoUserId,
          displayName: name.isNotEmpty ? name : user.displayName,
          photoUrl: photo.isNotEmpty ? photo : user.photoURL,
        );
      }

      // CRITICAL: Reset Functions instance after login

      state = true;
      if (kDebugMode) {
        debugPrint('Kakao login success');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Kakao login failed: $e');
      }
      rethrow;
    }
  }

  // Login with Google
  Future<void> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // Users canceled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      final user = _auth.currentUser;
      if (user != null) {
        await _upsertUserProfile(
          uid: user.uid,
          provider: 'google',
          providerUserId: googleUser.id,
          displayName: user.displayName,
          photoUrl: user.photoURL,
        );
      }

      // CRITICAL: Reset Functions instance after login

      state = true;
      if (kDebugMode) {
        debugPrint('Google login success');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Google login failed: $e');
      }
      rethrow;
    }
  }

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final e = email.trim();
    if (e.isEmpty) throw StateError('이메일을 입력하세요');
    if (password.isEmpty) throw StateError('비밀번호를 입력하세요');

    await _auth.signInWithEmailAndPassword(email: e, password: password);
    final user = _auth.currentUser;
    if (user != null) {
      await user.getIdToken(true);

      await _upsertUserProfile(
        uid: user.uid,
        provider: 'email',
        providerUserId: null,
        displayName: user.displayName,
        photoUrl: user.photoURL,
      );
    }
    state = true;
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String nickname,
    Uint8List? profileImageBytes,
  }) async {
    final e = email.trim();
    final n = nickname.trim();
    if (e.isEmpty) throw StateError('이메일을 입력하세요');
    if (password.isEmpty) throw StateError('비밀번호를 입력하세요');
    if (n.isEmpty) throw StateError('닉네임을 입력하세요');

    final cred = await _auth.createUserWithEmailAndPassword(
        email: e, password: password);
    final user = cred.user;
    if (user == null) throw StateError('회원가입에 실패했습니다.');

    // Update display name and refresh token in parallel
    await Future.wait([
      if ((user.displayName ?? '').trim() != n) user.updateDisplayName(n),
      user.reload(),
      user.getIdToken(true),
    ]);

    String? photoUrl;
    if (profileImageBytes != null && profileImageBytes.isNotEmpty) {
      try {
        final ref =
            _storage.ref().child('users').child(user.uid).child('profile');
        await ref.putData(
          profileImageBytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        photoUrl = await ref.getDownloadURL();
        if (photoUrl.trim().isNotEmpty &&
            (user.photoURL ?? '').trim() != photoUrl) {
          await user.updatePhotoURL(photoUrl);
        }
      } catch (e) {
        // Best-effort: profile image is optional. Don't fail sign-up.
        if (kDebugMode) {
          debugPrint('Profile image upload failed: $e');
        }
      }
    }

    await _upsertUserProfile(
      uid: user.uid,
      provider: 'email',
      providerUserId: null,
      displayName: n,
      photoUrl: (photoUrl ?? user.photoURL),
    );

    state = true;
  }

  Future<void> logout() async {
    await _auth.signOut();
    try {
      await kakao.UserApi.instance.logout();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Kakao logout failed: $e');
      }
    }
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Google signOut failed: $e');
      }
    }
    state = false;
  }

  Future<void> updateNickname(String nickname) async {
    final trimmed = nickname.trim();
    if (trimmed.isEmpty) {
      throw StateError('닉네임을 입력해주세요.');
    }
    if (trimmed.length > 20) {
      throw StateError('닉네임은 20자 이하로 입력해주세요.');
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('로그인이 필요합니다.');
    }

    if ((user.displayName ?? '').trim() != trimmed) {
      await user.updateDisplayName(trimmed);
    }

    await _upsertUserProfile(
      uid: user.uid,
      provider: null,
      providerUserId: null,
      displayName: trimmed,
      photoUrl: user.photoURL,
    );
  }

  Future<void> updateProfileImage(Uint8List profileImageBytes) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('로그인이 필요합니다.');
    if (profileImageBytes.isEmpty) throw StateError('프로필 이미지를 선택하세요');

    final ref = _storage.ref().child('users').child(user.uid).child('profile');
    await ref.putData(
      profileImageBytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final url = (await ref.getDownloadURL()).trim();
    if (url.isEmpty) throw StateError('프로필 이미지 업로드에 실패했습니다.');

    if ((user.photoURL ?? '').trim() != url) {
      await user.updatePhotoURL(url);
    }

    await _upsertUserProfile(
      uid: user.uid,
      provider: null,
      providerUserId: null,
      displayName: user.displayName,
      photoUrl: url,
    );
  }
}
