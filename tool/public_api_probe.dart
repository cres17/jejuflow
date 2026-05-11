// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

const _weatherKey = 'EXPO_PUBLIC_WEATHER_API_KEY';
const _tagoKey = 'EXPO_PUBLIC_TAGO_API_KEY';
const _tourKey = 'EXPO_PUBLIC_TOUR_API_KEY';

Future<void> main(List<String> args) async {
  final env = _readDotEnv(File('.env'));
  final probe = PublicApiProbe(env);

  print('Public API probe started');
  print('Key status:');
  print('  weather: ${_mask(env[_weatherKey])}');
  print('  tago   : ${_mask(env[_tagoKey])}');
  print('  tour   : ${_mask(env[_tourKey])}');
  print('');

  final results = <ProbeResult>[
    await probe.weather(),
    await probe.busArrival(),
    await probe.busRoute(),
    await probe.tourAreaCode(),
    await probe.tourAreaBasedList(),
    await probe.tourDetailImage(),
  ];

  print('');
  print('Summary');
  for (final result in results) {
    final mark = result.ok ? 'OK ' : 'ERR';
    print('[$mark] ${result.name}: ${result.message}');
  }

  final failed = results.where((result) => !result.ok).length;
  if (failed > 0) {
    print('');
    print(
        '$failed probe(s) failed. Check the messages above before wiring the same call into the app.');
    exitCode = 1;
  }
}

class PublicApiProbe {
  PublicApiProbe(this._env);

  final Map<String, String> _env;

  Future<ProbeResult> weather() async {
    final base = _latestKmaBaseTime(DateTime.now());
    return _get(
      name: 'Weather getVilageFcst',
      host: 'apis.data.go.kr',
      path: '/1360000/VilageFcstInfoService_2.0/getVilageFcst',
      keyName: _weatherKey,
      query: {
        'pageNo': '1',
        'numOfRows': '10',
        'dataType': 'JSON',
        'base_date': base.date,
        'base_time': base.time,
        'nx': '53',
        'ny': '38',
      },
      itemPath: 'response.body.items.item',
    );
  }

  Future<ProbeResult> busArrival() {
    return _get(
      name: 'TAGO bus arrival',
      host: 'apis.data.go.kr',
      path: '/1613000/ArvlInfoInqireService/getSttnAcctoArvlPrearngeInfoList',
      keyName: _tagoKey,
      query: {
        'pageNo': '1',
        'numOfRows': '10',
        '_type': 'json',
        'cityCode': '39',
        'nodeId': 'JEB406000816',
      },
      itemPath: 'response.body.items.item',
    );
  }

  Future<ProbeResult> busRoute() {
    return _get(
      name: 'TAGO bus route',
      host: 'apis.data.go.kr',
      path: '/1613000/BusRouteInfoInqireService/getRouteInfoIem',
      keyName: _tagoKey,
      query: {
        'pageNo': '1',
        'numOfRows': '10',
        '_type': 'json',
        'cityCode': '39',
        'routeId': 'JEB405320112',
      },
      itemPath: 'response.body.items.item',
    );
  }

  Future<ProbeResult> tourAreaCode() {
    return _get(
      name: 'Tour KorService2 areaCode2',
      host: 'apis.data.go.kr',
      path: '/B551011/KorService2/areaCode2',
      keyName: _tourKey,
      query: {
        'MobileOS': 'ETC',
        'MobileApp': 'JejuFlow',
        'numOfRows': '10',
        'pageNo': '1',
        '_type': 'json',
      },
      itemPath: 'response.body.items.item',
    );
  }

  Future<ProbeResult> tourDetailImage() {
    return _get(
      name: 'Tour KorService2 detailImage2',
      host: 'apis.data.go.kr',
      path: '/B551011/KorService2/detailImage2',
      keyName: _tourKey,
      query: {
        'MobileOS': 'ETC',
        'MobileApp': 'JejuFlow',
        'contentId': '126440',
        'imageYN': 'Y',
        'numOfRows': '5',
        'pageNo': '1',
        '_type': 'json',
      },
      itemPath: 'response.body.items.item',
    );
  }

  Future<ProbeResult> tourAreaBasedList() {
    return _get(
      name: 'Tour KorService2 areaBasedList2',
      host: 'apis.data.go.kr',
      path: '/B551011/KorService2/areaBasedList2',
      keyName: _tourKey,
      query: {
        'MobileOS': 'ETC',
        'MobileApp': 'JejuFlow',
        'areaCode': '39',
        'contentTypeId': '12',
        'arrange': 'C',
        'numOfRows': '10',
        'pageNo': '1',
        '_type': 'json',
      },
      itemPath: 'response.body.items.item',
    );
  }

