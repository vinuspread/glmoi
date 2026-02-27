import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'kakao_talk_share_service.dart';
import 'share_service.dart';

/// 공유 수단 선택 바텀시트
///
/// 카카오톡과 기타 공유 모두 동일한 합성 이미지(게시글 + 배너)를 사용한다.
/// - 기타: 합성 이미지 파일을 시스템 공유 시트로 전달
/// - 카카오톡: 합성 이미지를 Firebase Storage에 업로드 후 URL로 FeedTemplate 전달
///
/// 사용법:
/// ```dart
/// await showShareSheet(
///   context: context,
///   content: '게시글 내용',
///   author: '작성자',
///   likeCount: 10,
///   shareCount: 5,
/// );
/// ```
///
/// 반환값: 실제로 공유가 실행됐으면 true, 취소면 false
Future<bool> showShareSheet({
  required BuildContext context,
  required String content,
  required String author,
  int? likeCount,
  int? shareCount,
}) async {
  final result = await showModalBottomSheet<_ShareResult>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _ShareSheet(
      content: content,
      author: author,
      likeCount: likeCount,
      shareCount: shareCount,
    ),
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
  final String content;
  final String author;
  final int? likeCount;
  final int? shareCount;

  const _ShareSheet({
    required this.content,
    required this.author,
    this.likeCount,
    this.shareCount,
  });

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
          // 카카오: 게시글 텍스트 그대로 전달 (TextTemplate)
          final kakaoContent = KakaoTalkShareContent(
            text: widget.content,
            likeCount: widget.likeCount,
            shareCount: widget.shareCount,
          );
          await KakaoTalkShareService.share(kakaoContent);
          if (context.mounted) Navigator.pop(context, const _ShareResult(true));

        case _ShareMethod.other:
          // 기타: 합성 이미지(게시글+배너) 1장 전송
          final composedFile = await ShareService.composeShareImage(
            content: widget.content,
            author: widget.author,
          );

          final ShareResult result;
          final files = <XFile>[
            if (composedFile != null)
              XFile(composedFile.path, mimeType: 'image/png'),
          ];

          if (files.isNotEmpty) {
            result = await SharePlus.instance.share(
              ShareParams(
                files: files,
                text:
                    'https://play.google.com/store/apps/details?id=co.vinus.glmoi',
              ),
            );
          } else {
            // 이미지 합성 실패 시 텍스트로 폴백
            final authorLine = widget.author.trim().isEmpty
                ? ''
                : '\n\n- ${widget.author.trim()} -';
            result = await SharePlus.instance.share(
              ShareParams(text: '${widget.content}$authorLine'),
            );
          }
          if (!context.mounted) return;
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
