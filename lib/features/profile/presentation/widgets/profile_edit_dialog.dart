import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/auth/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/backend/functions_client.dart';

class ProfileEditDialog extends ConsumerStatefulWidget {
  const ProfileEditDialog({super.key});

  @override
  ConsumerState<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends ConsumerState<ProfileEditDialog> {
  final _picker = ImagePicker();
  final _nicknameController = TextEditingController();
  Uint8List? _pendingBytes;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _nicknameController.text =
        FirebaseAuth.instance.currentUser?.displayName ?? '';
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

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

    final newNickname = _nicknameController.text.trim();
    if (newNickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임을 입력해주세요.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      String? photoURL = FirebaseAuth.instance.currentUser?.photoURL;

      if (_pendingBytes != null) {
        await ref
            .read(authProvider.notifier)
            .updateProfileImage(_pendingBytes!);
        photoURL = FirebaseAuth.instance.currentUser?.photoURL;
      }

      await FirebaseAuth.instance.currentUser?.updateDisplayName(newNickname);

      final callable =
          FunctionsClient.instance.httpsCallable('syncProfileToQuotes');
      final result = await callable.call({
        'displayName': newNickname,
        'photoURL': photoURL,
      });

      if (!mounted) return;

      final data = result.data as Map?;
      final message = data?['message'] as String? ?? '프로필이 업데이트되었습니다.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('프로필 저장 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPhotoUrl =
        (FirebaseAuth.instance.currentUser?.photoURL ?? '').trim();
    final hasPendingImage = _pendingBytes != null && _pendingBytes!.isNotEmpty;

    ImageProvider? provider;
    if (hasPendingImage) {
      provider = MemoryImage(_pendingBytes!);
    } else if (currentPhotoUrl.isNotEmpty) {
      provider = NetworkImage(currentPhotoUrl);
    }

    return AlertDialog(
      title: const Text('프로필 수정'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: AppTheme.surfaceAlt,
              backgroundImage: provider,
              child: provider == null
                  ? const Icon(Icons.person,
                      color: AppTheme.textSecondary, size: 48)
                  : null,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: _saving ? null : _pickFromGallery,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.photo_library_outlined),
                    SizedBox(width: 8),
                    Padding(
                      padding: EdgeInsets.only(left: 1),
                      child: Text('이미지 변경'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nicknameController,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: '닉네임',
                border: OutlineInputBorder(),
              ),
              maxLength: 20,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
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
