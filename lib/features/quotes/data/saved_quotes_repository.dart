import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/functions_client.dart';
import '../domain/quote.dart';

final savedQuotesRepositoryProvider =
    Provider((ref) => SavedQuotesRepository());

class SavedQuotesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 담기 토글 (담겨있으면 취소, 없으면 담기)
  /// Cloud Function을 통해 saved_quotes_count도 함께 업데이트
  Future<bool> toggleSaveQuote(Quote quote) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('로그인이 필요합니다');
    }

    final callable = FunctionsClient.instance.httpsCallable('toggleSaveQuote');

    final result = await callable.call({
      'quoteId': quote.id,
      'quoteData': {
        'app_id': quote.appId,
        'type': quote.type.name,
        'content': quote.content,
        'author': quote.author,
        'image_url': quote.imageUrl,
      }
    });

    final data = result.data as Map<String, dynamic>;
    return data['saved'] == true;
  }

  /// 담은 글 목록 스트림
  Stream<List<SavedQuoteSnapshot>> watchSavedQuotes() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('saved_quotes')
        .orderBy('saved_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SavedQuoteSnapshot.fromFirestore(doc))
          .toList();
    });
  }

  /// 특정 글이 담겨있는지 확인
  Stream<bool> isSaved(String quoteId) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(false);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('saved_quotes')
        .doc(quoteId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// 담은 글 ID 목록 (초기 로드용)
  Future<Set<String>> getSavedQuoteIds() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {};
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('saved_quotes')
        .get();

    return snapshot.docs.map((doc) => doc.id).toSet();
  }
}

/// 담은 글 스냅샷 (비정규화된 데이터)
class SavedQuoteSnapshot {
  final String quoteId;
  final String appId;
  final String type;
  final String content;
  final String author;
  final String? imageUrl;
  final DateTime? savedAt;

  const SavedQuoteSnapshot({
    required this.quoteId,
    required this.appId,
    required this.type,
    required this.content,
    required this.author,
    this.imageUrl,
    this.savedAt,
  });

  factory SavedQuoteSnapshot.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw StateError('Document data is null');
    }

    final savedAtTimestamp = data['saved_at'] as Timestamp?;

    return SavedQuoteSnapshot(
      quoteId: doc.id,
      appId: (data['app_id'] as String?) ?? 'maumsori',
      type: (data['type'] as String?) ?? 'quote',
      content: (data['content'] as String?) ?? '',
      author: (data['author'] as String?) ?? '',
      imageUrl: data['image_url'] as String?,
      savedAt: savedAtTimestamp?.toDate(),
    );
  }
}
