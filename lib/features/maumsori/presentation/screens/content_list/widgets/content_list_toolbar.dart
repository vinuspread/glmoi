import 'package:flutter/material.dart';

class ContentListToolbar extends StatelessWidget {
  final int totalCount;
  final VoidCallback onCreate;

  const ContentListToolbar({
    super.key,
    required this.totalCount,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '총 $totalCount개',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('새 글 작성'),
        ),
      ],
    );
  }
}
