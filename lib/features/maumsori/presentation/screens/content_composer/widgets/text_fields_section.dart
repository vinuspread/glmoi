import 'package:flutter/material.dart';

class TextFieldsSection extends StatelessWidget {
  final TextEditingController contentController;
  final TextEditingController authorController;
  final VoidCallback onChanged;
  final String? badWordsWarning;
  final int contentMaxLength;
  final int contentMaxLines;

  const TextFieldsSection({
    super.key,
    required this.contentController,
    required this.authorController,
    required this.onChanged,
    this.badWordsWarning,
    this.contentMaxLength = 2000,
    this.contentMaxLines = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '본문',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: contentController,
          maxLines: contentMaxLines,
          maxLength: contentMaxLength,
          onChanged: (_) => onChanged(),
          decoration: const InputDecoration(
            hintText: '마음을 울리는 문장을 작성해주세요...',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(16),
          ),
        ),
        if (badWordsWarning != null) ...[
          const SizedBox(height: 10),
          Text(
            badWordsWarning!,
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 32),
        const Text(
          '작가/출처',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: authorController,
          onChanged: (_) => onChanged(),
          decoration: const InputDecoration(
            hintText: '예: 무명, 키케로, 법정 스님',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
