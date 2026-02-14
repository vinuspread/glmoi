import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/member_model.dart';

final memberRepositoryProvider = Provider((ref) => MemberRepository());

class MemberRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<MemberModel>> watchRecentMembers({int limit = 500}) {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((d) => MemberModel.fromFirestore(d)).toList(),
        );
  }

  /// 회원 정지
  Future<void> suspendMember(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'is_suspended': true,
      'suspended_at': FieldValue.serverTimestamp(),
    });
  }

  /// 회원 정지 해제
  Future<void> unsuspendMember(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'is_suspended': false,
      'suspended_at': null,
    });
  }

  /// 회원 삭제
  Future<void> deleteMember(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }
}
