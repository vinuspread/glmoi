import 'package:flutter/material.dart';

class ControlBar extends StatelessWidget {
  final VoidCallback onDecreaseFont;
  final VoidCallback onIncreaseFont;
  final VoidCallback onClose;
  final double currentFontSize;

  const ControlBar({
    super.key,
    required this.onDecreaseFont,
    required this.onIncreaseFont,
    required this.onClose,
    required this.currentFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Close Button
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: onClose,
            ),

            // Font Controls
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(77),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, color: Colors.white),
                    onPressed: onDecreaseFont,
                  ),
                  Text(
                    '${currentFontSize.toInt()}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: onIncreaseFont,
                  ),
                ],
              ),
            ),

            // Placeholder for balance
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}
