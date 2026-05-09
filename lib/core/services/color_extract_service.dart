import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'cache_service.dart';

class ExtractedTheme {
  final Color bgColor;
  final Color accentColor;
  final String source; // 'extracted' | 'pantone'
  const ExtractedTheme({required this.bgColor, required this.accentColor, required this.source});
}

class ColorExtractService {
  static Future<ExtractedTheme?> extract(String spotId, String imageUrl) async {
    final key = 'theme:$spotId';
    final cached = await CacheService.get<ExtractedTheme>(key, CacheService.month, _fromJson);
    if (cached != null) return cached;

    try {
      final provider = NetworkImage(imageUrl);
      final palette  = await PaletteGenerator.fromImageProvider(
        provider,
        maximumColorCount: 8,
      );

      // Prefer vibrant, then dominant
      final dominant = palette.vibrantColor?.color ?? palette.dominantColor?.color;
      if (dominant == null) return null;

      final accent = _ensureReadable(dominant);
      final bg     = _darken(accent, 0.12);

      final theme = ExtractedTheme(bgColor: bg, accentColor: accent, source: 'extracted');
      await CacheService.set(key, _toJson(theme));
      return theme;
    } catch (_) {
      return null;
    }
  }

  /// Lighten color until contrast ratio ≥ 3.5 against dark background
  static Color _ensureReadable(Color color) {
    double contrast = _contrastRatio(color, const Color(0xFF111110));
    var c = color;
    var attempts = 0;
    while (contrast < 3.5 && attempts < 10) {
      c = Color.lerp(c, Colors.white, 0.15)!;
      contrast = _contrastRatio(c, const Color(0xFF111110));
      attempts++;
    }
    return c;
  }

  static Color _darken(Color color, double amount) => Color.fromARGB(
    (color.a * 255).round(),
    (color.r * 255 * amount).round(),
    (color.g * 255 * amount).round(),
    (color.b * 255 * amount).round(),
  );

  static double _contrastRatio(Color fg, Color bg) {
    double lum(Color c) {
      final r = c.r;
      final g = c.g;
      final b = c.b;
      double lin(double v) => v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) * ((v + 0.055) / 1.055);
      return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b);
    }
    final l1 = lum(fg), l2 = lum(bg);
    return (l1 > l2 ? (l1 + 0.05) / (l2 + 0.05) : (l2 + 0.05) / (l1 + 0.05));
  }

  static Map<String, dynamic> _toJson(ExtractedTheme t) => {
    'bgColor': t.bgColor.toARGB32(), 'accentColor': t.accentColor.toARGB32(), 'source': t.source,
  };
  static ExtractedTheme _fromJson(dynamic j) {
    final m = j as Map<String, dynamic>;
    return ExtractedTheme(bgColor: Color(m['bgColor']), accentColor: Color(m['accentColor']), source: m['source']);
  }
}
