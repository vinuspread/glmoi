import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'kakao_talk_share_service.dart';

/// 공유 수단 선택 바텀시트
///
/// 사용법:
/// ```dart
/// await ShareSheet.show(
///   context: context,
///   content: KakaoTalkShareContent(text: '...'),
///   plainText: '공유할 텍스트',
/// );
/// ```
///
/// 반환값: 실제로 공유가 실행됐으면 true, 취소면 false
Future<bool> showShareSheet({
  required BuildContext context,
  required KakaoTalkShareContent content,
  required String plainText,
}) async {
  final result = await showModalBottomSheet<_ShareResult>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _ShareSheet(content: content, plainText: plainText),
  );

  if (result == null) return false;
  return result.shared;
}

enum _ShareMethod { kakao, other }

class _ShareResult {
  final bool shared;
  const _ShareResult(this.shared);
}

class _ShareSheet extends StatefulWidget {
  final KakaoTalkShareContent content;
  final String plainText;

  const _ShareSheet({required this.content, required this.plainText});

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  bool _loading = false;

  Future<void> _onTap(_ShareMethod method) async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      switch (method) {
        case _ShareMethod.kakao:
          await KakaoTalkShareService.share(widget.content);
          if (context.mounted) Navigator.pop(context, const _ShareResult(true));

        case _ShareMethod.other:
          final result = await SharePlus.instance.share(
            ShareParams(
              text: widget.plainText,
              subject: widget.content.title,
            ),
          );
          if (!context.mounted) return;
          // ShareResultStatus.dismissed = 사용자가 취소
          final shared = result.status != ShareResultStatus.dismissed;
          Navigator.pop(context, _ShareResult(shared));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context, const _ShareResult(false));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('공유 실패: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '공유하기',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _ShareOption(
                  icon: Image.asset(
                    'assets/icons/kakao_icon.png',
                    width: 36,
                    height: 36,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.chat_bubble_rounded,
                      color: Color(0xFF391B1B),
                      size: 36,
                    ),
                  ),
                  label: '카카오톡',
                  onTap: _loading ? null : () => _onTap(_ShareMethod.kakao),
                ),
                const SizedBox(width: 24),
                _ShareOption(
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: Colors.black54,
                    size: 36,
                  ),
                  label: '기타',
                  onTap: _loading ? null : () => _onTap(_ShareMethod.other),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Center(child: LinearProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: icon),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