  Future<ProbeResult> _get({
    required String name,
    required String host,
    required String path,
    required String keyName,
    required Map<String, String> query,
    required String itemPath,
  }) async {
    final key = _normalizedServiceKey(_env[keyName]);
    if (key == null || key.isEmpty) {
      return ProbeResult(name, false, 'missing $keyName in .env');
    }

    final uri = Uri.https(host, path, {
      'serviceKey': key,
      ...query,
    });

    try {
      final response = await _getUri(uri);
      final decoded = _decodeIfNeeded(response.body);
      final header = _valueAt(decoded, 'response.header');
      final code = header is Map ? header['resultCode']?.toString() : null;
      final message = header is Map ? header['resultMsg']?.toString() : null;
      final items = _valueAt(decoded, itemPath);
      final count = _countItems(items);

      if (response.statusCode != HttpStatus.ok) {
        return ProbeResult(
            name, false, 'HTTP ${response.statusCode}, ${_preview(decoded)}');
      }
      if (code != null && code != '00' && code != '0000') {
        return ProbeResult(
            name, false, 'API resultCode=$code, resultMsg=$message');
      }

      return ProbeResult(
          name, true, 'HTTP 200, resultCode=${code ?? 'n/a'}, items=$count');
    } on SocketException catch (error) {
      return ProbeResult(name, false, 'network error: ${error.message}');
    } on TimeoutException catch (error) {
      return ProbeResult(name, false, error.message ?? 'request timed out');
    } catch (error) {
      return ProbeResult(name, false, error.toString());
    }
  }
}

class _HttpResult {
  const _HttpResult(this.statusCode, this.body);

  final int statusCode;
  final String body;
}

Future<_HttpResult> _getUri(Uri uri) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final request =
        await client.getUrl(uri).timeout(const Duration(seconds: 10));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close().timeout(const Duration(seconds: 10));
    final body = await response.transform(utf8.decoder).join();
    return _HttpResult(response.statusCode, body);
  } finally {
    client.close(force: true);
  }
}

class ProbeResult {
  const ProbeResult(this.name, this.ok, this.message);

  final String name;
  final bool ok;
  final String message;
}

class _KmaBaseTime {
  const _KmaBaseTime(this.date, this.time);

  final String date;
  final String time;
}

_KmaBaseTime _latestKmaBaseTime(DateTime now) {
  final releaseHours = [2, 5, 8, 11, 14, 17, 20, 23];
  var baseDate = DateTime(now.year, now.month, now.day);
  var baseHour = releaseHours.last;

  for (final hour in releaseHours) {
    if (now.hour > hour || (now.hour == hour && now.minute >= 10)) {
      baseHour = hour;
    }
  }

  if (now.hour < 2 || (now.hour == 2 && now.minute < 10)) {
    baseDate = baseDate.subtract(const Duration(days: 1));
  }

  String two(int value) => value.toString().padLeft(2, '0');
  return _KmaBaseTime(
    '${baseDate.year}${two(baseDate.month)}${two(baseDate.day)}',
    '${two(baseHour)}00',
  );
}

Map<String, String> _readDotEnv(File file) {
  if (!file.existsSync()) return {};

  final result = <String, String>{};
  for (final rawLine in file.readAsLinesSync()) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) continue;

    final equals = line.indexOf('=');
    if (equals <= 0) continue;

    final name = line.substring(0, equals).trim();
    var value = line.substring(equals + 1).trim();
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.substring(1, value.length - 1);
    }
    result[name] = value;
  }
  return result;
}

String? _normalizedServiceKey(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (!trimmed.contains('%')) return trimmed;

  try {
    return Uri.decodeComponent(trimmed);
  } catch (_) {
    return trimmed;
  }
}

dynamic _decodeIfNeeded(dynamic data) {
  if (data is String) {
    try {
      return jsonDecode(data);
    } catch (_) {
      return data;
    }
  }
  return data;
}

dynamic _valueAt(dynamic data, String dottedPath) {
  dynamic current = data;
  for (final part in dottedPath.split('.')) {
    if (current is! Map) return null;
    current = current[part];
  }
  return current;
}

int _countItems(dynamic items) {
  if (items == null || items == '') return 0;
  if (items is List) return items.length;
  if (items is Map) return 1;
  return 0;
}

String _preview(dynamic value) {
  final text = value.toString().replaceAll(RegExp(r'\s+'), ' ');
  return text.length <= 160 ? text : '${text.substring(0, 160)}...';
}

String _mask(String? value) {
  if (value == null || value.isEmpty) return 'missing';
  final normalized = _normalizedServiceKey(value) ?? value;
  final encodedHint =
      value.contains('%') ? ', encoded in .env' : ', decoded in .env';
  if (normalized.length <= 8) {
    return 'present (${normalized.length} chars$encodedHint)';
  }
  return '${normalized.substring(0, 4)}...${normalized.substring(normalized.length - 4)} (${normalized.length} chars$encodedHint)';
}
