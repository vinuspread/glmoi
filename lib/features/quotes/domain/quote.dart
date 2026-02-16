import 'package:cloud_firestore/cloud_firestore.dart';

enum QuoteType { quote, thought, malmoi }

enum MalmoiLength { short, long }

QuoteType quoteTypeFromFirestore(String? raw) {
  switch (raw) {
    case 'thought':
      return QuoteType.thought;
    case 'malmoi':
    case 'glmoi':
      return QuoteType.malmoi;
    case 'quote':
    default:
      return QuoteType.quote;
  }
}

String quoteTypeToFirestore(QuoteType t) {
  switch (t) {
    case QuoteType.quote:
      return 'quote';
    case QuoteType.thought:
      return 'thought';
    case QuoteType.malmoi:
      return 'malmoi';
  }
}

MalmoiLength malmoiLengthFromFirestore(String? raw) {
  switch (raw) {
    case 'long':
      return MalmoiLength.long;
    case 'short':
    default:
      return MalmoiLength.short;
  }
}

class Quote {
  final String id;
  final String appId;
  final QuoteType type;
  final MalmoiLength malmoiLength;
  final String content;
  final String author;
  final String? authorName;
  final String? authorPhotoUrl;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isUserPost;
  final int likeCount;
  final int shareCount;
  final int reportCount;
  final Map<String, int> reactionCounts;

  // Ownership fields (used for "내 글" / edit / delete).
  // New posts should use `user_uid` (Firebase Auth uid). Legacy posts may only
  // have `user_provider` + `user_id`.
  final String? userUid;
  final String? userProvider;
  final String? userId;

  const Quote({
    required this.id,
    required this.appId,
    required this.type,
    required this.malmoiLength,
    required this.content,
    required this.author,
    this.authorName,
    this.authorPhotoUrl,
    required this.imageUrl,
    required this.createdAt,
    required this.isUserPost,
    required this.likeCount,
    required this.shareCount,
    required this.reportCount,
    this.reactionCounts = const <String, int>{},
    required this.userUid,
    required this.userProvider,
    required this.userId,
  });

  Quote copyWith({
    String? content,
    String? author,
    String? authorName,
    String? authorPhotoUrl,
    String? imageUrl,
    DateTime? createdAt,
    bool? isUserPost,
    int? likeCount,
    int? shareCount,
    int? reportCount,
    Map<String, int>? reactionCounts,
    String? userUid,
    String? userProvider,
    String? userId,
  }) {
    return Quote(
      id: id,
      appId: appId,
      type: type,
      malmoiLength: malmoiLength,
      content: content ?? this.content,
      author: author ?? this.author,
      authorName: authorName ?? this.authorName,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      isUserPost: isUserPost ?? this.isUserPost,
      likeCount: likeCount ?? this.likeCount,
      shareCount: shareCount ?? this.shareCount,
      reportCount: reportCount ?? this.reportCount,
      reactionCounts: reactionCounts ?? this.reactionCounts,
      userUid: userUid ?? this.userUid,
      userProvider: userProvider ?? this.userProvider,
      userId: userId ?? this.userId,
    );
  }

  factory Quote.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? const {};
    final type = quoteTypeFromFirestore(data['type'] as String?);

    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return 0;
    }

    Map<String, int> parseReactionCounts(dynamic v) {
      if (v is! Map) return const <String, int>{};
      final out = <String, int>{};
      for (final e in v.entries) {
        final k = e.key;
        final val = e.value;
        if (k is! String) continue;
        if (val is int) out[k] = val;
        if (val is num) out[k] = val.toInt();
      }
      return out;
    }

    return Quote(
      id: doc.id,
      appId: (data['app_id'] as String?) ?? 'maumsori',
      type: type,
      malmoiLength: type == QuoteType.malmoi
          ? malmoiLengthFromFirestore(data['malmoi_length'] as String?)
          : MalmoiLength.short,
      content: (data['content'] as String?) ?? '',
      author: (data['author'] as String?) ?? '',
      authorName: data['author_name'] as String?,
      authorPhotoUrl: data['author_photo_url'] as String?,
      imageUrl: data['image_url'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isUserPost: (data['is_user_post'] as bool?) ?? false,
      likeCount: asInt(data['like_count']),
      shareCount: asInt(data['share_count']),
      reportCount: asInt(data['report_count']),
      reactionCounts: parseReactionCounts(data['reaction_counts']),
      userUid: data['user_uid'] as String?,
      userProvider: data['user_provider'] as String?,
      userId: data['user_id'] as String?,
    );
  }
}
