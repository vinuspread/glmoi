import 'package:flutter/material.dart';

class QuoteEditorDialog extends StatelessWidget {
  final bool isEdit;
  final TextEditingController contentController;
  final TextEditingController authorController;
  final TextEditingController categoryController;
  final Future<void> Function() onSave;

  const QuoteEditorDialog({
    super.key,
    required this.isEdit,
    required this.contentController,
    required this.authorController,
    required this.categoryController,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        isEdit ? '명언 수정' : '새 명언 추가',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: contentController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: '명언 내용',
              hintText: '내용을 입력하세요',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: authorController,
            decoration: const InputDecoration(
              labelText: '작가/출처',
              hintText: '예: 무명, 키케로',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: categoryController.text,
            items: [
              '힐링',
              '응원',
              '행복',
              '지혜',
              '기타',
            ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (val) => categoryController.text = val ?? '힐링',
            decoration: const InputDecoration(labelText: '카테고리'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (contentController.text.isNotEmpty) {
              await onSave();
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: const Text('저장'),
        ),
      ],
    );
  }
}
