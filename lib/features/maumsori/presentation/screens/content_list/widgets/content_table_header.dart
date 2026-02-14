import 'package:flutter/material.dart';
import 'package:app_admin/core/theme/app_theme.dart';

import '../../../../data/models/quote_model.dart';

class ContentTableHeader extends StatelessWidget {
  final ContentType type;

  const ContentTableHeader({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: const Text(
              '노출여부',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (type != ContentType.quote)
            const SizedBox(
              width: 80,
              child: Text(
                '카테고리',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(width: 24),
          const SizedBox(width: 56),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: const Text(
              '내용',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: const Text(
              '작가',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            width: 100,
            child: const Text(
              '지표',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            width: 100,
            child: const Text(
              '등록일',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              '작업',
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
