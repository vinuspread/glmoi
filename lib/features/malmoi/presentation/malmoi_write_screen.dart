import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/config/app_config_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/domain/login_redirect.dart';
import '../../quotes/data/quotes_repository.dart';
import '../../quotes/domain/quote.dart';

final _quotesRepoProvider = Provider((ref) => QuotesRepository());

class _AdminBackgroundImage {
  final String thumbnailUrl;
  final String backgroundUrl;

  const _AdminBackgroundImage({
    required this.thumbnailUrl,
    required this.backgroundUrl,
  });

  factory _AdminBackgroundImage.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? const {};
    final originalUrl = (data['original_url'] as String?) ?? '';
    final thumbnailUrl = (data['thumbnail_url'] as String?) ?? '';
    final webpUrl = (data['webp_url'] as String?) ?? '';

    final bg = webpUrl.trim().isNotEmpty ? webpUrl.trim() : originalUrl.trim();
    final thumb = thumbnailUrl.trim().isNotEmpty
        ? thumbnailUrl.trim()
        : originalUrl.trim();
    return _AdminBackgroundImage(thumbnailUrl: thumb, backgroundUrl: bg);
  }
}

final _adminBackgroundImagesProvider = StreamProvider.autoDispose(
  (ref) {
    final db = FirebaseFirestore.instance;
    final query = db
        .collection('image_assets')
        .where('app_id', isEqualTo: 'maumsori')
        .where('is_active', isEqualTo: true)
        .orderBy('uploaded_at', descending: true)
        .limit(60);
    return query
        .snapshots()
        .map((s) => s.docs.map(_AdminBackgroundImage.fromFirestore).toList());
  },
);

class MalmoiWriteScreen extends ConsumerStatefulWidget {
  const MalmoiWriteScreen({super.key});

  @override
  ConsumerState<MalmoiWriteScreen> createState() => _MalmoiWriteScreenState();
}

class _MalmoiWriteScreenState extends ConsumerState<MalmoiWriteScreen> {
  final _controller = TextEditingController();
  final _contentFocusNode = FocusNode();
  var _saving = false;
  String? _selectedBackgroundUrl;
  String? _selectedCategory;
  var _selectedLength = MalmoiLength.short;
  var _optionsExpanded = true;

