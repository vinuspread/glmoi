import 'package:flutter/material.dart';
import 'package:app_admin/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_admin/core/widgets/word_wrap_text.dart';

import '../../../../data/models/quote_model.dart';

class ComposerPreviewPanel extends StatelessWidget {
  final double previewFontSize;
  final double previewLineHeight;
  final double previewDimStrength;
  final ContentType selectedType;
  final MalmoiLength selectedMalmoiLength;
  final String? selectedImageUrl;
  final String contentText;
  final String authorText;
  final ContentFont selectedFont;
  final ContentFontThickness selectedFontThickness;

  const ComposerPreviewPanel({
    super.key,
    required this.previewFontSize,
    required this.previewLineHeight,
    required this.previewDimStrength,
    required this.selectedType,
    required this.selectedMalmoiLength,
    required this.selectedImageUrl,
    required this.contentText,
    required this.authorText,
    required this.selectedFont,
    required this.selectedFontThickness,
  });

  TextStyle _applyContentFont(TextStyle base) {
    if (selectedFont == ContentFont.serif) {
      // Use an explicit serif face so the preview change is obvious.
      return GoogleFonts.gowunBatang(textStyle: base);
    }
    return base.copyWith(fontFamily: 'Pretendard');
  }

  FontWeight _contentFontWeight() {
    if (selectedFontThickness == ContentFontThickness.regular) {
      return FontWeight.w400;
    }
    // Keep a clearly visible weight delta in preview.
    return FontWeight.w700;
  }

  String _labelForType(ContentType type) {
    switch (type) {
      case ContentType.quote:
        return '한줄명언';
      case ContentType.thought:
        return '좋은생각';
      case ContentType.malmoi:
        return '글모이';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: Colors.white),
            child: Row(
              children: [
                const Icon(Icons.phone_android, color: AppTheme.primaryPurple),
                const SizedBox(width: 12),
                const Text(
                  '실시간 프리뷰',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${previewFontSize.toInt()}pt / ${previewLineHeight}x',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: _MobilePreviewContainer(
                previewFontSize: previewFontSize,
                previewLineHeight: previewLineHeight,
                previewDimStrength: previewDimStrength,
                selectedType: selectedType,
                selectedMalmoiLength: selectedMalmoiLength,
                selectedImageUrl: selectedImageUrl,
                contentText: contentText,
                authorText: authorText,
                applyContentFont: _applyContentFont,
                contentFontWeight: _contentFontWeight(),
                labelForType: _labelForType,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobilePreviewContainer extends StatefulWidget {
  final double previewFontSize;
  final double previewLineHeight;
  final double previewDimStrength;
  final ContentType selectedType;
  final MalmoiLength selectedMalmoiLength;
  final String? selectedImageUrl;
  final String contentText;
  final String authorText;
  final TextStyle Function(TextStyle base) applyContentFont;
  final FontWeight contentFontWeight;
  final String Function(ContentType type) labelForType;

  const _MobilePreviewContainer({
    required this.previewFontSize,
    required this.previewLineHeight,
    required this.previewDimStrength,
    required this.selectedType,
    required this.selectedMalmoiLength,
    required this.selectedImageUrl,
    required this.contentText,
    required this.authorText,
    required this.applyContentFont,
    required this.contentFontWeight,
    required this.labelForType,
  });

  @override
  State<_MobilePreviewContainer> createState() =>
      _MobilePreviewContainerState();
}

class _MobilePreviewContainerState extends State<_MobilePreviewContainer> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewFontSize = widget.previewFontSize;
    final previewLineHeight = widget.previewLineHeight;
    final previewDimStrength = widget.previewDimStrength;
    final selectedType = widget.selectedType;
    final selectedMalmoiLength = widget.selectedMalmoiLength;
    final selectedImageUrl = widget.selectedImageUrl;
    final contentText = widget.contentText;
    final authorText = widget.authorText;
    final applyContentFont = widget.applyContentFont;
    final contentFontWeight = widget.contentFontWeight;
    final labelForType = widget.labelForType;

    final isLongForm =
        selectedType == ContentType.thought ||
        (selectedType == ContentType.malmoi &&
            selectedMalmoiLength == MalmoiLength.long);

    return Container(
      width: 375,
      height: 667,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. 이미지 (바닥)
            if (selectedImageUrl != null)
              Image.network(selectedImageUrl, fit: BoxFit.cover),
            // 2. 딤 레이어 (중간)
            if (selectedImageUrl != null)
              Container(color: Colors.black.withOpacity(previewDimStrength)),
            // 3. 텍스트 (상단)
            LayoutBuilder(
              builder: (context, constraints) {
                final align = isLongForm
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center;
                final textAlign = isLongForm
                    ? TextAlign.left
                    : TextAlign.center;

                final baseStyle = TextStyle(
                  fontSize: previewFontSize,
                  height: previewLineHeight,
                  color: selectedImageUrl != null
                      ? Colors.white
                      : AppTheme.textPrimary,
                  fontWeight: contentFontWeight,
                );

                final contentWidget = Column(
                  mainAxisAlignment: isLongForm
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  crossAxisAlignment: align,
                  children: [
                    if (contentText.isNotEmpty)
                      WordWrapText(
                        text: contentText,
                        style: applyContentFont(baseStyle),
                        textAlign: textAlign,
                      )
                    else
                      Text(
                        '여기에 작성한 글이\n실시간으로 표시됩니다',
                        style: applyContentFont(
                          TextStyle(
                            fontSize: previewFontSize,
                            height: previewLineHeight,
                            color: AppTheme.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    if (authorText.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        '- $authorText -',
                        style: applyContentFont(
                          TextStyle(
                            fontSize: previewFontSize * 0.7,
                            color: selectedImageUrl != null
                                ? Colors.white.withValues(alpha: 0.8)
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                );

                if (!isLongForm) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 64,
                      ),
                      child: contentWidget,
                    ),
                  );
                }

                // Long form: top-aligned + scrollable.
                return Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                    child: contentWidget,
                  ),
                );
              },
            ),
            // 상단 인디케이터 (Positioned)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  labelForType(selectedType),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
