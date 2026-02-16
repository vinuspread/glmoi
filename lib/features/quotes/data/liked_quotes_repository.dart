import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final likedQuotesRepositoryProvider =
    Provider((ref) => LikedQuotesRepository());

class LikedQuotesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<LikedQuoteSnapshot>> watchLikedQuotes() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('liked_quotes')
        .orderBy('liked_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => LikedQuoteSnapshot.fromFirestore(doc))
          .toList();
    });
  }

  Future<Set<String>> getLikedQuoteIds() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {};
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('liked_quotes')
        .get();

    return snapshot.docs.map((doc) => doc.id).toSet();
  }
}

class LikedQuoteSnapshot {
  final String quoteId;
  final String appId;
  final String type;
  final String content;
  final String author;
  final String? authorName;
  final String? authorPhotoUrl;
  final String? imageUrl;
  final DateTime? likedAt;

  const LikedQuoteSnapshot({
    required this.quoteId,
    required this.appId,
    required this.type,
    required this.content,
    required this.author,
    this.authorName,
    this.authorPhotoUrl,
    this.imageUrl,
    this.likedAt,
  });

  factory LikedQuoteSnapshot.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw StateError('Document data is null');
    }

    final likedAtTimestamp = data['liked_at'] as Timestamp?;

    return LikedQuoteSnapshot(
      quoteId: doc.id,
      appId: (data['app_id'] as String?) ?? 'maumsori',
      type: (data['type'] as String?) ?? 'quote',
      content: (data['content'] as String?) ?? '',
      author: (data['author'] as String?) ?? '',
      authorName: data['author_name'] as String?,
      authorPhotoUrl: data['author_photo_url'] as String?,
      imageUrl: data['image_url'] as String?,
      likedAt: likedAtTimestamp?.toDate(),
    );
  }
}
