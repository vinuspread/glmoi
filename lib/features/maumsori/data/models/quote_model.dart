import 'package:cloud_firestore/cloud_firestore.dart';

enum ContentType {
  quote, // 한줄명언
  thought, // 좋은생각
  malmoi, // 글모이
}

enum MalmoiLength {
  short, // short-form (centered like quote)
  long, // long-form (top-aligned like thought)
}

enum ContentFont { gothic, serif }

enum ContentFontThickness {
  regular, // Regular
  thick, // Next step after regular (per-font mapping)
}

String malmoiLengthToFirestore(MalmoiLength v) {
  switch (v) {
    case MalmoiLength.short:
      return 'short';
    case MalmoiLength.long:
      return 'long';
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

String contentFontToFirestore(ContentFont font) {
  switch (font) {
    case ContentFont.gothic:
      return 'gothic';
    case ContentFont.serif:
      return 'serif';
  }
}

ContentFont contentFontFromFirestore(String? raw) {
  switch (raw) {
    case 'serif':
      return ContentFont.serif;
    case 'gothic':
    default:
      return ContentFont.gothic;
  }
}

String contentFontThicknessToFirestore(ContentFontThickness thickness) {
  switch (thickness) {
    case ContentFontThickness.regular:
      return 'regular';
    case ContentFontThickness.thick:
      return 'thick';
  }
}

ContentFontThickness contentFontThicknessFromFirestore(String? raw) {
  switch (raw) {
    case 'thick':
      return ContentFontThickness.thick;
    case 'regular':
    default:
      return ContentFontThickness.regular;
  }
}

String contentTypeToFirestore(ContentType type) {
  switch (type) {
    case ContentType.quote:
      return 'quote';
    case ContentType.thought:
      return 'thought';
    case ContentType.malmoi:
      return 'malmoi';
  }
}

ContentType contentTypeFromFirestore(String? raw) {
  switch (raw) {
    case 'thought':
      return ContentType.thought;
    case 'malmoi':
      return ContentType.malmoi;
    case 'quote':
    default:
      return ContentType.quote;
  }
}

class QuoteModel {
  final String id;
  final String appId; // Multi-app support
  final ContentType type; // 한줄명언 or 좋은생각
  final MalmoiLength malmoiLength; // 글모이 length mode
  final String content;
  final String author;
  final String category;
  final String? imageUrl; // 매칭된 이미지 URL
  final ContentFont font; // 글 폰트 (고딕/명조)
  final ContentFontThickness fontThickness; // 글 두께 (보통/두껍게)
  final DateTime createdAt;
  final bool isActive; // 노출 상태
  final bool isUserPost; // 글모이(사용자 게시글) 여부
  final bool isApproved; // 검수 승인 여부
  final int reportCount; // 신고 횟수
  final int likeCount; // 좋아요 수
  final int shareCount; // 공유 수

  // Report reason breakdown (populated by user app)
  final Map<String, int> reportReasons;
  final String? lastReportReasonCode;

  QuoteModel({
    required this.id,
    this.appId = 'maumsori',
    required this.type,
    this.malmoiLength = MalmoiLength.short,
    required this.content,
    this.author = '',
    this.category = '일반',
    this.imageUrl,
    this.font = ContentFont.gothic,
    this.fontThickness = ContentFontThickness.regular,
    required this.createdAt,
    this.isActive = true,
    this.isUserPost = false,
    this.isApproved = true,
    this.reportCount = 0,
    this.likeCount = 0,
    this.shareCount = 0,

    this.reportReasons = const {},
    this.lastReportReasonCode,
  });

  factory QuoteModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final parsedType = contentTypeFromFirestore(data['type']);

    final rawReasons = data['report_reasons'];
    final reasons = <String, int>{};
    if (rawReasons is Map) {
      for (final e in rawReasons.entries) {
        final k = e.key;
        final v = e.value;
        if (k is! String) continue;
        if (v is int) {
          reasons[k] = v;
        } else if (v is num) {
          reasons[k] = v.toInt();
        }
      }
    }

    return QuoteModel(
      id: doc.id,
      appId: data['app_id'] ?? 'maumsori',
      type: parsedType,
      malmoiLength: parsedType == ContentType.malmoi
          ? malmoiLengthFromFirestore(data['malmoi_length'])
          : MalmoiLength.short,
      content: data['content'] ?? '',
      author: data['author'] ?? '',
      category: data['category'] ?? '일반',
      imageUrl: data['image_url'],
      font: contentFontFromFirestore(data['font_style']),
      fontThickness: contentFontThicknessFromFirestore(data['font_weight']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['is_active'] ?? true,
      isUserPost: data['is_user_post'] ?? false,
      isApproved: data['is_approved'] ?? true,
      reportCount: data['report_count'] ?? 0,
      likeCount: data['like_count'] ?? 0,
      shareCount: data['share_count'] ?? 0,

      reportReasons: reasons,
      lastReportReasonCode: data['last_report_reason_code'],
    );
  }

  Map<String, dynamic> toFirestore() {
    final out = <String, dynamic>{
      'app_id': appId,
      'type': contentTypeToFirestore(type),
      if (type == ContentType.malmoi)
        'malmoi_length': malmoiLengthToFirestore(malmoiLength),
      'content': content,
      'author': author,
      'category': category,
      'image_url': imageUrl,
      'font_style': contentFontToFirestore(font),
      'font_weight': contentFontThicknessToFirestore(fontThickness),
      'createdAt': Timestamp.fromDate(createdAt),
      'is_active': isActive,
      'is_user_post': isUserPost,
      'is_approved': isApproved,
      'report_count': reportCount,
      'like_count': likeCount,
      'share_count': shareCount,
    };
    return out;
  }

  QuoteModel copyWith({
    String? content,
    String? author,
    String? category,
    String? imageUrl,
    DateTime? createdAt,
    bool? isActive,
    bool? isUserPost,
    bool? isApproved,
    int? reportCount,
    int? likeCount,
    int? shareCount,
    Map<String, int>? reportReasons,
    String? lastReportReasonCode,
    ContentType? type,
    MalmoiLength? malmoiLength,
    ContentFont? font,
    ContentFontThickness? fontThickness,
  }) {
    return QuoteModel(
      id: id,
      appId: appId,
      type: type ?? this.type,
      malmoiLength: malmoiLength ?? this.malmoiLength,
      content: content ?? this.content,
      author: author ?? this.author,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      font: font ?? this.font,
      fontThickness: fontThickness ?? this.fontThickness,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      isUserPost: isUserPost ?? this.isUserPost,
      isApproved: isApproved ?? this.isApproved,
      reportCount: reportCount ?? this.reportCount,
      likeCount: likeCount ?? this.likeCount,
      shareCount: shareCount ?? this.shareCount,

      reportReasons: reportReasons ?? this.reportReasons,
      lastReportReasonCode: lastReportReasonCode ?? this.lastReportReasonCode,
    );
  }
}