  @override
  void initState() {
    super.initState();
    _contentFocusNode.addListener(() {
      if (!mounted) return;
      if (_contentFocusNode.hasFocus) {
        if (_optionsExpanded) setState(() => _optionsExpanded = false);
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Check auth state directly from FirebaseAuth instead of relying on StreamProvider
    // to avoid timing issues with state synchronization
    final currentUser = FirebaseAuth.instance.currentUser;
    debugPrint(
        '[MalmoiWrite] _submit called, currentUser: ${currentUser?.uid ?? "NULL"}');
    if (currentUser == null) {
      if (!mounted) return;
      debugPrint('[MalmoiWrite] currentUser is null, redirecting to login');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      context.push('/login', extra: const LoginRedirect.pop());
      return;
    }
    debugPrint(
        '[MalmoiWrite] currentUser OK: uid=${currentUser.uid}, email=${currentUser.email}');

    final cat = (_selectedCategory ??
            ref.read(appConfigProvider).valueOrNull?.categories.firstOrNull ??
            '')
        .trim();
    if (cat.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카테고리를 선택하세요.')),
      );
      return;
    }

    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() => _saving = true);
    try {
      await ref.read(_quotesRepoProvider).createMalmoiPost(
            content: content,
            imageUrl: _selectedBackgroundUrl,
            category: cat,
            malmoiLength: _selectedLength,
          );
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;

      String msg = '저장에 실패했습니다.';
      if (e is FirebaseFunctionsException) {
        switch (e.code) {
          case 'failed-precondition':
            msg = '사용할 수 없는 단어가 있습니다.';
            break;
          case 'unauthenticated':
            // Cloud Run IAM 권한 문제일 수 있음
            msg = '서버 권한 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.';
            debugPrint(
                '[MalmoiWrite] unauthenticated error - possible Cloud Run IAM issue: ${e.message}');
            break;
          case 'permission-denied':
            msg = '권한이 없습니다.';
            break;
          case 'unavailable':
            msg = '서버에 연결할 수 없습니다.\n네트워크를 확인해주세요.';
            break;
          default:
            msg = '저장에 실패했습니다. (${e.code})';
            debugPrint('[MalmoiWrite] Error: ${e.code} - ${e.message}');
        }
      } else {
        debugPrint('[MalmoiWrite] Unexpected error: $e');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );

      if (e is FirebaseFunctionsException && e.code == 'unauthenticated') {
        context.push('/login', extra: const LoginRedirect.pop());
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final uidAsync = ref.watch(authUidProvider);
    final isLoggedIn = uidAsync.valueOrNull != null;
    final appConfigAsync = ref.watch(appConfigProvider);

    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final isContentFocused = _contentFocusNode.hasFocus;

    final categories =
        appConfigAsync.valueOrNull?.categories ?? const <String>[];
    final effectiveCategory =
        (_selectedCategory != null && categories.contains(_selectedCategory))
            ? _selectedCategory
            : (categories.isNotEmpty ? categories.first : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('글모이 작성'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('등록'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isLoggedIn)
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppTheme.radius16),
                  border: Border.all(color: AppTheme.border),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '글 작성은 로그인 후 이용 가능합니다.',
                        style: t.textTheme.bodyMedium
                            ?.copyWith(color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppTheme.radius16),
                  border: Border.all(color: AppTheme.border),
                ),
                padding: const EdgeInsets.all(12),
                child: (isContentFocused && !_optionsExpanded)
                    ? InkWell(
                        borderRadius: BorderRadius.circular(AppTheme.radius16),
                        onTap: _saving
                            ? null
                            : () {
                                FocusScope.of(context).unfocus();
                                setState(() => _optionsExpanded = true);
                              },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 4,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.tune,
                                size: 18,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '옵션열기',
                                style: t.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.expand_more,
                                color: AppTheme.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.category_outlined,
                                size: 18,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: appConfigAsync.when(
                                  data: (cfg) {
                                    final items = cfg.categories;
                                    if (items.isEmpty) {
                                      return Text(
                                        '-',
                                        style: t.textTheme.bodyMedium?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                      );
                                    }

                                    final value = (effectiveCategory != null &&
                                            items.contains(effectiveCategory))
                                        ? effectiveCategory
                                        : items.first;

                                    return DropdownButtonFormField<String>(
                                      initialValue: value,
                                      items: items
                                          .map((c) => DropdownMenuItem(
                                                value: c,
                                                child: Text(c),
                                              ))
                                          .toList(),
                                      onChanged: _saving
                                          ? null
                                          : (v) => setState(() {
                                                _selectedCategory = v;
                                              }),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        labelText: '카테고리',
                                      ),
                                    );
                                  },
                                  loading: () => const LinearProgressIndicator(
                                    minHeight: 2,
                                  ),
                                  error: (e, _) => Text(
                                    '-',
                                    style: t.textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.format_align_left,
                                size: 18,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('짧은글'),
                                selected: _selectedLength == MalmoiLength.short,
                                onSelected: _saving
                                    ? null
                                    : (_) => setState(
                                          () => _selectedLength =
                                              MalmoiLength.short,
                                        ),
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('긴글'),
                                selected: _selectedLength == MalmoiLength.long,
                                onSelected: _saving
                                    ? null
                                    : (_) => setState(
                                          () => _selectedLength =
                                              MalmoiLength.long,
                                        ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.image_outlined,
                                size: 18,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: _saving
                                    ? null
                                    : () async {
                                        final selected =
                                            await _pickBackgroundImage(
                                          context,
                                          selectedUrl: _selectedBackgroundUrl,
                                        );
                                        if (!mounted) return;
                                        if (selected == null) return;
                                        setState(() => _selectedBackgroundUrl =
                                            selected.isEmpty ? null : selected);
                                      },
                                child: const Text('배경선택'),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _contentFocusNode,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                maxLines: null,
                expands: true,
                maxLength: 2000,
                textAlignVertical: TextAlignVertical.top,
                scrollPadding: const EdgeInsets.only(bottom: 160),
                onTap: () {
                  if (_optionsExpanded) {
                    setState(() => _optionsExpanded = false);
                  }
                },
                decoration: const InputDecoration(
                  hintText: '내용을 입력하세요 (최대 2,000자)',
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (!isKeyboardOpen)
              FilledButton(
                onPressed: (_saving || uidAsync.isLoading) ? null : _submit,
                child: const Text('등록하기'),
              ),
          ],
        ),
      ),
    );
  }

  Future<String?> _pickBackgroundImage(
    BuildContext context, {
    required String? selectedUrl,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      '배경 이미지 선택',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context, ''),
                      child: const Text('선택 안함'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final imagesAsync =
                          ref.watch(_adminBackgroundImagesProvider);
                      return imagesAsync.when(
                        data: (images) {
                          if (images.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text('사용 가능한 배경 이미지가 없습니다.'),
                              ),
                            );
                          }

                          const crossAxisCount = 3;
                          return GridView.builder(
                            shrinkWrap: true,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 9 / 16,
                            ),
                            itemCount: images.length,
                            itemBuilder: (context, i) {
                              final img = images[i];
                              final isSelected =
                                  selectedUrl == img.backgroundUrl;
                              return GestureDetector(
                                onTap: () => Navigator.pop(
                                  context,
                                  img.backgroundUrl,
                                ),
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radius16),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl: img.thumbnailUrl,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) =>
                                            const ColoredBox(
                                          color: AppTheme.surfaceAlt,
                                        ),
                                      ),
                                      if (isSelected)
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: AppTheme.accent,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      if (isSelected)
                                        const Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 36),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, _) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text('이미지 로딩 실패: $e'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
