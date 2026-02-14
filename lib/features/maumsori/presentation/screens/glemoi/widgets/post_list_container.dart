import 'package:flutter/material.dart';

class PostListContainer extends StatelessWidget {
  final int totalCount;
  final List<Widget> children;

  const PostListContainer({
    super.key,
    required this.totalCount,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '총 $totalCount개',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }
}
