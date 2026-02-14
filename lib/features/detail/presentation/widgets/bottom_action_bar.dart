import 'package:flutter/material.dart';

class BottomActionBar extends StatelessWidget {
  final VoidCallback onLike;
  final VoidCallback onShare;
  final bool isLiked;

  const BottomActionBar({
    super.key,
    required this.onLike,
    required this.onShare,
    this.isLiked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withAlpha(204),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Like Button
          _ActionButton(
            icon: isLiked ? Icons.favorite : Icons.favorite_border,
            label: '저장하기',
            color: isLiked ? const Color(0xFFEF4444) : Colors.white,
            onTap: onLike,
          ),

          // Share Button
          _ActionButton(
            icon: Icons
                .chat_bubble_outline, // Kakao-like icon logic handled by asset usually
            label: '카카오톡 공유',
            color: Colors.yellow,
            textColor: Colors.black,
            onTap: onShare,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.textColor = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
                    color: textColor == Colors.black
                        ? Colors.yellow
                        : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)
                .copyWith(
                    color: Colors.white), // Override for now for consistency
          ),
        ],
      ),
    );
  }
}
