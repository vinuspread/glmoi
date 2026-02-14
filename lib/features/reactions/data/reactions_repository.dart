import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/reaction_type.dart';
import '../../../core/backend/functions_client.dart';

class ReactionsRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  ReactionsRepository({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
  })  : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Stream<ReactionType?> watchMyReaction({required String quoteId}) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value(null);
    }

    return _db
        .collection('quotes')
        .doc(quoteId)
        .collection('reactions')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final data = doc.data();
      final raw = data?['reaction_type'] as String?;
      return reactionTypeFromFirestore(raw);
    });
  }

  Future<(bool alreadyReacted, ReactionType? reactionType)> reactToQuoteOnce({
    required String quoteId,
    required ReactionType reactionType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('로그인이 필요합니다.');
    }

    // Force token refresh and wait for auth state to stabilize
    await user.reload();
    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw StateError('로그인 인증 정보를 가져올 수 없습니다.');
    }

    final callable = FunctionsClient.instance.httpsCallable('reactToQuoteOnce');
    final res = await callable.call({
      'quoteId': quoteId,
      'reactionType': reactionTypeToFirestore(reactionType),
    });

    final data = (res.data as Map?)?.cast<String, dynamic>() ?? const {};
    final already = data['alreadyReacted'] == true;
    final raw = data['reactionType'] as String?;
    return (already, reactionTypeFromFirestore(raw));
  }
}
