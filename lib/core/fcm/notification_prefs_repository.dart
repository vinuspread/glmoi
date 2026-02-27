import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationPrefsRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>>? _userDoc() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid);
  }

  /// 자동수신 여부 스트림 (기본값 true)
  Stream<bool> watchAutoContent() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(false);

    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) => snap.data()?['auto_content_enabled'] as bool? ?? true);
  }

  /// 자동수신 여부 저장
  Future<void> setAutoContent(bool enabled) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).set(
      {'uid': uid, 'auto_content_enabled': enabled},
      SetOptions(merge: true),
    );
  }

  /// 현재 자동수신 여부 읽기 (1회)
  Future<bool> getAutoContent() async {
    final doc = _userDoc();
    if (doc == null) return false;
    final snap = await doc.get();
    return snap.data()?['auto_content_enabled'] as bool? ?? true;
  }
}
