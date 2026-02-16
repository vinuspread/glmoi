import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/functions_client.dart';

final userStatsRepositoryProvider = Provider((ref) => UserStatsRepository());

class UserStatsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _migrationAttempted = false;

  Stream<UserStats> watchUserStats() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(UserStats.empty());
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .asyncMap((snapshot) async {
      if (!snapshot.exists) {
        return UserStats.empty();
      }

      final data = snapshot.data() ?? {};

      final receivedReactions =
          data['received_reactions'] as Map<String, dynamic>?;
      final receivedReactionStats = <String, int>{
        'comfort': (receivedReactions?['comfort'] as num?)?.toInt() ?? 0,
        'empathize': (receivedReactions?['empathize'] as num?)?.toInt() ?? 0,
        'good': (receivedReactions?['good'] as num?)?.toInt() ?? 0,
        'touched': (receivedReactions?['touched'] as num?)?.toInt() ?? 0,
        'fan': (receivedReactions?['fan'] as num?)?.toInt() ?? 0,
      };

      final stats = UserStats(
        myQuotesCount: (data['my_quotes_count'] as num?)?.toInt() ?? 0,
        savedQuotesCount: (data['saved_quotes_count'] as num?)?.toInt() ?? 0,
        likedQuotesCount: (data['liked_quotes_count'] as num?)?.toInt() ?? 0,
        receivedReactionStats: receivedReactionStats,
      );

      if (!_migrationAttempted && stats.needsMigration) {
        _migrationAttempted = true;
        await _triggerMigration();
      }

      return stats;
    });
  }

  Future<UserStats> getUserStats() async {
    final user = _auth.currentUser;
    if (user == null) {
      return UserStats.empty();
    }

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        return UserStats.empty();
      }

      final data = userDoc.data() ?? {};

      final receivedReactions =
          data['received_reactions'] as Map<String, dynamic>?;
      final receivedReactionStats = <String, int>{
        'comfort': (receivedReactions?['comfort'] as num?)?.toInt() ?? 0,
        'empathize': (receivedReactions?['empathize'] as num?)?.toInt() ?? 0,
        'good': (receivedReactions?['good'] as num?)?.toInt() ?? 0,
        'touched': (receivedReactions?['touched'] as num?)?.toInt() ?? 0,
        'fan': (receivedReactions?['fan'] as num?)?.toInt() ?? 0,
      };

      final stats = UserStats(
        myQuotesCount: (data['my_quotes_count'] as num?)?.toInt() ?? 0,
        savedQuotesCount: (data['saved_quotes_count'] as num?)?.toInt() ?? 0,
        likedQuotesCount: (data['liked_quotes_count'] as num?)?.toInt() ?? 0,
        receivedReactionStats: receivedReactionStats,
      );

      if (!_migrationAttempted && stats.needsMigration) {
        _migrationAttempted = true;
        await _triggerMigration();

        return getUserStats();
      }

      return stats;
    } catch (e) {
      return UserStats.empty();
    }
  }

  Future<void> _triggerMigration() async {
    try {
      final callable =
          FunctionsClient.instance.httpsCallable('migrateUserStats');
      await callable.call();
    } catch (e) {
      // 마이그레이션 실패해도 앱 사용에는 지장 없도록 무시
      // 새로운 활동부터 통계가 누적됨
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

  /// 마이그레이션이 필요한지 확인 (모든 통계가 0인 경우)
  bool get needsMigration {
    final totalReactions =
        receivedReactionStats.values.fold<int>(0, (sum, count) => sum + count);
    return myQuotesCount == 0 && savedQuotesCount == 0 && totalReactions == 0;
  }
}
