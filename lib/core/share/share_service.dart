import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  static const _appUrl =
      'https://play.google.com/store/apps/details?id=co.vinus.glmoi';

  static const _bannerPaths = [
    'banner/banner_01.png',
    'banner/banner_02.png',
    'banner/banner_03.png',
    'banner/banner_04.png',
  ];

  static Uint8List? _cachedBannerBytes;

  /// 배너 이미지 단독 파일을 반환한다.
  /// 기타 공유 시 합성 이미지와 함께 2번째 파일로 첨부하는 용도.
  /// 실패 시 null 반환.
  static Future<File?> getBannerFile() async {
    final bytes = await _bannerBytes();
    if (bytes == null) return null;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/glmoi_banner.png');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// 게시글 텍스트 + 배너를 합성한 이미지 파일을 반환한다.
  /// 실패 시 null 반환.
  static Future<File?> composeShareImage({
    required String content,
    required String author,
  }) async {
    final bannerBytes = await _bannerBytes();
    if (bannerBytes == null) return null;
    return _compose(content: content, author: author, bannerBytes: bannerBytes);
  }

  /// 합성 이미지를 Firebase Storage에 업로드하고 다운로드 URL을 반환한다.
  /// 카카오톡처럼 공개 URL이 필요한 경우 사용.
  /// 실패 시 null 반환.
  static Future<String?> uploadShareImage(File imageFile) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('shared_images/${DateTime.now().millisecondsSinceEpoch}.png');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  /// 시스템 공유 다이얼로그로 직접 공유 (share_sheet를 거치지 않는 경우 호환용).
  static Future<bool> shareQuote({
    required String content,
    required String author,
  }) async {
    try {
      final composed =
          await composeShareImage(content: content, author: author);

      final ShareResult result;
      if (composed != null) {
        result = await SharePlus.instance.share(
          ShareParams(files: [XFile(composed.path, mimeType: 'image/png')]),
        );
      } else {
        final authorLine =
            author.trim().isEmpty ? '' : '\n\n- ${author.trim()} -';
        result = await SharePlus.instance.share(
          ShareParams(text: '$content$authorLine\n\n글모이 $_appUrl'),
        );
      }
      return result.status != ShareResultStatus.dismissed;
    } catch (_) {
      return false;
    }
  }

  static Future<Uint8List?> _bannerBytes() async {
    if (_cachedBannerBytes != null) return _cachedBannerBytes;
    try {
      final path = _bannerPaths[Random().nextInt(_bannerPaths.length)];
      final ref = FirebaseStorage.instance.ref().child(path);
      final bytes = await ref.getData();
      if (bytes == null) return null;
      _cachedBannerBytes = bytes;
      return _cachedBannerBytes;
    } catch (_) {
      return null;
    }
  }

  static Future<File?> _compose({
    required String content,
    required String author,
    required Uint8List bannerBytes,
  }) async {
    try {
      const double canvasW = 800;
      const double pad = 48;
      const double textSize = 30;
      const double authorSize = 24;
      const double urlSize = 20;

      // Decode banner
      final codec = await ui.instantiateImageCodec(bannerBytes);
      final frame = await codec.getNextFrame();
      final bannerImg = frame.image;
      final bannerH = canvasW * bannerImg.height / bannerImg.width;

      // Build paragraphs
      final contentPara = _buildParagraph(
        content,
        fontSize: textSize,
        color: const Color(0xFF212121),
        maxWidth: canvasW - pad * 2,
        height: 1.7,
      );

      final authorText = author.trim().isEmpty ? '' : '— ${author.trim()} —';
      final authorPara = authorText.isEmpty
          ? null
          : _buildParagraph(
              authorText,
              fontSize: authorSize,
              color: const Color(0xFF757575),
              maxWidth: canvasW - pad * 2,
            );

      final urlPara = _buildParagraph(
        '글모이  $_appUrl',
        fontSize: urlSize,
        color: const Color(0xFF9E9E9E),
        maxWidth: canvasW - pad * 2,
      );

      final textBlockH = contentPara.height +
          (authorPara != null ? pad * 0.5 + authorPara.height : 0) +
          pad * 0.75 +
          urlPara.height;

      final totalH = pad + textBlockH + pad + bannerH;

      // Draw
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // White text area background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, canvasW, pad + textBlockH + pad),
        Paint()..color = Colors.white,
      );

      double y = pad;
      canvas.drawParagraph(contentPara, Offset(pad, y));
      y += contentPara.height;

      if (authorPara != null) {
        y += pad * 0.5;
        canvas.drawParagraph(authorPara, Offset(pad, y));
        y += authorPara.height;
      }

      y += pad * 0.75;
      canvas.drawParagraph(urlPara, Offset(pad, y));
      y += urlPara.height + pad;

      // Banner image
      canvas.drawImageRect(
        bannerImg,
        Rect.fromLTWH(
            0, 0, bannerImg.width.toDouble(), bannerImg.height.toDouble()),
        Rect.fromLTWH(0, y, canvasW, bannerH),
        Paint(),
      );

      final picture = recorder.endRecording();
      final image = await picture.toImage(canvasW.toInt(), totalH.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/glmoi_share_composed.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      return file;
    } catch (_) {
      return null;
    }
  }

  static ui.Paragraph _buildParagraph(
    String text, {
    required double fontSize,
    required Color color,
    required double maxWidth,
    double height = 1.5,
  }) {
    final pb = ui.ParagraphBuilder(
      ui.ParagraphStyle(fontSize: fontSize, height: height),
    )
      ..pushStyle(
          ui.TextStyle(color: color, fontSize: fontSize, height: height))
      ..addText(text);
    final para = pb.build();
    para.layout(ui.ParagraphConstraints(width: maxWidth));
    return para;
  }
}
