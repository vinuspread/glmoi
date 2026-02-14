import 'package:flutter/material.dart';
import 'package:app_admin/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_admin/core/widgets/word_wrap_text.dart';

import '../../../../data/models/quote_model.dart';

class QuotePreviewDialog extends StatelessWidget {
  final QuoteModel quote;
  final int defaultFontSize;
  final double defaultLineHeight;
  final double defaultDimStrength;

  const QuotePreviewDialog({
    super.key,
    required this.quote,
    required this.defaultFontSize,
    required this.defaultLineHeight,
    required this.defaultDimStrength,
  });

  TextStyle _applyContentFont(QuoteModel quote, TextStyle base) {
    if (quote.font == ContentFont.serif) {
      return GoogleFonts.gowunBatang(textStyle: base);
    }
    return base.copyWith(fontFamily: 'Pretendard');
  }

  FontWeight _contentFontWeight(QuoteModel quote) {
    if (quote.fontThickness == ContentFontThickness.regular) {
      return FontWeight.w400;
    }
    return quote.font == ContentFont.serif ? FontWeight.w700 : FontWeight.w500;
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = defaultFontSize.toDouble();
    final lineHeight = defaultLineHeight;
    final dimStrength = defaultDimStrength;

    final isLongForm =
        quote.type == ContentType.thought ||
        (quote.type == ContentType.malmoi &&
            quote.malmoiLength == MalmoiLength.long);

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (quote.imageUrl != null)
                  Image.network(
                    quote.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: AppTheme.background),
                  )
                else
                  Container(color: AppTheme.background),
                if (quote.imageUrl != null)
                  Container(color: Colors.black.withOpacity(dimStrength)),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final align = isLongForm
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center;
                    final textAlign = isLongForm
                        ? TextAlign.left
                        : TextAlign.center;

                    final contentWidget = Column(
                      mainAxisAlignment: isLongForm
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      crossAxisAlignment: align,
                      children: [
                        WordWrapText(
                          text: quote.content,
                          style: _applyContentFont(
                            quote,
                            TextStyle(
                              fontSize: fontSize,
                              height: lineHeight,
                              color: quote.imageUrl != null
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                              fontWeight: _contentFontWeight(quote),
                            ),
                          ),
                          textAlign: textAlign,
                        ),
                        if (quote.author.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Text(
                            '- ${quote.author} -',
                            style: _applyContentFont(
                              quote,
                              TextStyle(
                                fontSize: fontSize * 0.7,
                                color: quote.imageUrl != null
                                    ? Colors.white.withOpacity(0.8)
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

                    return Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        primary: true,
                        padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                        child: contentWidget,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
