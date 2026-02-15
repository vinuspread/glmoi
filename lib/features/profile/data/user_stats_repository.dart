import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userStatsRepositoryProvider = Provider((ref) => UserStatsRepository());

class UserStatsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 사용자 통계 조회
  Future<UserStats> getUserStats() async {
    final user = _auth.currentUser;
    if (user == null) {
      return UserStats.empty();
    }

    try {
      final results = await Future.wait([
        _getMyQuotesCount(user.uid),
        _getSavedQuotesCount(user.uid),
        _getLikedQuotesCount(user.uid),
        _getReceivedReactionStats(user.uid),
      ]);

      return UserStats(
        myQuotesCount: results[0] as int,
        savedQuotesCount: results[1] as int,
        likedQuotesCount: results[2] as int,
        receivedReactionStats: results[3] as Map<String, int>,
      );
    } catch (e) {
      return UserStats.empty();
    }
  }

  Future<int> _getMyQuotesCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('quotes')
          .where('user_uid', isEqualTo: userId)
          .where('is_user_post', isEqualTo: true)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getSavedQuotesCount(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('saved_quotes')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<int> _getLikedQuotesCount(String userId) async {
    // liked_quotes 컬렉션이 없다면 0 반환
    // 현재는 클라이언트 메모리에만 저장되므로 Firestore에서 조회 불가
    // TODO: Firebase Functions에서 liked_quotes 컬렉션에 기록하도록 수정 필요
    return 0;
  }

  Future<Map<String, int>> _getReceivedReactionStats(String userId) async {
    try {
      final myQuotesSnapshot = await _firestore
          .collection('quotes')
          .where('user_uid', isEqualTo: userId)
          .where('is_user_post', isEqualTo: true)
          .get();

      final stats = <String, int>{
        'comfort': 0,
        'empathize': 0,
        'good': 0,
        'touched': 0,
        'fan': 0,
      };

      for (final quoteDoc in myQuotesSnapshot.docs) {
        final reactionsSnapshot =
            await quoteDoc.reference.collection('reactions').get();

        for (final reactionDoc in reactionsSnapshot.docs) {
          final data = reactionDoc.data();
          final reactionType = data['reaction_type'] as String?;
          if (reactionType != null && stats.containsKey(reactionType)) {
            stats[reactionType] = (stats[reactionType] ?? 0) + 1;
          }
        }
      }

      return stats;
    } catch (e) {
      return {
        'comfort': 0,
        'empathize': 0,
        'good': 0,
        'touched': 0,
        'fan': 0,
      };
    }
  }
}

class UserStats {
  final int myQuotesCount;
  final int savedQuotesCount;
  final int likedQuotesCount;
  final Map<String, int> receivedReactionStats;

  const UserStats({
    required this.myQuotesCount,
    required this.savedQuotesCount,
    required this.likedQuotesCount,
    required this.receivedReactionStats,
  });

  factory UserStats.empty() {
    return const UserStats(
      myQuotesCount: 0,
      savedQuotesCount: 0,
      likedQuotesCount: 0,
      receivedReactionStats: {
        'comfort': 0,
        'empathize': 0,
        'good': 0,
        'touched': 0,
        'fan': 0,
      },
    );
  }
}
