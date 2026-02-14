import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_admin/core/theme/app_theme.dart';
import '../providers/quote_provider.dart';
import '../providers/image_provider.dart';
import '../providers/config_provider.dart';
import '../providers/bad_words_provider.dart';
import '../../data/repositories/quote_repository.dart';
import '../widgets/maumsori_sidebar.dart';
import '../../data/models/quote_model.dart';
import '../../domain/bad_words/bad_words_matcher.dart';
import 'content_composer/widgets/composer_input_form.dart';
import 'content_composer/widgets/composer_preview_panel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_admin/core/widgets/admin_background.dart';
import 'package:google_fonts/google_fonts.dart';

class ContentComposerScreen extends ConsumerStatefulWidget {
  final String? quoteId;
  final String? initialTypeRaw;

  const ContentComposerScreen({super.key, this.quoteId, this.initialTypeRaw});

  @override
  ConsumerState<ContentComposerScreen> createState() =>
      _ContentComposerScreenState();
}

class _ContentComposerScreenState extends ConsumerState<ContentComposerScreen> {
  final _contentController = TextEditingController();
  final _authorController = TextEditingController();
  ContentType _selectedType = ContentType.quote;
  String? _selectedCategory;
  String? _selectedImageUrl;
  ContentFont _selectedFont = ContentFont.gothic;
  ContentFontThickness _selectedFontThickness = ContentFontThickness.regular;
  MalmoiLength _selectedMalmoiLength = MalmoiLength.short;

  bool _isEditMode = false;
  bool _isEditLoading = false;
  QuoteModel? _editingQuote;

  ContentType _typeFromRaw(String? raw) {
    switch (raw) {
      case 'thought':
        return ContentType.thought;
      case 'malmoi':
        return ContentType.malmoi;
      case 'quote':
      default:
        return ContentType.quote;
    }
  }

  // Composer defaults (loaded from config/app_config)
  bool _defaultsInitialized = false;
  double _previewFontSize = 24.0;
  double _previewLineHeight = 1.6;
  double _previewDimStrength = 0.4;

  ContentFont _fontFromConfig(String raw) {
    return raw == 'serif' ? ContentFont.serif : ContentFont.gothic;
  }

  void _initializeFromConfigDefaults() {
    final config = ref.read(appConfigProvider).valueOrNull;
    if (config == null || _defaultsInitialized) {
      return;
    }

    setState(() {
      _previewFontSize = config.composerFontSize.toDouble();
      _previewLineHeight = config.composerLineHeight;
      _previewDimStrength = config.composerDimStrength;

      // In edit mode, keep the quote's stored font choice.
      if (!_isEditMode) {
        _selectedFont = _fontFromConfig(config.composerFontStyle);
      }

      _selectedCategory ??= (config.categories.isNotEmpty
          ? config.categories.first
          : '일반');
      _defaultsInitialized = true;
    });
  }

