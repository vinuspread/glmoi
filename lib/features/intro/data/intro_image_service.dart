import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

class IntroImageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> getRandomIntroImageUrl({String? previousUrl}) async {
    try {
      final imageValues = await _loadIntroImageValues();
      if (imageValues.isEmpty) {
        debugPrint('[IntroImageService] no image entries in manifest');
        return null;
      }

      final urls = await _resolveToDownloadUrls(imageValues);
      if (urls.isEmpty) {
        debugPrint(
            '[IntroImageService] no resolvable URLs from manifest values');
        return null;
      }

      if (previousUrl != null && urls.length > 1) {
        final filtered = urls.where((url) => url != previousUrl).toList();
        if (filtered.isNotEmpty) {
          final selected = filtered[Random().nextInt(filtered.length)];
          debugPrint(
              '[IntroImageService] selected (excluding previous): $selected');
          return selected;
        }
      }

      final selected = urls[Random().nextInt(urls.length)];
      debugPrint('[IntroImageService] selected: $selected');
      return selected;
    } catch (e) {
      // 타임아웃 또는 네트워크 오류 발생 시 fallback을 위해 null 반환
      debugPrint('[IntroImageService] fetch failed: $e');
      return null;
    }
  }

  Future<List<String>> _loadIntroImageValues() async {
    final docTargets = const [
      ('config', 'intro_manifest'),
      ('app_config', 'intro_manifest'),
    ];

    for (final target in docTargets) {
      try {
        final doc = await _firestore
            .collection(target.$1)
            .doc(target.$2)
            .get(const GetOptions(source: Source.serverAndCache))
            .timeout(const Duration(seconds: 3));

        if (!doc.exists) continue;
        final data = doc.data();
        if (data == null) continue;

        final active = data['active'];
        if (active is bool && !active) continue;

        final parsed = _extractImageValues(data);
        if (parsed.isNotEmpty) {
          debugPrint(
            '[IntroImageService] manifest found at ${target.$1}/${target.$2}, count=${parsed.length}',
          );
          return parsed;
        }
      } catch (e) {
        debugPrint(
          '[IntroImageService] manifest read failed at ${target.$1}/${target.$2}: $e',
        );
      }
    }

    return const [];
  }

  List<String> _extractImageValues(Map<String, dynamic> data) {
    final rawImages = data['images'] ?? data['items'];
    if (rawImages is! List) return const [];

    final candidates = <String>[];
    for (final item in rawImages) {
      if (item is String && item.trim().isNotEmpty) {
        candidates.add(item.trim());
        continue;
      }

      if (item is Map) {
        final value = item['url'] ??
            item['downloadUrl'] ??
            item['download_url'] ??
            item['imageUrl'] ??
            item['image_url'] ??
            item['path'] ??
            item['storagePath'] ??
            item['storage_path'];

        if (value is String && value.trim().isNotEmpty) {
          candidates.add(value.trim());
        }
      }
    }

    return candidates.toSet().toList();
  }

  Future<List<String>> _resolveToDownloadUrls(List<String> imageValues) async {
    final results = <String>[];

    for (final value in imageValues) {
      if (value.startsWith('http://') || value.startsWith('https://')) {
        results.add(value);
        continue;
      }

      try {
        final ref = value.startsWith('gs://')
            ? _storage.refFromURL(value)
            : _storage.ref(value.startsWith('/') ? value.substring(1) : value);

        final url =
            await ref.getDownloadURL().timeout(const Duration(seconds: 3));
        results.add(url);
      } catch (_) {
        // skip invalid/unreachable path values
      }
    }

    return results.toSet().toList();
  }
}
