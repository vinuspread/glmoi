import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userRepositoryProvider = Provider((ref) => UserRepository());

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'users';

  /// 전체 회원 수
  Future<int> getTotalUserCount() async {
    try {
      final snapshot = await _firestore.collection(_collectionPath).get();
      return snapshot.size;
    } catch (e) {
      // users 컬렉션이 없으면 0 반환
      return 0;
    }
  }

  /// 신규 회원 수 (지난 N일간)
  Future<int> getNewUserCount({int days = 7}) async {
    try {
      final DateTime cutoffDate = DateTime.now().subtract(Duration(days: days));
      final Timestamp cutoffTimestamp = Timestamp.fromDate(cutoffDate);

      final snapshot = await _firestore
          .collection(_collectionPath)
          .where('createdAt', isGreaterThanOrEqualTo: cutoffTimestamp)
          .get();

      return snapshot.size;
    } catch (e) {
      return 0;
    }
  }

  /// 글모이 새로운 글 갯수 (지난 N일간, 사용자 작성)
  Future<int> getNewMalmoiCount({int days = 7}) async {
    try {
      final DateTime cutoffDate = DateTime.now().subtract(Duration(days: days));
      final Timestamp cutoffTimestamp = Timestamp.fromDate(cutoffDate);

      final snapshot = await _firestore
          .collection('quotes')
          .where('app_id', isEqualTo: 'maumsori')
          .where('is_user_post', isEqualTo: true)
          .where('type', isEqualTo: 'malmoi')
          .where('createdAt', isGreaterThanOrEqualTo: cutoffTimestamp)
          .get();

      return snapshot.size;
    } catch (e) {
      return 0;
    }
  }

  /// 대시보드용 통계 (1주일 기준)
  Future<Map<String, int>> getWeeklyStats() async {
    final newMalmoi = await getNewMalmoiCount(days: 7);
    final totalUsers = await getTotalUserCount();
    final newUsers = await getNewUserCount(days: 7);

    return {
      'newMalmoi': newMalmoi,
      'totalUsers': totalUsers,
      'newUsers': newUsers,
    };
  }
}
