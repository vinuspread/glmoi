import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Wrap text by word boundaries (spaces) instead of breaking inside words.
///
/// Notes:
/// - If the input has no whitespace (single "word"), we fall back to [Text]
///   so the layout can still wrap for long strings.
class WordWrapText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final StrutStyle? strutStyle;

  const WordWrapText({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.start,
    this.strutStyle,
  });

  WrapAlignment _wrapAlignment(TextAlign align) {
    switch (align) {
      case TextAlign.center:
        return WrapAlignment.center;
      case TextAlign.right:
      case TextAlign.end:
        return WrapAlignment.end;
      case TextAlign.left:
      case TextAlign.start:
      case TextAlign.justify:
      default:
        return WrapAlignment.start;
    }
  }

  CrossAxisAlignment _crossAxisAlignment(TextAlign align) {
    switch (align) {
      case TextAlign.center:
        return CrossAxisAlignment.center;
      case TextAlign.right:
      case TextAlign.end:
        return CrossAxisAlignment.end;
      case TextAlign.left:
      case TextAlign.start:
      case TextAlign.justify:
        return CrossAxisAlignment.start;
    }
  }

  Widget _buildWrappedSingleLine(String line) {
    final raw = line;
    if (raw.isEmpty) {
      return const SizedBox.shrink();
    }

    // Collapse whitespace for predictable wrapping, but keep this line's
    // boundaries intact (newlines are handled at a higher level).
    final normalized = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (!normalized.contains(' ')) {
      return Text(
        raw,
        style: style,
        textAlign: textAlign,
        strutStyle: strutStyle,
      );
    }

    final words = normalized.split(' ');
    return Wrap(
      alignment: _wrapAlignment(textAlign),
      children: [
        for (var i = 0; i < words.length; i++)
          Text(
            i == words.length - 1 ? words[i] : '${words[i]} ',
            style: style,
            strutStyle: strutStyle,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final raw = text;
    if (raw.isEmpty) {
      return const SizedBox.shrink();
    }

    // Preserve explicit newlines entered by the user while still wrapping by
    // word boundaries within each line.
    final lines = raw.split('\n');
    if (lines.length == 1) {
      return _buildWrappedSingleLine(raw);
    }

    final effectiveHeight = (style?.height ?? 1.2);
    final effectiveFontSize = (style?.fontSize ?? 14.0);
    final lineGap = math.max(0.0, (effectiveHeight - 1.0) * effectiveFontSize);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: _crossAxisAlignment(textAlign),
      children: [
        for (var i = 0; i < lines.length; i++) ...[
          if (lines[i].isEmpty)
            SizedBox(height: effectiveFontSize * effectiveHeight)
          else
            _buildWrappedSingleLine(lines[i]),
          if (i != lines.length - 1 && lines[i].isNotEmpty)
            SizedBox(height: lineGap),
        ],
      ],
    );
  }
}
