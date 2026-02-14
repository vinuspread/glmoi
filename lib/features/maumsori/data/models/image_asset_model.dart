import 'package:cloud_firestore/cloud_firestore.dart';

class ImageAssetModel {
  final String id;
  final String appId;
  final String originalUrl; // Storage 원본 URL
  final String thumbnailUrl; // 썸네일 URL
  final String? webpUrl; // WebP 최적화 URL (Functions 생성)
  final DateTime uploadedAt;
  final int width;
  final int height;
  final int fileSize; // bytes
  final int usageCount; // 사용된 횟수
  final bool isActive;

  ImageAssetModel({
    required this.id,
    this.appId = 'maumsori',
    required this.originalUrl,
    required this.thumbnailUrl,
    this.webpUrl,
    required this.uploadedAt,
    this.width = 0,
    this.height = 0,
    this.fileSize = 0,
    this.usageCount = 0,
    this.isActive = true,
  });

  factory ImageAssetModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ImageAssetModel(
      id: doc.id,
      appId: data['app_id'] ?? 'maumsori',
      originalUrl: data['original_url'] ?? '',
      thumbnailUrl: data['thumbnail_url'] ?? '',
      webpUrl: data['webp_url'],
      uploadedAt: (data['uploaded_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      width: data['width'] ?? 0,
      height: data['height'] ?? 0,
      fileSize: data['file_size'] ?? 0,
      usageCount: data['usage_count'] ?? 0,
      isActive: data['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'app_id': appId,
      'original_url': originalUrl,
      'thumbnail_url': thumbnailUrl,
      'webp_url': webpUrl,
      'uploaded_at': Timestamp.fromDate(uploadedAt),
      'width': width,
      'height': height,
      'file_size': fileSize,
      'usage_count': usageCount,
      'is_active': isActive,
    };
  }

  ImageAssetModel copyWith({
    String? originalUrl,
    String? thumbnailUrl,
    String? webpUrl,
    int? usageCount,
    bool? isActive,
  }) {
    return ImageAssetModel(
      id: id,
      appId: appId,
      originalUrl: originalUrl ?? this.originalUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      webpUrl: webpUrl ?? this.webpUrl,
      uploadedAt: uploadedAt,
      width: width,
      height: height,
      fileSize: fileSize,
      usageCount: usageCount ?? this.usageCount,
      isActive: isActive ?? this.isActive,
    );
  }
}
