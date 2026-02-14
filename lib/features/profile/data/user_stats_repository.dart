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
      // 병렬로 모든 쿼리 실행
      final results = await Future.wait([
        _getMyQuotesCount(user.uid),
        _getSavedQuotesCount(user.uid),
        _getLikedQuotesCount(user.uid),
        _getSharedQuotesCount(user.uid),
        _getReactionStats(user.uid),
      ]);

      return UserStats(
        myQuotesCount: results[0] as int,
        savedQuotesCount: results[1] as int,
        likedQuotesCount: results[2] as int,
        sharedQuotesCount: results[3] as int,
        reactionStats: results[4] as Map<String, int>,
      );
    } catch (e) {
      return UserStats.empty();
    }
  }

  Future<int> _getMyQuotesCount(String userId) async {
    final snapshot = await _firestore
        .collection('quotes')
        .where('user_id', isEqualTo: userId)
        .where('is_user_post', isEqualTo: true)
        .count()
        .get();
    return snapshot.count ?? 0;
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

  Future<int> _getSharedQuotesCount(String userId) async {
    // share_records 컬렉션이 없다면 0 반환
    // TODO: 공유 기록이 Firestore에 저장되는지 확인 필요
    try {
      final snapshot = await _firestore
          .collection('share_records')
          .where('user_id', isEqualTo: userId)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<Map<String, int>> _getReactionStats(String userId) async {
    try {
      // 모든 quotes의 reactions 서브컬렉션에서 사용자의 반응 조회
      // Collection group query 사용
      final snapshot = await _firestore
          .collectionGroup('reactions')
          .where('user_id', isEqualTo: userId)
          .get();

      final stats = <String, int>{
        'comfort': 0,
        'empathize': 0,
        'good': 0,
        'touched': 0,
        'fan': 0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final reactionType = data['reaction_type'] as String?;
        if (reactionType != null && stats.containsKey(reactionType)) {
          stats[reactionType] = (stats[reactionType] ?? 0) + 1;
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
  final int sharedQuotesCount;
  final Map<String, int> reactionStats;

  const UserStats({
    required this.myQuotesCount,
    required this.savedQuotesCount,
    required this.likedQuotesCount,
    required this.sharedQuotesCount,
    required this.reactionStats,
  });

  factory UserStats.empty() {
    return const UserStats(
      myQuotesCount: 0,
      savedQuotesCount: 0,
      likedQuotesCount: 0,
      sharedQuotesCount: 0,
      reactionStats: {
        'comfort': 0,
        'empathize': 0,
        'good': 0,
        'touched': 0,
        'fan': 0,
      },
    );
  }
}
