// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/api_keys.dart';
import '../../core/constants/colors.dart';
import 'kakao_map_view_stub.dart' show KakaoFallbackLocationCard;

class KakaoMapView extends StatefulWidget {
  const KakaoMapView({
    super.key,
    required this.lat,
    required this.lng,
    required this.name,
    required this.nameKo,
    this.height = 280,
    this.showRoute = false,
  });

  final double lat;
  final double lng;
  final String name;
  final String nameKo;
  final double height;
  final bool showRoute;

  @override
  State<KakaoMapView> createState() => _KakaoMapViewState();
}

class _KakaoMapViewState extends State<KakaoMapView> {
  static int _nextId = 0;

  late final String _viewType;
  late final String _elementId;
  bool _registered = false;

  @override
  void initState() {
    super.initState();
    _viewType = 'jejuflow-kakao-map-${_nextId++}';
    _elementId = '$_viewType-container';
    _registerView();
    WidgetsBinding.instance.addPostFrameCallback((_) => _renderMap());
  }

  @override
  void didUpdateWidget(covariant KakaoMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lat != widget.lat ||
        oldWidget.lng != widget.lng ||
        oldWidget.name != widget.name ||
        oldWidget.nameKo != widget.nameKo ||
        oldWidget.showRoute != widget.showRoute) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _renderMap());
    }
  }

  void _registerView() {
    if (_registered) return;
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      return html.DivElement()
        ..id = _elementId
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = '0'
        ..style.overflow = 'hidden'
        ..style.borderRadius = '28px'
        ..style.backgroundColor = '#f0f0ec';
    });
    _registered = true;
  }

  void _renderMap() {
    final bridge = js.context['JejuFlowKakaoMap'];
    final key = ApiKeys.kakaoMap.trim();
    if (bridge == null || key.isEmpty) return;
    bridge.callMethod('render', [
      _elementId,
      js.JsObject.jsify({
        'appKey': key,
        'lat': widget.lat,
        'lng': widget.lng,
        'name': widget.name,
        'nameKo': widget.nameKo,
        'showRoute': widget.showRoute,
        'level': widget.showRoute ? 7 : 6,
      }),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (ApiKeys.kakaoMap.trim().isEmpty) {
      return Stack(
        children: [
          KakaoFallbackLocationCard(
            height: widget.height,
            name: widget.name,
            lat: widget.lat,
            lng: widget.lng,
            showRoute: widget.showRoute,
          ),
          const Positioned(
            left: 14,
            right: 14,
            top: 14,
            child: _MapNotice(
              text: 'Kakao map key is missing',
            ),
          ),
        ],
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: widget.height,
        child: HtmlElementView(viewType: _viewType),
      ),
    );
  }
}

class _MapNotice extends StatelessWidget {
  const _MapNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.accent,
        ),
      ),
    );
  }
}
