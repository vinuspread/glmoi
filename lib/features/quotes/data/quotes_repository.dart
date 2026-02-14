import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/quote.dart';
import '../../../core/backend/functions_client.dart';

class QuotesRepository {
  final FirebaseFirestore _db;
  final String appId;

  QuotesRepository({
    FirebaseFirestore? db,
    this.appId = 'maumsori',
  }) : _db = db ?? FirebaseFirestore.instance;

  Stream<List<Quote>> watchQuotes({required QuoteType type, int limit = 50}) {
    if (type == QuoteType.malmoi) {
      return _watchMalmoi(limit: limit);
    }

    final query = _db
        .collection('quotes')
        .where('app_id', isEqualTo: appId)
        .where('is_user_post', isEqualTo: false)
        .where('is_active', isEqualTo: true)
        .where('type', isEqualTo: quoteTypeToFirestore(type))
        .orderBy('createdAt', descending: true)
        .limit(limit);

    return query
        .snapshots()
        .map((s) => s.docs.map(Quote.fromFirestore).toList());
  }

  Stream<List<Quote>> _watchMalmoi({required int limit}) {
    // Approval flow removed: show all active malmoi posts (official + user).
    final query = _db
        .collection('quotes')
        .where('app_id', isEqualTo: appId)
        .where('type', isEqualTo: quoteTypeToFirestore(QuoteType.malmoi))
        .where('is_active', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    return query
        .snapshots()
        .map((s) => s.docs.map(Quote.fromFirestore).toList());
  }

  Future<void> createMalmoiPost({
    required String content,
    required String category,
    required MalmoiLength malmoiLength,
    String? imageUrl,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    final cat = category.trim();
    if (cat.isEmpty) {
      throw StateError('카테고리를 선택하세요.');
    }

    final img = (imageUrl ?? '').trim();

    String malmoiLengthToFirestore(MalmoiLength v) {
      switch (v) {
        case MalmoiLength.long:
          return 'long';
        case MalmoiLength.short:
          return 'short';
      }
    }

    // Get displayName for author field (Functions will handle auth check)
    final user = FirebaseAuth.instance.currentUser;
    final displayName = (user?.displayName ?? user?.email ?? '').trim();

    final callable = FunctionsClient.instance.httpsCallable('createMalmoiPost');
    await callable.call({
      'content': trimmed,
      'category': cat,
      'malmoi_length': malmoiLengthToFirestore(malmoiLength),
      'image_url': img,
      'author': displayName,
    });
  }

  Stream<List<Quote>> watchMyMalmoiPosts({int limit = 50}) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('로그인이 필요합니다.');
    }

    final query = _db
        .collection('quotes')
        .where('app_id', isEqualTo: appId)
        .where('type', isEqualTo: quoteTypeToFirestore(QuoteType.malmoi))
        .where('is_user_post', isEqualTo: true)
        .where('user_uid', isEqualTo: user.uid)
        .where('is_active', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    return query
        .snapshots()
        .map((s) => s.docs.map(Quote.fromFirestore).toList());
  }

  Future<void> updateMalmoiPost({
    required String quoteId,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    final callable = FunctionsClient.instance.httpsCallable('updateMalmoiPost');
    await callable.call({'quote_id': quoteId, 'content': trimmed});
  }

  Future<void> deleteMalmoiPost({required String quoteId}) async {
    final callable = FunctionsClient.instance.httpsCallable('deleteMalmoiPost');
    await callable.call({'quote_id': quoteId});
  }
}
