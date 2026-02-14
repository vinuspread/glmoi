import 'dart:typed_data';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/image_asset_model.dart';

final imageRepositoryProvider = Provider((ref) => ImageRepository());

class ImageRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collectionPath = 'image_assets';
  final String _appId = 'maumsori';

  static final Random _rng = _createRng();

  static Random _createRng() {
    try {
      return Random.secure();
    } catch (_) {
      // Random.secure() is not available on all platforms (notably web).
      // Fallback is fine here since this is used only for collision resistance,
      // not for cryptographic security.
      return Random();
    }
  }

  int _nextUint32() {
    // Avoid bitwise shifts >= 32 which can become 0 in JS.
    // Use two 16-bit draws to construct a 32-bit value safely.
    final a = _rng.nextInt(0x10000); // 16-bit
    final b = _rng.nextInt(0x10000); // 16-bit
    return (a * 0x10000) + b;
  }

  String _extractSafeExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == fileName.length - 1) return '';

    final rawExt = fileName.substring(dotIndex + 1).toLowerCase();
    final safeExt = rawExt.replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (safeExt.isEmpty) return '';
    return '.$safeExt';
  }

  String _generateStorageObjectName(String originalFileName) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = _nextUint32().toRadixString(16).padLeft(8, '0');
    final ext = _extractSafeExtension(originalFileName);
    return '${ts}_$rand$ext';
  }

  // 이미지 풀 목록 조회 (최신순 또는 사용빈도순)
  Stream<List<ImageAssetModel>> getImages({String sortBy = 'uploaded_at'}) {
    Query query = _firestore
        .collection(_collectionPath)
        .where('app_id', isEqualTo: _appId)
        .where('is_active', isEqualTo: true);

    if (sortBy == 'usage_count') {
      query = query.orderBy('usage_count', descending: true);
    } else {
      query = query.orderBy('uploaded_at', descending: true);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => ImageAssetModel.fromFirestore(doc))
          .toList(),
    );
  }

  // 이미지 업로드 (Storage + Firestore 메타데이터)
  Future<ImageAssetModel> uploadImage({
    required String originalFileName,
    required Uint8List fileBytes,
    required String contentType,
    int? width,
    int? height,
  }) async {
    // Storage 업로드
    final objectName = _generateStorageObjectName(originalFileName);
    final storageRef = _storage.ref().child(
      'assets/$_appId/images/$objectName',
    );

    final uploadTask = await storageRef.putData(
      fileBytes,
      SettableMetadata(contentType: contentType),
    );

    final downloadUrl = await uploadTask.ref.getDownloadURL();

    // Firestore 메타데이터 저장
    final imageAsset = ImageAssetModel(
      id: '',
      originalUrl: downloadUrl,
      thumbnailUrl: downloadUrl, // 초기에는 동일, Functions에서 썸네일 생성 후 업데이트
      uploadedAt: DateTime.now(),
      width: width ?? 0,
      height: height ?? 0,
      fileSize: fileBytes.length,
    );

    await _firestore.collection(_collectionPath).add(imageAsset.toFirestore());

    return imageAsset.copyWith(originalUrl: downloadUrl);
  }

  // 이미지 사용 횟수 증가
  Future<void> incrementUsageCount(String imageId) async {
    await _firestore.collection(_collectionPath).doc(imageId).update({
      'usage_count': FieldValue.increment(1),
    });
  }

  // 이미지 삭제
  Future<void> deleteImage(
    String imageId, {
    required String originalUrl,
    String? thumbnailUrl,
    String? webpUrl,
  }) async {
    Future<void> tryDeleteUrl(String? url) async {
      if (url == null || url.isEmpty) return;
      try {
        final ref = _storage.refFromURL(url);
        await ref.delete();
      } catch (e) {
        // Storage 삭제 실패해도 Firestore는 삭제
        print('Storage delete failed: $e');
      }
    }

    // Storage objects (original + derived)
    await tryDeleteUrl(originalUrl);
    await tryDeleteUrl(thumbnailUrl);
    await tryDeleteUrl(webpUrl);

    // Firestore metadata
    await _firestore.collection(_collectionPath).doc(imageId).delete();
  }

  // 이미지 비활성화
  Future<void> deactivateImage(String imageId) async {
    await _firestore.collection(_collectionPath).doc(imageId).update({
      'is_active': false,
    });
  }

  // 이미지 총 개수 조회
  Future<int> getImageCount() async {
    // API 권한 이슈로 인해 직접 카운팅
    final snapshot = await _firestore
        .collection(_collectionPath)
        .where('app_id', isEqualTo: _appId)
        .where('is_active', isEqualTo: true)
        .get();

    return snapshot.size;
  }
}
