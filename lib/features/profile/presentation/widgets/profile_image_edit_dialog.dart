import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/auth/auth_service.dart';
import '../../../../core/backend/functions_client.dart';
import '../../../../core/theme/app_theme.dart';

class ProfileImageEditDialog extends ConsumerStatefulWidget {
  const ProfileImageEditDialog({super.key});

  @override
  ConsumerState<ProfileImageEditDialog> createState() =>
      _ProfileImageEditDialogState();
}

class _ProfileImageEditDialogState
    extends ConsumerState<ProfileImageEditDialog> {
  final _picker = ImagePicker();
  Uint8List? _pendingBytes;
  var _saving = false;

  Future<void> _pickFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 720,
      imageQuality: 82,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _pendingBytes = bytes);
  }

  Future<void> _save() async {
    if (_saving) return;
    final bytes = _pendingBytes;
    if (bytes == null || bytes.isEmpty) return;

    setState(() => _saving = true);
    try {
      await ref.read(authProvider.notifier).updateProfileImage(bytes);

      // 프로필 이미지 변경 후 글모이 작성자 정보 자동 동기화
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final callable =
            FunctionsClient.instance.httpsCallable('syncProfileToQuotes');
        await callable.call({
          'displayName': user.displayName ?? '',
          'photoURL': user.photoURL,
        });
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('프로필 이미지 저장 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPhotoUrl =
        (FirebaseAuth.instance.currentUser?.photoURL ?? '').trim();
    final hasPending = _pendingBytes != null && _pendingBytes!.isNotEmpty;

    ImageProvider? provider;
    if (hasPending) {
      provider = MemoryImage(_pendingBytes!);
    } else if (currentPhotoUrl.isNotEmpty) {
      provider = NetworkImage(currentPhotoUrl);
    }

    return AlertDialog(
      title: const Text('프로필 이미지'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppTheme.surfaceAlt,
            backgroundImage: provider,
            child: provider == null
                ? const Icon(Icons.person, color: AppTheme.textSecondary)
                : null,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _saving ? null : _pickFromGallery,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('갤러리에서 선택'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currentPhotoUrl.isNotEmpty
                ? '저장하지 않으면 현재 프로필 이미지가 그대로 사용됩니다.'
                : '프로필 이미지는 나중에 언제든지 등록할 수 있어요.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('닫기'),
        ),
        FilledButton(
          onPressed: (_saving || !hasPending) ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('저장'),
        ),
      ],
    );
  }
}
