import 'package:flutter/material.dart';

class ContentDeleteDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const ContentDeleteDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('글 삭제'),
      content: const Text('이 글을 삭제하시겠습니까?\n삭제된 글은 복구할 수 없습니다.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('삭제'),
        ),
      ],
    );
  }
}
