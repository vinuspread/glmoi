import 'package:flutter/material.dart';
import 'package:app_admin/core/theme/app_theme.dart';

class QuotesTableHeader extends StatelessWidget {
  const QuotesTableHeader({super.key});

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
      child: const Row(
        children: [
          SizedBox(
            width: 80,
            child: Text('카테고리', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 3,
            child: Text('내용', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text('작가/출처', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text('등록일', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            width: 80,
            child: Text(
              '작업',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
