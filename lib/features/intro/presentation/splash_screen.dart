import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../data/intro_image_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static String? _lastShownRemoteUrl;
  static String? _lastShownFallbackAssetPath;

  final IntroImageService _introImageService = IntroImageService();
  late Future<String?> _imageUrlFuture;
  late final String _fallbackAssetPath;

  @override
  void initState() {
    super.initState();
    _imageUrlFuture = _introImageService.getRandomIntroImageUrl(
      previousUrl: _lastShownRemoteUrl,
    );
    _fallbackAssetPath = _pickFallbackAsset(_lastShownFallbackAssetPath);
    _lastShownFallbackAssetPath = _fallbackAssetPath;
    _navigateToNextScreen();
  }

  String _pickFallbackAsset(String? previousAssetPath) {
    final candidates = List<String>.generate(
      5,
      (index) =>
          'assets/intro/intro_${(index + 1).toString().padLeft(2, '0')}.webp',
    );

    if (previousAssetPath != null && candidates.length > 1) {
      candidates.remove(previousAssetPath);
    }

    return candidates[Random().nextInt(candidates.length)];
  }

  Future<void> _navigateToNextScreen() async {
    await Future.wait([
      Future.delayed(const Duration(seconds: 3)),
      _imageUrlFuture.timeout(const Duration(seconds: 3),
          onTimeout: () => null),
    ]);

    if (mounted) {
      context.go('/intro');
    }
  }

  Widget _buildFallbackImage() {
    return Image.asset(
      _fallbackAssetPath,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: FutureBuilder<String?>(
          future: _imageUrlFuture,
          builder: (context, snapshot) {
            // 로딩 중이거나 데이터를 못 가져온 경우 로컬 Fallback 노출
            if (snapshot.connectionState == ConnectionState.waiting) {
              debugPrint(
                  '[SplashScreen] showing fallback while loading: $_fallbackAssetPath');
              return _buildFallbackImage();
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data == null) {
              debugPrint(
                  '[SplashScreen] showing fallback due to null/error: $_fallbackAssetPath');
              return _buildFallbackImage();
            }

            _lastShownRemoteUrl = snapshot.data!;
            debugPrint(
                '[SplashScreen] showing remote image: ${snapshot.data!}');

            // 정상적으로 URL을 받아온 경우 캐시된 이미지 렌더링
            return CachedNetworkImage(
              imageUrl: snapshot.data!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              // 이미지 다운로드 중이거나 에러 발생 시 Fallback 유지
              placeholder: (context, url) => _buildFallbackImage(),
              errorWidget: (context, url, error) => _buildFallbackImage(),
            );
          },
        ),
      ),
    );
  }
}
