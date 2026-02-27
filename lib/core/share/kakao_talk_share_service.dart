import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart' as kshare;

import '../remote_config/remote_config_service.dart';

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
  static Future<void> share(KakaoTalkShareContent content) async {
    final isAvailable =
        await kshare.ShareClient.instance.isKakaoTalkSharingAvailable();
    if (!isAvailable) {
      throw StateError('KakaoTalk sharing is not available');
    }

    // Remote Config에서 공유 링크를 가져온다.
    // Firebase 콘솔 > Remote Config > share_link 값으로 앱 재배포 없이 변경 가능.
    final shareLink =
        content.link ?? Uri.parse(RemoteConfigService.getShareLink());

    // 게시글 텍스트를 그대로 전달 (TextTemplate)
    await _shareText(content, shareLink);
  }

  // 기본 배너 이미지 URL (합성 이미지 업로드 실패 시 폴백)
  static const _defaultBannerUrl =
      'https://firebasestorage.googleapis.com/v0/b/glmoi-prod.firebasestorage.app/o/share.png?alt=media&token=eb82f569-c562-4af0-932b-e39243c55c1d';

  static Future<void> _shareFeed(
      KakaoTalkShareContent content, Uri shareLink) async {
    final imageUri = Uri.parse(content.imageUrl ?? _defaultBannerUrl);
    final template = kshare.FeedTemplate(
      content: kshare.Content(
        title: content.title ?? '좋은 글 모음',
        description: content.description ?? content.text,
        imageUrl: imageUri,
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
  }
}
