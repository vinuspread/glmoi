import 'package:flutter/material.dart';

class ImmersiveCard extends StatelessWidget {
  final String content;
  final String author;
  final String? imageUrl;
  final double fontSize;

  const ImmersiveCard({
    super.key,
    required this.content,
    required this.author,
    this.imageUrl,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Fallback dark color
        image: imageUrl != null
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Stack(
        children: [
          // Dim Layer
          Container(
            color: Colors.black.withAlpha(153), // 60% dim
          ),

          // Content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Main Text
                  Text(
                    content,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      // NotoSans removed, will inherit Pretendard
                      color: Colors.white,
                      fontSize: fontSize,
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Author
                  Text(
                    author,
                    style: TextStyle(
                      color: Colors.white.withAlpha(204),
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
