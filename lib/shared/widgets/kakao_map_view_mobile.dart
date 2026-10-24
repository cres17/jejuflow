import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    _loadMap();
  }

  @override
  void didUpdateWidget(covariant KakaoMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lat != widget.lat ||
        oldWidget.lng != widget.lng ||
        oldWidget.name != widget.name ||
        oldWidget.nameKo != widget.nameKo ||
        oldWidget.showRoute != widget.showRoute) {
      _loadMap();
    }
  }

  void _loadMap() {
    final key = ApiKeys.kakaoMap.trim();
    if (key.isEmpty || !(Platform.isAndroid || Platform.isIOS)) return;

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.surfaceLow)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (_) {},
          // 지도 페이지 밖으로 이동하지 못하게 막는다. 다른 페이지가 이 WebView의 위치 권한을 쓰지 못하도록 하기 위함
          onNavigationRequest: (request) =>
              _isAllowedNavigation(request.url, request.isMainFrame)
                  ? NavigationDecision.navigate
                  : NavigationDecision.prevent,
        ),
      );

    if (controller.platform is AndroidWebViewController) {
      final androidController = controller.platform as AndroidWebViewController;
      androidController.setGeolocationEnabled(true);
      androidController.setGeolocationPermissionsPromptCallbacks(
        // 앱이 직접 띄운 지도 페이지(http://localhost)에만 위치를 허용한다
        onShowPrompt: (params) async => GeolocationPermissionsResponse(
          allow: _isMapOrigin(params.origin),
          retain: false,
        ),
      );
    }

    controller.loadHtmlString(
      _html(
        appKey: key,
        lat: widget.lat,
        lng: widget.lng,
        name: widget.name,
        nameKo: widget.nameKo,
        showRoute: widget.showRoute,
      ),
      baseUrl: 'http://localhost',
    );

    setState(() => _controller = controller);
  }

  @override
  Widget build(BuildContext context) {
    final key = ApiKeys.kakaoMap.trim();
    if (key.isEmpty || _controller == null || !(Platform.isAndroid || Platform.isIOS)) {
      return KakaoFallbackLocationCard(
        height: widget.height,
        name: widget.name,
        lat: widget.lat,
        lng: widget.lng,
        showRoute: widget.showRoute,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: widget.height,
        child: WebViewWidget(controller: _controller!),
      ),
    );
  }
}

const _mapOrigin = 'http://localhost';

bool _isMapOrigin(String origin) {
  final uri = Uri.tryParse(origin);
  return uri != null && uri.scheme == 'http' && uri.host == 'localhost' && !uri.hasPort;
}

bool _isAllowedNavigation(String url, bool isMainFrame) {
  if (url == 'about:blank' || url.startsWith('$_mapOrigin/') || url == _mapOrigin) {
    return true;
  }
  if (isMainFrame) return false;
  // 지도 SDK가 여는 하위 프레임은 Kakao 도메인만 허용한다
  final host = Uri.tryParse(url)?.host ?? '';
  return url.startsWith('https://') &&
      (host == 'kakao.com' || host.endsWith('.kakao.com') ||
          host.endsWith('.daumcdn.net') || host.endsWith('.kakaocdn.net'));
}

String _html({
  required String appKey,
  required double lat,
  required double lng,
  required String name,
  required String nameKo,
  required bool showRoute,
}) {
  // <script> 안에 넣는 JSON이므로 '</script>'로 태그가 끊기지 않게 '<'를 이스케이프한다
  final options = jsonEncode({
    'appKey': appKey,
    'lat': lat,
    'lng': lng,
    'name': name,
    'nameKo': nameKo,
    'showRoute': showRoute,
    'level': showRoute ? 7 : 6,
  }).replaceAll('<', r'\u003c');

  return '''
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
  <style>
    html, body, #map { margin: 0; width: 100%; height: 100%; overflow: hidden; background: #f0f0ec; }
    .status {
      height: 100%;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 18px;
      box-sizing: border-box;
      text-align: center;
      color: #37503d;
      font: 700 14px system-ui, -apple-system, BlinkMacSystemFont, sans-serif;
    }
  </style>
</head>
<body>
  <div id="map"><div class="status">Loading Kakao Map...</div></div>
  <script>
    const options = $options;
    const container = document.getElementById('map');

    function setStatus(message) {
      container.innerHTML = '<div class="status"></div>';
      container.firstChild.textContent = message;
    }

    function render(maps) {
      container.innerHTML = '';
      const center = new maps.LatLng(Number(options.lat), Number(options.lng));
      const map = new maps.Map(container, {
        center: center,
        level: Number(options.level || 6)
      });

      const destinationMarker = new maps.Marker({ position: center });
      destinationMarker.setMap(map);

      const label = String(options.nameKo || options.name || 'Destination')
        .replace(/[&<>"']/g, (ch) => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch]));
      const info = new maps.InfoWindow({
        content: '<div style="padding:8px 12px;font-size:13px;font-weight:700;color:#263229;white-space:nowrap;">' + label + '</div>'
      });
      info.open(map, destinationMarker);

      if (navigator.geolocation && options.showRoute) {
        navigator.geolocation.getCurrentPosition(
          (position) => {
            const start = new maps.LatLng(position.coords.latitude, position.coords.longitude);
            const startMarker = new maps.Marker({ position: start });
            startMarker.setMap(map);
            const bounds = new maps.LatLngBounds();
            bounds.extend(start);
            bounds.extend(center);
            map.setBounds(bounds, 32, 32, 32, 32);
            new maps.Polyline({
              map: map,
              path: [start, center],
              strokeWeight: 5,
              strokeColor: '#37503d',
              strokeOpacity: 0.82,
              strokeStyle: 'solid'
            });
          },
          () => map.setCenter(center),
          { enableHighAccuracy: true, timeout: 6500, maximumAge: 60000 }
        );
      } else {
        map.setCenter(center);
      }
    }

    const script = document.createElement('script');
    script.src = 'https://dapi.kakao.com/v2/maps/sdk.js?autoload=false&libraries=services&appkey=' +
      encodeURIComponent(options.appKey);
    script.onload = () => {
      if (!window.kakao || !window.kakao.maps) {
        setStatus('Kakao SDK loaded, but maps object is unavailable.');
        return;
      }
      window.kakao.maps.load(() => render(window.kakao.maps));
    };
    script.onerror = () => setStatus('Kakao Maps SDK could not load. Check the JavaScript key and Web platform domain.');
    document.head.appendChild(script);
  </script>
</body>
</html>
''';
}
