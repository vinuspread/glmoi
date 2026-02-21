import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  static const _bannerImageUrl =
      'https://firebasestorage.googleapis.com/v0/b/glmoi-prod.firebasestorage.app/o/share.png?alt=media&token=eb82f569-c562-4af0-932b-e39243c55c1d';

  static const _appUrl =
      'https://play.google.com/store/apps/details?id=co.vinus.glmoi';

  static File? _cachedBanner;

  static Future<bool> shareQuote({
    required String content,
    required String author,
  }) async {
    final authorLine = author.trim().isEmpty ? '' : '\n\n- ${author.trim()} -';
    final text = '$content$authorLine\n\n글모이 $_appUrl';

    final banner = await _banner();

    try {
      final result = banner != null
          ? await SharePlus.instance.share(
              ShareParams(text: text, files: [XFile(banner.path)]),
            )
          : await SharePlus.instance.share(ShareParams(text: text));
      return result.status != ShareResultStatus.dismissed;
    } catch (_) {
      final result = await SharePlus.instance.share(ShareParams(text: text));
      return result.status != ShareResultStatus.dismissed;
    }
  }

  static Future<File?> _banner() async {
    if (_cachedBanner != null && await _cachedBanner!.exists()) {
      return _cachedBanner;
    }
    try {
      final response = await http
          .get(Uri.parse(_bannerImageUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/glmoi_share_banner.png');
      await file.writeAsBytes(response.bodyBytes);
      _cachedBanner = file;
      return file;
    } catch (_) {
      return null;
    }
  }
}
