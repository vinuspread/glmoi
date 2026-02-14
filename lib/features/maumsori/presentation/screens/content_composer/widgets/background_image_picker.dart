import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_admin/core/theme/app_theme.dart';

import '../../../../data/models/image_asset_model.dart';

class BackgroundImagePicker extends StatelessWidget {
  final AsyncValue<List<ImageAssetModel>> imagesAsync;
  final String? selectedImageUrl;
  final ValueChanged<String> onSelect;

  const BackgroundImagePicker({
    super.key,
    required this.imagesAsync,
    required this.selectedImageUrl,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return imagesAsync.when(
      data: (images) {
        if (images.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Text(
              '등록된 배경 이미지가 없습니다.\n이미지 풀에서 먼저 업로드해주세요.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          );
        }

        const tileSize = 80.0;
        const spacing = 10.0;
        const rows = 3;
        final height = (tileSize * rows) + (spacing * (rows - 1));

        return SizedBox(
          height: height,
          child: GridView.builder(
            primary: false,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: tileSize,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: 1,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              final image = images[index];
              final thumbUrl = image.thumbnailUrl.isNotEmpty
                  ? image.thumbnailUrl
                  : image.originalUrl;

              final backgroundUrl =
                  (image.webpUrl != null && image.webpUrl!.isNotEmpty)
                  ? image.webpUrl!
                  : image.originalUrl;

              final isSelected = selectedImageUrl == backgroundUrl;

              return GestureDetector(
                onTap: () => onSelect(backgroundUrl),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryPurple
                          : AppTheme.border,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(thumbUrl, fit: BoxFit.cover),
                      if (isSelected)
                        const Positioned(
                          top: 6,
                          right: 6,
                          child: Icon(
                            Icons.check_circle,
                            size: 18,
                            color: AppTheme.primaryPurple,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Text(
          '배경 이미지 로딩 오류: $err',
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
    );
  }
}
