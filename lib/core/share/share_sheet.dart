import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'share_service.dart';

/// 시스템 공유 시트를 즉시 연다.
///
/// 카카오톡 전용 공유는 사용하지 않으며,
/// 항상 "기타 공유"(시스템 선택 시트)로 공유한다.
///
/// 공유 payload:
/// - 이미지 성공: 게시글(텍스트+작성자+URL)+배너 합성 이미지 1장
///   카카오톡 외 앱(텔레그램·문자 등)에서는 text URL도 함께 전달되어 탭 가능한 링크로 노출
/// - 이미지 실패: 텍스트(게시글+작성자+앱 링크) 폴백
const _appUrl = 'https://play.google.com/store/apps/details?id=co.vinus.glmoi';

Future<bool> showShareSheet({
  required BuildContext context,
  required String content,
  required String author,
  int? likeCount,
  int? shareCount,
}) async {
  try {
    final composedFile = await ShareService.composeShareImage(
      content: content,
      author: author,
    );

    final ShareResult result;
    if (composedFile != null) {
      result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(composedFile.path, mimeType: 'image/png')],
          text: _appUrl, // 카카오톡은 무시, 텔레그램·문자 등은 탭 가능 링크로 노출
        ),
      );
    } else {
      // 이미지 합성 실패 시 텍스트 폴백
      final authorLine =
          author.trim().isEmpty ? '' : '\n\n- ${author.trim()} -';
      result = await SharePlus.instance.share(
        ShareParams(text: '$content$authorLine\n\n$_appUrl'),
      );
    }

    return result.status != ShareResultStatus.dismissed;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('공유 실패: $e')));
    }
    return false;
  }
}
