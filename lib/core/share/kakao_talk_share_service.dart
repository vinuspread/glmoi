import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart' as kshare;

import '../remote_config/remote_config_service.dart';

class KakaoShareKeyHashMismatchException implements Exception {
  final String originalMessage;
  final List<String> androidKeyHashes;

  const KakaoShareKeyHashMismatchException({
    required this.originalMessage,
    required this.androidKeyHashes,
  });

  String get message {
    if (androidKeyHashes.isEmpty) {
      return '카카오 키해시 불일치가 감지됐습니다. Kakao Developers > Android에 현재 배포 서명 키해시를 등록해주세요.';
    }
    return '카카오 키해시 불일치가 감지됐습니다. 등록 필요 키해시: ${androidKeyHashes.join(', ')}';
  }

  @override
  String toString() => message;
}

class KakaoTalkUnavailableException implements Exception {
  const KakaoTalkUnavailableException();

  @override
  String toString() => '카카오톡 앱을 사용할 수 없어 기타 공유로 전환이 필요합니다.';
}

class KakaoTalkShareContent {
  final String text;
  final Uri? link;
  final String? title;
  final String? description;

  /// 공유 카드에 표시할 이미지 URL.
  /// null이면 기본 배너 이미지를 사용한다.
  final String? imageUrl;
  final int? likeCount;
  final int? shareCount;

  const KakaoTalkShareContent({
    required this.text,
    this.link,
    this.title,
    this.description,
    this.imageUrl,
    this.likeCount,
    this.shareCount,
  });
}

class KakaoTalkShareService {
  static const MethodChannel _platformChannel =
      MethodChannel('co.vinus.glmoi/platform');

  static Future<void> share(KakaoTalkShareContent content) async {
    final isAvailable =
        await kshare.ShareClient.instance.isKakaoTalkSharingAvailable();
    if (!isAvailable) {
      throw const KakaoTalkUnavailableException();
    }

    // Remote Config에서 공유 링크를 가져온다.
    // Firebase 콘솔 > Remote Config > share_link 값으로 앱 재배포 없이 변경 가능.
    final shareLink =
        content.link ?? Uri.parse(RemoteConfigService.getShareLink());

    // 게시글 텍스트를 그대로 전달 (TextTemplate)
    await _shareText(content, shareLink);
  }

  static Future<void> _shareText(
      KakaoTalkShareContent content, Uri shareLink) async {
    try {
      final template = kshare.TextTemplate(
        text: content.text,
        link: kshare.Link(
          webUrl: shareLink,
          mobileWebUrl: shareLink,
          androidExecutionParams: {'route': '/'},
          iosExecutionParams: {'route': '/'},
        ),
        buttons: [
          kshare.Button(
            title: '앱에서 보기',
            link: kshare.Link(
              webUrl: shareLink,
              mobileWebUrl: shareLink,
              androidExecutionParams: {'route': '/'},
              iosExecutionParams: {'route': '/'},
            ),
          ),
        ],
      );

      final uri =
          await kshare.ShareClient.instance.shareDefault(template: template);
      await kshare.ShareClient.instance.launchKakaoTalk(uri);
    } catch (error) {
      final errorText = error.toString();
      final isKeyHashMismatch = isKeyHashMismatchErrorText(errorText);

      if (isKeyHashMismatch) {
        throw KakaoShareKeyHashMismatchException(
          originalMessage: errorText,
          androidKeyHashes: await _readAndroidKeyHashes(),
        );
      }

      rethrow;
    }
  }

  @visibleForTesting
  static bool isKeyHashMismatchErrorText(String text) {
    final normalized = text.toLowerCase().replaceAll(' ', '');
    return normalized.contains('keyhashmismatched') ||
        normalized.contains('androidkeyhashmismatched') ||
        normalized.contains('code:-401') ||
        normalized.contains('code=-401') ||
        normalized.contains('errorcode:-401') ||
        normalized.contains('errorcode=-401');
  }

  static Future<List<String>> _readAndroidKeyHashes() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const [];
    }
    try {
      final values = await _platformChannel.invokeMethod<List<dynamic>>(
        'getAndroidKeyHashes',
      );
      if (values == null) return const [];
      return values
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}
