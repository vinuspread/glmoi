import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/font_scale_provider.dart';

class ContentText extends ConsumerWidget {
  final String content;
  final TextAlign? textAlign;
  final double baseFontSize;
  final double? height;
  final FontWeight? fontWeight;
  final Color? color;

  const ContentText(
    this.content, {
    super.key,
    this.textAlign,
    this.baseFontSize = 24,
    this.height,
    this.fontWeight,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontScale = ref.watch(fontScaleProvider);

    return Text(
      content,
      textAlign: textAlign,
      style: TextStyle(
        color: color,
        fontSize: baseFontSize * fontScale.scale,
        height: height,
        fontWeight: fontWeight,
      ),
    );
  }
}
