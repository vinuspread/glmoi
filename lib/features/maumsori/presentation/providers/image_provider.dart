import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/image_asset_model.dart';
import '../../data/repositories/image_repository.dart';

// 이미지 목록 스트림 (업로드 최신순)
final imageListProvider = StreamProvider<List<ImageAssetModel>>((ref) {
  return ref.watch(imageRepositoryProvider).getImages(sortBy: 'uploaded_at');
});

// 이미지 컨트롤러 Provider
final imageControllerProvider = Provider((ref) => ImageController(ref));

class ImageController {
  final Ref _ref;

  ImageController(this._ref);

  // 이미지 업로드
  Future<void> uploadImage({
    required String fileName,
    required Uint8List fileBytes,
    required String mimeType,
  }) async {
    await _ref
        .read(imageRepositoryProvider)
        .uploadImage(
          originalFileName: fileName,
          fileBytes: fileBytes,
          contentType: mimeType,
        );
  }

  // 이미지 삭제
  Future<void> deleteImage(
    String id, {
    required String originalUrl,
    String? thumbnailUrl,
    String? webpUrl,
  }) async {
    await _ref
        .read(imageRepositoryProvider)
        .deleteImage(
          id,
          originalUrl: originalUrl,
          thumbnailUrl: thumbnailUrl,
          webpUrl: webpUrl,
        );
  }

  // 사용 횟수 증가
  Future<void> incrementUsage(String id) async {
    await _ref.read(imageRepositoryProvider).incrementUsageCount(id);
  }
}