  @override
  void initState() {
    super.initState();

    // Preload serif font used in preview to reduce first-toggle latency.
    Future.microtask(() {
      GoogleFonts.gowunBatang();
    });

    Future.microtask(() async {
      // Ensure defaults exist so realtime filtering has data.
      await ref.read(badWordsControllerProvider).ensureInitialized();
    });

    _isEditMode = widget.quoteId != null && widget.quoteId!.isNotEmpty;
    if (!_isEditMode) {
      _selectedType = _typeFromRaw(widget.initialTypeRaw);
      _selectedMalmoiLength = MalmoiLength.short;
      return;
    }

    _isEditLoading = true;
    Future.microtask(() async {
      try {
        final quote = await ref
            .read(quoteRepositoryProvider)
            .getQuoteById(widget.quoteId!);
        if (!mounted) return;
        if (quote == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('수정할 글을 찾을 수 없습니다.')));
          setState(() => _isEditLoading = false);
          return;
        }

        setState(() {
          _editingQuote = quote;
          _selectedType = quote.type;
          _selectedMalmoiLength = quote.malmoiLength;
          _selectedFont = quote.font;
          _selectedFontThickness = quote.fontThickness;
          _selectedCategory = quote.category.isEmpty ? null : quote.category;
          _selectedImageUrl = quote.imageUrl;
          _contentController.text = quote.content;
          _authorController.text = quote.author;
          _isEditLoading = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _isEditLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('불러오기 실패: $e')));
      }
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appConfigAsync = ref.watch(appConfigProvider);
    final imagesAsync = ref.watch(imageListProvider);
    final badWordsAsync = ref.watch(badWordsConfigProvider);

    final badWordsConfig = badWordsAsync.valueOrNull;
    final badWordsMatches = badWordsConfig == null
        ? const <BadWordsMatch>[]
        : const BadWordsMatcher().findMatches(
            _contentController.text,
            badWordsConfig,
          );
    final badWordsWarning = badWordsMatches.isEmpty
        ? null
        : '금지어가 포함되어 저장할 수 없습니다: ${badWordsMatches.first.display}';

    final categoryItems = appConfigAsync.when(
      data: (config) => config.categories
          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
          .toList(),
      loading: () => const <DropdownMenuItem<String>>[],
      error: (_, __) => const <DropdownMenuItem<String>>[],
    );

    if (!_defaultsInitialized && appConfigAsync.hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _defaultsInitialized) {
          return;
        }
        _initializeFromConfigDefaults();
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_isEditMode ? '글 수정' : '글 작성 (Composer)'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.border, height: 1),
        ),
      ),
      body: AdminBackground(
        child: Row(
          children: [
            // Sidebar
            const MaumSoriSidebar(activeRoute: '/maumsori/compose'),
            const VerticalDivider(width: 1, color: AppTheme.border),

            // Left: Input Form
            Expanded(
              flex: 5,
              child: _isEditLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ComposerInputForm(
                      selectedType: _selectedType,
                      onTypeSelected: (type) {
                        final config = ref.read(appConfigProvider).value;
                        setState(() {
                          _selectedType = type;
                          if (type != ContentType.malmoi) {
                            _selectedMalmoiLength = MalmoiLength.short;
                          }
                          if (type == ContentType.quote) {
                            _selectedCategory = null;
                          } else {
                            // 좋은생각/글모이는 항상 기본 카테고리 설정
                            _selectedCategory =
                                (config != null && config.categories.isNotEmpty)
                                ? config.categories.first
                                : '일반';
                          }
                        });
                      },
                      selectedMalmoiLength: _selectedMalmoiLength,
                      onMalmoiLengthSelected: (v) =>
                          setState(() => _selectedMalmoiLength = v),
                      selectedFont: _selectedFont,
                      onFontSelected: (font) =>
                          setState(() => _selectedFont = font),
                      selectedFontThickness: _selectedFontThickness,
                      onFontThicknessSelected: (thickness) =>
                          setState(() => _selectedFontThickness = thickness),
                      selectedCategory: _selectedCategory,
                      categoryItems: categoryItems,
                      onCategoryChanged: (value) =>
                          setState(() => _selectedCategory = value),
                      contentController: _contentController,
                      authorController: _authorController,
                      onTextChanged: () => setState(() {}),
                      badWordsWarning: badWordsWarning,
                      imagesAsync: imagesAsync,
                      selectedImageUrl: _selectedImageUrl,
                      onImageSelected: (url) =>
                          setState(() => _selectedImageUrl = url),
                      onReset: () {
                        final config = appConfigAsync.value;
                        _contentController.clear();
                        _authorController.clear();
                        setState(() {
                          _selectedImageUrl = null;
                          _selectedCategory =
                              (config != null && config.categories.isNotEmpty)
                              ? config.categories.first
                              : '일반';
                        });
                      },
                      onSave: _saveQuote,
                      canSave:
                          _contentController.text.isNotEmpty &&
                          badWordsMatches.isEmpty,
                    ),
            ),

            const VerticalDivider(width: 1, color: AppTheme.border),

            // Right: Real-Time Preview
            Expanded(
              flex: 4,
              child: ComposerPreviewPanel(
                previewFontSize: _previewFontSize,
                previewLineHeight: _previewLineHeight,
                previewDimStrength: _previewDimStrength,
                selectedType: _selectedType,
                selectedMalmoiLength: _selectedMalmoiLength,
                selectedImageUrl: _selectedImageUrl,
                contentText: _contentController.text,
                authorText: _authorController.text,
                selectedFont: _selectedFont,
                selectedFontThickness: _selectedFontThickness,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveQuote() async {
    final badWordsConfig = ref.read(badWordsConfigProvider).valueOrNull;
    if (badWordsConfig != null) {
      final matches = const BadWordsMatcher().findMatches(
        _contentController.text,
        badWordsConfig,
      );
      if (matches.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('금지어가 포함되어 저장할 수 없습니다: ${matches.first.display}'),
            ),
          );
        }
        return;
      }
    }

    try {
      if (_isEditMode && _editingQuote != null) {
        final updated = _editingQuote!.copyWith(
          type: _selectedType,
          malmoiLength: _selectedType == ContentType.malmoi
              ? _selectedMalmoiLength
              : MalmoiLength.short,
          content: _contentController.text,
          author: _authorController.text,
          category: _selectedType == ContentType.quote
              ? ''
              : (_selectedCategory ?? '일반'),
          imageUrl: _selectedImageUrl,
          font: _selectedFont,
          fontThickness: _selectedFontThickness,
        );
        await ref.read(quoteControllerProvider).updateQuote(updated);
      } else {
        await ref
            .read(quoteControllerProvider)
            .addQuote(
              type: _selectedType,
              content: _contentController.text,
              author: _authorController.text,
              category: _selectedType == ContentType.quote
                  ? ''
                  : (_selectedCategory ?? '일반'),
              imageUrl: _selectedImageUrl,
              font: _selectedFont,
              fontThickness: _selectedFontThickness,
              malmoiLength: _selectedMalmoiLength,
              isUserPost: false,
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('글이 성공적으로 저장되었습니다!')));
        if (_isEditMode) {
          return;
        }

        // Reset form (create mode)
        final config = ref.read(appConfigProvider).value;
        _contentController.clear();
        _authorController.clear();
        setState(() {
          _selectedImageUrl = null;
          // 한줄명언이면 null, 아니면 기본 카테고리 설정
          if (_selectedType == ContentType.quote) {
            _selectedCategory = null;
          } else {
            _selectedCategory = (config != null && config.categories.isNotEmpty)
                ? config.categories.first
                : '일반';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        if (e is DuplicateOfficialContentException) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.message)));
          return;
        }

        final s = e.toString();
        final looksLikePermissionDenied =
            (e is FirebaseException && e.code == 'permission-denied') ||
            s.contains('permission-denied') ||
            s.contains('Missing or insufficient permissions');
        if (looksLikePermissionDenied) {
          final userEmail =
              FirebaseAuth.instance.currentUser?.email ?? '(unknown)';
          final projectId = Firebase.app().options.projectId;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '저장 실패: 권한이 없습니다.\n'
                'email: $userEmail\n'
                'project: $projectId',
              ),
              duration: const Duration(seconds: 6),
            ),
          );
          return;
        }

        if (s.contains('Dart exception thrown from converted Future')) {
          final projectId = Firebase.app().options.projectId;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '저장 실패: 웹(Firebase) 내부 오류가 발생했습니다.\n'
                'project: $projectId\n'
                'Firestore Rules에 quotes/dedup_quotes 권한이 있는지 확인해주세요.\n'
                '$s',
              ),
              duration: const Duration(seconds: 8),
            ),
          );
          return;
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
      }
    }
  }
}
