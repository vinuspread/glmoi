import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Font scale levels
enum FontScaleLevel {
  small(0.85, '작게'),
  normal(1.0, '보통'),
  large(1.15, '크게'),
  extraLarge(1.3, '가장 크게');

  final double scale;
  final String label;

  const FontScaleLevel(this.scale, this.label);
}

/// Provider for font scale settings
final fontScaleProvider =
    StateNotifierProvider<FontScaleNotifier, FontScaleLevel>((ref) {
  return FontScaleNotifier();
});

class FontScaleNotifier extends StateNotifier<FontScaleLevel> {
  static const String _key = 'font_scale';

  FontScaleNotifier() : super(FontScaleLevel.normal) {
    _loadScale();
  }

  Future<void> _loadScale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scaleValue = prefs.getDouble(_key);

      if (scaleValue != null) {
        for (final level in FontScaleLevel.values) {
          if (level.scale == scaleValue) {
            state = level;
            break;
          }
        }
      }
    } catch (e) {
      // Ignore and use default
    }
  }

  Future<void> setScale(FontScaleLevel level) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_key, level.scale);
      state = level;
    } catch (e) {
      // Ignore save failure
    }
  }
}
