import 'package:flutter/material.dart';

class ImageOptionsDialog extends StatelessWidget {
  final Future<void> Function(BuildContext context) onFixMetadata;
  final VoidCallback onCancel;
  final Future<void> Function(BuildContext context) onDelete;

  const ImageOptionsDialog({
    super.key,
    required this.onFixMetadata,
    required this.onCancel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('이미지 관리'),
      content: const Text('이 이미지를 삭제하시겠습니까?'),
      actions: [
        TextButton(
          onPressed: () => onFixMetadata(context),
          child: const Text('메타데이터 수정'),
        ),
        TextButton(onPressed: onCancel, child: const Text('취소')),
        TextButton(
          onPressed: () => onDelete(context),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('삭제'),
        ),
      ],
    );
  }
}
