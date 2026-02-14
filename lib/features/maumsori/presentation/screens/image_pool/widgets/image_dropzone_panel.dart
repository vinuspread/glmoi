import 'package:flutter/material.dart';
import 'package:app_admin/core/theme/app_theme.dart';

class ImageDropzonePanel extends StatelessWidget {
  final bool isDragging;
  final bool isUploading;
  final int bulkTotal;
  final int bulkDone;
  final bool isDropzoneRegistered;
  final String? dropzoneError;
  final Widget? dropzoneView;
  final VoidCallback onPickMultiple;

  const ImageDropzonePanel({
    super.key,
    required this.isDragging,
    required this.isUploading,
    required this.bulkTotal,
    required this.bulkDone,
    required this.isDropzoneRegistered,
    required this.dropzoneError,
    required this.dropzoneView,
    required this.onPickMultiple,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 120,
        decoration: BoxDecoration(
          color: isDragging ? AppTheme.accentLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDragging ? AppTheme.primaryPurple : AppTheme.border,
            width: isDragging ? 2 : 1,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (dropzoneView != null) dropzoneView!,
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.accentLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.cloud_upload_outlined,
                      color: AppTheme.primaryPurple,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '이미지를 여기에 드롭해서 대량 업로드',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isUploading && bulkTotal > 0
                              ? '업로드 중: $bulkDone / $bulkTotal'
                              : (isDropzoneRegistered
                                    ? 'Drag & Drop 또는 오른쪽 버튼으로 여러 장 선택'
                                    : '오른쪽 버튼으로 여러 장 선택 (Drag & Drop 비활성)'),
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                        if (dropzoneError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'Dropzone error: $dropzoneError',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: isUploading ? null : onPickMultiple,
                    icon: const Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 18,
                    ),
                    label: const Text('여러 장 선택'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
