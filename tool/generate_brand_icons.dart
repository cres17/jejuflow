import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

/// Run from the repository root: dart run tool/generate_brand_icons.dart
void main() {
  const sourcePath = 'assets/branding/jejuflow-logo.png';
  final source = img.decodePng(File(sourcePath).readAsBytesSync());
  if (source == null || source.width != source.height) {
    throw StateError('Expected a square PNG at $sourcePath');
  }

  void writeIcon(String path, int size,
      {double fraction = 1, bool opaque = false}) {
    final canvas =
        img.Image(width: size, height: size, numChannels: opaque ? 3 : 4);
    img.fill(canvas,
        color: opaque
            ? img.ColorRgba8(255, 248, 236, 255)
            : img.ColorRgba8(0, 0, 0, 0));
    final artwork = img.copyResize(
      source,
      width: (size * fraction).round(),
      interpolation: img.Interpolation.average,
    );
    img.compositeImage(canvas, artwork, center: true);
    final file = File(path)..createSync(recursive: true);
    file.writeAsBytesSync(img.encodePng(canvas));
    stdout.writeln('$path ($size x $size)');
  }

  const android = 'android/app/src/main/res';
  for (final (density, size, foregroundSize) in [
    ('mdpi', 48, 108),
    ('hdpi', 72, 162),
    ('xhdpi', 96, 216),
    ('xxhdpi', 144, 324),
    ('xxxhdpi', 192, 432),
  ]) {
    writeIcon('$android/mipmap-$density/ic_launcher.png', size, fraction: 0.9);
    // The drawing stays inside Android's 66/108 adaptive-icon safe zone.
    writeIcon(
      '$android/mipmap-$density/ic_launcher_foreground.png',
      foregroundSize,
      fraction: 0.62,
    );
  }

  writeIcon('web/favicon.png', 64);
  writeIcon('web/icons/apple-touch-icon.png', 180);
  for (final size in [192, 512]) {
    writeIcon('web/icons/Icon-$size.png', size);
    // Leave generous space for circular and rounded home-screen masks.
    writeIcon('web/icons/Icon-maskable-$size.png', size,
        fraction: 0.7, opaque: true);
  }

  const catalog = 'ios/Runner/Assets.xcassets';
  final images = <Map<String, String>>[];
  for (final (idiom, points, scale) in [
    ('iphone', 20.0, 2),
    ('iphone', 20.0, 3),
    ('iphone', 29.0, 2),
    ('iphone', 29.0, 3),
    ('iphone', 40.0, 2),
    ('iphone', 40.0, 3),
    ('iphone', 60.0, 2),
    ('iphone', 60.0, 3),
    ('ipad', 20.0, 1),
    ('ipad', 20.0, 2),
    ('ipad', 29.0, 1),
    ('ipad', 29.0, 2),
    ('ipad', 40.0, 1),
    ('ipad', 40.0, 2),
    ('ipad', 76.0, 1),
    ('ipad', 76.0, 2),
    ('ipad', 83.5, 2),
    ('ios-marketing', 1024.0, 1),
  ]) {
    final pointsLabel = points == points.roundToDouble()
        ? points.toInt().toString()
        : points.toString();
    final filename = 'Icon-$pointsLabel@${scale}x.png';
    writeIcon('$catalog/AppIcon.appiconset/$filename', (points * scale).round(),
        fraction: 0.9, opaque: true);
    images.add({
      'idiom': idiom,
      'size': '${pointsLabel}x$pointsLabel',
      'scale': '${scale}x',
      'filename': filename,
    });
  }
  const encoder = JsonEncoder.withIndent('  ');
  File('$catalog/AppIcon.appiconset/Contents.json').writeAsStringSync(
    '${encoder.convert({
          'images': images,
          'info': {'version': 1, 'author': 'xcode'},
        })}\n',
  );
  File('$catalog/Contents.json').writeAsStringSync(
    '${encoder.convert({
          'info': {'version': 1, 'author': 'xcode'},
        })}\n',
  );
}
