import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quote_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final quoteRepositoryProvider = Provider((ref) => QuoteRepository());

class DuplicateOfficialContentException implements Exception {
  final String message;
  const DuplicateOfficialContentException(this.message);

  @override
  String toString() => message;
}

class QuoteRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'quotes';
  final String _appId = 'maumsori';

  String _normalizeContent(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';
    // Collapse whitespace to reduce accidental duplicates.
    return trimmed.replaceAll(RegExp(r'\s+'), ' ');
  }

  int _fnv1a32(String input) {
    const int fnvOffset = 0x811C9DC5;
    const int fnvPrime = 0x01000193;

    var hash = fnvOffset;
    final units = input.codeUnits;
    for (final b in units) {
      hash = hash ^ (b & 0xff);
      hash = (hash * fnvPrime) & 0xffffffff;
    }
    return hash;
  }

  String _dedupKeyForOfficialQuote(QuoteModel quote) {
    // Dedup strategy:
    // - Admin-only official posts (is_user_post=false) are prone to accidental duplicates.
    // - We avoid a query+index by using a deterministic doc id in `dedup_quotes/{dedupKey}`.
    // - The doc is created in the same transaction as the quote itself, which makes
    //   the check atomic and race-safe.
    final contentNorm = _normalizeContent(quote.content);
    final malmoiSuffix = quote.type == ContentType.malmoi
        ? '|${malmoiLengthToFirestore(quote.malmoiLength)}'
        : '';
    final base =
        '${quote.appId}|${contentTypeToFirestore(quote.type)}$malmoiSuffix|$contentNorm';
    final h = _fnv1a32(base).toRadixString(16).padLeft(8, '0');
    return 'official_${quote.appId}_${contentTypeToFirestore(quote.type)}_$h';
  }

  // 전체 글 목록 (공식 콘텐츠만, 타입별 필터링 가능)
  Stream<List<QuoteModel>> getQuotes({ContentType? type}) {
    Query query = _firestore
        .collection(_collectionPath)
        .where('app_id', isEqualTo: _appId)
        .where('is_user_post', isEqualTo: false)
        .orderBy('createdAt', descending: true);

    if (type != null) {
      query = query.where('type', isEqualTo: contentTypeToFirestore(type));
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => QuoteModel.fromFirestore(doc)).toList(),
    );
  }

  // 글모이 (사용자 게시글) 목록
  Stream<List<QuoteModel>> getUserPosts({bool? isApproved}) {
    Query query = _firestore
        .collection(_collectionPath)
        .where('app_id', isEqualTo: _appId)
        .where('is_user_post', isEqualTo: true)
        .orderBy('createdAt', descending: true);

    if (isApproved != null) {
      query = query.where('is_approved', isEqualTo: isApproved);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => QuoteModel.fromFirestore(doc)).toList(),
    );
  }

  // 신고된 글 목록
  Stream<List<QuoteModel>> getReportedPosts() {
    return _firestore
        .collection(_collectionPath)
        .where('app_id', isEqualTo: _appId)
        .where('report_count', isGreaterThan: 0)
        .orderBy('report_count', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => QuoteModel.fromFirestore(doc))
              .toList(),
        );
  }

  // 인기 글 TOP 5 (좋아요 + 공유 수 기준)
  Future<List<QuoteModel>> getTopPosts({int limit = 5}) async {
    final snapshot = await _firestore
        .collection(_collectionPath)
        .where('app_id', isEqualTo: _appId)
        .where('is_active', isEqualTo: true)
        .orderBy('like_count', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => QuoteModel.fromFirestore(doc)).toList();
  }

  Future<void> addQuote(QuoteModel quote) async {
    await _firestore.collection(_collectionPath).add(quote.toFirestore());
  }

  Future<void> addOfficialQuoteDeduped(QuoteModel quote) async {
    if (quote.isUserPost) {
      // Not an admin-only official post.
      await addQuote(quote);
      return;
    }

    final dedupKey = _dedupKeyForOfficialQuote(quote);
    final dedupRef = _firestore.collection('dedup_quotes').doc(dedupKey);
    final quoteRef = _firestore.collection(_collectionPath).doc();

    try {
      await _firestore.runTransaction((tx) async {
        final existing = await tx.get(dedupRef);
        if (existing.exists) {
          throw const DuplicateOfficialContentException(
            '중복 글입니다. 이미 등록된 콘텐츠가 있습니다.',
          );
        }

        tx.set(quoteRef, quote.toFirestore());
        tx.set(dedupRef, {
          'quote_id': quoteRef.id,
          'app_id': quote.appId,
          'type': contentTypeToFirestore(quote.type),
          'content_norm': _normalizeContent(quote.content),
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      final s = e.toString();
      final looksLikePermissionDenied =
          s.contains('permission-denied') ||
          s.contains('Missing or insufficient permissions');
      if (looksLikePermissionDenied) {
        // If Rules allow writing quotes but not dedup_quotes, the transaction
        // fails. Fall back to a non-deduped write so production isn't blocked.
        await addQuote(quote);
        return;
      }
      rethrow;
    }
  }

  Future<QuoteModel?> getQuoteById(String id) async {
    final doc = await _firestore.collection(_collectionPath).doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return QuoteModel.fromFirestore(doc);
  }

  Future<void> updateQuote(QuoteModel quote) async {
    await _firestore
        .collection(_collectionPath)
        .doc(quote.id)
        .update(quote.toFirestore());
  }

  Future<void> deleteQuote(String id) async {
    await _firestore.collection(_collectionPath).doc(id).delete();
  }

  // 사용자 게시글을 공식 콘텐츠로 격상
  Future<void> promoteUserPost(String id) async {
    await _firestore.collection(_collectionPath).doc(id).update({
      'is_user_post': false,
      'is_approved': true,
    });
  }

  // 글의 타입 변경 (예: 글모이 → 좋은생각)
  // 사용자 글을 공식 콘텐츠로 이동하므로 is_user_post도 false로 변경
  Future<void> changeContentType(String id, ContentType newType) async {
    await _firestore.collection(_collectionPath).doc(id).update({
      'type': contentTypeToFirestore(newType),
      'is_user_post': false,
      'is_approved': true,
    });
  }

  // 대시보드 통계 조회 (API 미활성화 대비 스냅샷 카운팅 방식 사용)
  Future<Map<String, int>> getStats() async {
    final totalQuotesSnapshot = await _firestore
        .collection(_collectionPath)
        .where('app_id', isEqualTo: _appId)
        .where('is_user_post', isEqualTo: false)
        .get();

    final totalThoughtsSnapshot = await _firestore
        .collection(_collectionPath)
        .where('app_id', isEqualTo: _appId)
        .where('is_user_post', isEqualTo: false)
        .where('type', isEqualTo: 'thought')
        .get();

    final pendingUserPostsSnapshot = await _firestore
        .collection(_collectionPath)
        .where('app_id', isEqualTo: _appId)
        .where('is_user_post', isEqualTo: true)
        .where('is_approved', isEqualTo: false)
        .get();

    return {
      'totalQuotes': totalQuotesSnapshot.size,
      'totalThoughts': totalThoughtsSnapshot.size,
      'pendingUserPosts': pendingUserPostsSnapshot.size,
    };
  }
}
