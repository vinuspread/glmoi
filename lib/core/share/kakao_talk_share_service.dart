import 'dart:typed_data';

import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart' as kshare;

class KakaoTalkShareContent {
  final String text;
  final Uri? link;
  final String? title;
  final String? description;
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
  // 스토어 출시 전: 접근 가능한 랜딩 URL 사용
  // 스토어 출시 후: 'https://play.google.com/store/apps/details?id=co.vinus.glmoi' 로 교체
  static final Uri defaultShareLink = Uri.parse('https://glmoi-prod.web.app');

  static Future<void> share(KakaoTalkShareContent content) async {
    final isAvailable =
        await kshare.ShareClient.instance.isKakaoTalkSharingAvailable();
    if (!isAvailable) {
      throw StateError('KakaoTalk sharing is not available');
    }

    final shareLink = content.link ?? defaultShareLink;

    // Always use Feed Template to show App Card/OG Image effect
    await _shareFeed(content, shareLink);
  }

  static Future<void> _shareFeed(
      KakaoTalkShareContent content, Uri shareLink) async {
    final template = kshare.FeedTemplate(
      content: kshare.Content(
        title: content.title ?? '좋은 글 모음',
        description: content.description ?? content.text,
        imageUrl: Uri.parse(
            'https://firebasestorage.googleapis.com/v0/b/glmoi-prod.firebasestorage.app/o/share.png?alt=media&token=eb82f569-c562-4af0-932b-e39243c55c1d'), // User's Custom Banner (2026-02-18)
        link: kshare.Link(
          webUrl: shareLink,
          mobileWebUrl: shareLink,
          androidExecutionParams: {'route': '/'},
          iosExecutionParams: {'route': '/'},
        ),
        imageWidth: 800,
        imageHeight: 400,
      ),
      social: kshare.Social(
        likeCount: content.likeCount,
        sharedCount: content.shareCount,
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
  }

  static Future<void> _shareText(
      KakaoTalkShareContent content, Uri shareLink) async {
    final template = kshare.TextTemplate(
      text: content.text,
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
