import 'package:flutter/material.dart';

import '../../domain/reaction_type.dart';

class ReactionBottomSheetItem {
  final ReactionType type;
  final String label;
  final String assetPath;
  final int count;
  final bool selected;
  final bool disabled;
  final Future<void> Function() onTap;

  const ReactionBottomSheetItem({
    required this.type,
    required this.label,
    required this.assetPath,
    required this.count,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });
}

class ReactionBottomSheet extends StatelessWidget {
  final List<ReactionBottomSheetItem> items;

  const ReactionBottomSheet({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1F2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0x33FFFFFF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                '공감 남기기',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0x1AFFFFFF)),
            for (int i = 0; i < items.length; i++) ...[
              _ReactionBottomSheetRow(item: items[i]),
              if (i < items.length - 1)
                const Divider(
                    height: 1, thickness: 1, color: Color(0x1AFFFFFF)),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ReactionBottomSheetRow extends StatelessWidget {
  final ReactionBottomSheetItem item;

  const _ReactionBottomSheetRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.disabled ? null : () => item.onTap(),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Image.asset(
                item.assetPath,
                width: 24,
                height: 24,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.emoji_emotions_outlined,
                  size: 24,
                  color: item.selected ? const Color(0xFFFD2F79) : Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        item.selected ? FontWeight.w700 : FontWeight.w600,
                    color:
                        item.selected ? const Color(0xFFFD2F79) : Colors.white,
                  ),
                ),
              ),
              Text(
                '${item.count}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: item.selected
                      ? const Color(0xFFFD2F79)
                      : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
