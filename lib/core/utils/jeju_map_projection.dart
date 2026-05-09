import 'dart:math' as math;

import 'package:flutter/widgets.dart';

const _westLng = 126.12;
const _eastLng = 126.98;
const _northLat = 33.62;
const _southLat = 33.20;

const _mapLeft = 0.15;
const _mapRight = 0.86;
const _mapTop = 0.29;
const _mapBottom = 0.71;

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
