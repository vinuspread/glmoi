import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/ads/ads_controller.dart';
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
  _AdminBackgroundImage? _selectedBackground;
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

    // 배경 미선택 시 랜덤 자동 선택
    String? imageUrl = _selectedBackground?.backgroundUrl;
    if (imageUrl == null) {
      final images = ref.read(_adminBackgroundImagesProvider).valueOrNull ?? [];
      if (images.isNotEmpty) {
        final picked = images[Random().nextInt(images.length)];
        imageUrl = picked.backgroundUrl;
      }
    }

    setState(() => _saving = true);
    try {
      await ref.read(_quotesRepoProvider).createMalmoiPost(
            content: content,
            imageUrl: imageUrl,
            category: cat,
            malmoiLength: _selectedLength,
          );

      try {
        if (mounted) {
          await ref.read(adsControllerProvider).onPostCreated(context);
        } else {
          await ref.read(adsControllerProvider).onPostCreated(null);
        }
      } catch (adError) {
        debugPrint('[MalmoiWrite] onPostCreated ad trigger failed: $adError');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('글이 등록되었습니다.')),
      );
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    } catch (e) {
      if (!mounted) return;

      String msg = '저장에 실패했습니다.';
      if (e is FirebaseFunctionsException) {
        switch (e.code) {
          case 'failed-precondition':
            msg = '사용할 수 없는 단어가 있습니다.';
            break;
          case 'invalid-argument':
            msg = e.message?.trim().isNotEmpty == true
                ? e.message!.trim()
                : '입력값을 확인해주세요.';
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
    // 랜덤 배경 자동선택을 위해 항상 미리 로드
    ref.watch(_adminBackgroundImagesProvider);

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isLoggedIn)
              Container(
                decoration: AppTheme.cardDecoration(elevated: true),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 28,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '글 작성은 로그인 후 이용 가능합니다.',
                        style: t.textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              const _SectionHeader(title: '글 옵션'),
              const SizedBox(height: 8),
              Container(
                decoration: AppTheme.cardDecoration(elevated: true),
                clipBehavior: Clip.antiAlias,
                child: (isContentFocused && !_optionsExpanded)
                    ? InkWell(
                        onTap: _saving
                            ? null
                            : () {
                                FocusScope.of(context).unfocus();
                                setState(() => _optionsExpanded = true);
                              },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.tune,
                                size: 24,
                                color: AppTheme.accent,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '옵션열기',
                                style: t.textTheme.bodyLarge?.copyWith(
                                  color: AppTheme.accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.expand_more,
                                size: 24,
                                color: AppTheme.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 카테고리 선택
                          ListTile(
                            leading: const Icon(Icons.category_outlined,
                                color: AppTheme.accent),
                            title: const Text('카테고리',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary)),
                            subtitle: Text(
                              effectiveCategory ?? '선택안함',
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary),
                            ),
                            trailing: const Icon(Icons.chevron_right,
                                color: AppTheme.textSecondary, size: 20),
                            onTap: _saving
                                ? null
                                : () => _showCategoryPicker(context,
                                    categories: categories,
                                    current: effectiveCategory),
                          ),
                          const Divider(height: 1, indent: 56),

                          // 글 종류 선택
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            child: Row(
                              children: [
                                const Icon(Icons.format_align_left,
                                    color: AppTheme.accent, size: 24),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Row(
                                    children: [
                                      _TypeChip(
                                        label: '짧은글',
                                        isSelected: _selectedLength ==
                                            MalmoiLength.short,
                                        onSelected: (_) => setState(() =>
                                            _selectedLength =
                                                MalmoiLength.short),
                                      ),
                                      const SizedBox(width: 8),
                                      _TypeChip(
                                        label: '긴글',
                                        isSelected: _selectedLength ==
                                            MalmoiLength.long,
                                        onSelected: (_) => setState(() =>
                                            _selectedLength =
                                                MalmoiLength.long),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, indent: 56),

                          // 배경 선택
                          ListTile(
                            leading: const Icon(Icons.image_outlined,
                                color: AppTheme.accent),
                            title: const Text('배경 이미지',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary)),
                            subtitle: Text(
                              _selectedBackground != null
                                  ? '이미지 선택됨'
                                  : '랜덤 자동선택',
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_selectedBackground != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      _selectedBackground!.thumbnailUrl,
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right,
                                    color: AppTheme.textSecondary, size: 20),
                              ],
                            ),
                            onTap: _saving
                                ? null
                                : () async {
                                    final selected = await _pickBackgroundImage(
                                      context,
                                      selected: _selectedBackground,
                                    );
                                    if (!mounted) return;
                                    if (selected == null) return;
                                    setState(() => _selectedBackground =
                                        selected.backgroundUrl.isEmpty
                                            ? null
                                            : selected);
                                  },
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 28),
              const _SectionHeader(title: '내용 입력'),
              const SizedBox(height: 8),
              Container(
                height: 320,
                decoration: AppTheme.cardDecoration(elevated: true),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _controller,
                  focusNode: _contentFocusNode,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  maxLines: null,
                  expands: true,
                  maxLength: 2000,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(
                    fontSize: 19,
                    height: 1.6,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w400,
                  ),
                  onTap: () {
                    if (_optionsExpanded) {
                      setState(() => _optionsExpanded = false);
                    }
                  },
                  decoration: const InputDecoration(
                    hintText: '마음을 울리는 따뜻한 글을 작성해주세요.',
                    hintStyle: TextStyle(
                      fontSize: 18,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            if (!isKeyboardOpen)
              SizedBox(
                height: 60,
                child: FilledButton(
                  onPressed: (_saving || uidAsync.isLoading) ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radius16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '소중한 글 등록하기',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
            // 하단 여유 공간
            SizedBox(height: isKeyboardOpen ? 16 : 60),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker(BuildContext context,
      {required List<String> categories, String? current}) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radius24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('카테고리 선택',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = cat == current;
                    return ListTile(
                      title: Text(cat,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? AppTheme.accent
                                : AppTheme.textPrimary,
                          )),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle,
                              color: AppTheme.accent)
                          : null,
                      onTap: () {
                        setState(() => _selectedCategory = cat);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// 배경 이미지 선택 bottom sheet.
  /// - null 반환: 사용자가 dismiss (변경 없음)
  /// - backgroundUrl이 빈 객체 반환: '선택 안함' 클릭 (배경 제거)
  /// - 정상 객체 반환: 이미지 선택
  Future<_AdminBackgroundImage?> _pickBackgroundImage(
    BuildContext context, {
    required _AdminBackgroundImage? selected,
  }) {
    return showModalBottomSheet<_AdminBackgroundImage>(
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
                      onPressed: () => Navigator.pop(
                        context,
                        const _AdminBackgroundImage(
                            thumbnailUrl: '', backgroundUrl: ''),
                      ),
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
                                  selected?.backgroundUrl == img.backgroundUrl;
                              return GestureDetector(
                                onTap: () => Navigator.pop(context, img),
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

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppTheme.textSecondary,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      showCheckmark: false,
      labelStyle: TextStyle(
        fontSize: 15,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : AppTheme.textSecondary,
      ),
      selectedColor: AppTheme.accent,
      backgroundColor: AppTheme.surfaceAlt,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
