import 'dart:math' as math;

import 'package:flutter/widgets.dart';

// Main Jeju island bounds. The map artwork also includes nearby islets, but
// app spots are placed on the main island, so using the main-island envelope
// keeps pins from drifting toward Udo/Gapado.
const _westLng = 126.15;
const _eastLng = 126.98;
const _northLat = 33.57;
const _southLat = 33.20;

const _mapLeft = 0.16;
const _mapRight = 0.84;
const _mapTop = 0.29;
const _mapBottom = 0.70;

Offset projectJejuLatLng(double lat, double lng, Size size) {
  final xRatio =
      ((lng - _westLng) / (_eastLng - _westLng)).clamp(0.0, 1.0).toDouble();
  final yRatio =
      ((_northLat - lat) / (_northLat - _southLat)).clamp(0.0, 1.0).toDouble();

  final x = _lerp(_mapLeft, _mapRight, xRatio);
  final y = _lerp(_mapTop, _mapBottom, yRatio);
  return Offset(size.width * x, size.height * y);
}

double _lerp(double a, double b, double t) => a + (b - a) * math.min(1, t);
