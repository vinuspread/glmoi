import 'dart:typed_data';

import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart' as kshare;

class KakaoTalkShareContent {
  final String text;
  final Uri? link;

  // Reserved for future expansion (image + text + link).
  final Uint8List? imageBytes;
  final Uri? imageUrl;

  const KakaoTalkShareContent({
    required this.text,
    this.link,
    this.imageBytes,
    this.imageUrl,
  });
}

class KakaoTalkShareService {
  static final Uri defaultShareLink =
      Uri.parse('https://play.google.com/store/apps/details?id=co.vinus.glmoi');

  static Future<void> share(KakaoTalkShareContent content) async {
    // Text-only for now.
    await shareText(text: content.text, link: content.link);
  }

  static Future<void> shareText({
    required String text,
    Uri? link,
  }) async {
    final shareLink = link ?? defaultShareLink;
    final isAvailable =
        await kshare.ShareClient.instance.isKakaoTalkSharingAvailable();
    if (!isAvailable) {
      throw StateError('KakaoTalk sharing is not available');
    }

    final template = kshare.TextTemplate(
      text: text,
      link: kshare.Link(
        webUrl: shareLink,
        mobileWebUrl: shareLink,
      ),
      buttonTitle: '앱에서 보기',
    );

    final uri =
        await kshare.ShareClient.instance.shareDefault(template: template);
    await kshare.ShareClient.instance.launchKakaoTalk(uri);
  }
}
