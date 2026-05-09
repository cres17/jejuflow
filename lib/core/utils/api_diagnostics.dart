import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_keys.dart';
import 'time_utils.dart';

class ApiDiagnostics {
  static final _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 5)));

  static Future<void> runTests() async {
    debugPrint('=== API Key Diagnostics Start ===');

    final kmaTime = getKMABaseDateTime();
    final date = kmaTime['date']!;
    final time = kmaTime['time']!;

    // 1. Weather API Test
    await _testApi(
      name: 'Weather (기상청)',
      baseUrl: ApiKeys.weatherBase,
      path: '/getVilageFcst',
      key: ApiKeys.weather,
      params: 'pageNo=1&numOfRows=1&dataType=JSON&base_date=$date&base_time=$time&nx=53&ny=38',
    );

    // 2. TAGO Bus API Test
    await _testApi(
      name: 'Transit (TAGO)',
      baseUrl: ApiKeys.tagoBase,
      path: '/ArvlInfoInqireService/getSttnAcctoArvlPrearngeInfoList',
      key: ApiKeys.tago,
      params: 'pageNo=1&numOfRows=1&_type=json&cityCode=39&nodeId=JEB406000816',
    );

    // 3. Tour API Test (v1 -> v1.0 or parameters check)
    // 관광공사는 KorService1 대신 EngService1 등 다른 엔드포인트로도 테스트
    await _testApi(
      name: 'Tour (관광공사)',
      baseUrl: ApiKeys.tourBase,
      path: '/areaBasedList1',
      key: ApiKeys.tour,
      params: 'numOfRows=1&pageNo=1&MobileOS=ETC&MobileApp=AppTest&_type=json&areaCode=39',
    );

    debugPrint('=== API Key Diagnostics End ===');
  }

  static Future<void> _testApi({
    required String name,
    required String baseUrl,
    required String path,
    required String key,
    required String params,
  }) async {
    try {
      final url = '$baseUrl$path?serviceKey=$key&$params';
      final uri = Uri.parse(url);
      final response = await _dio.getUri(uri);

      final header = response.data?['response']?['header'];
      final resultCode = header?['resultCode'];
      final resultMsg = header?['resultMsg'];

      if (resultCode == '00') {
        debugPrint('✅ $name: SUCCESS');
      } else {
        debugPrint('❌ $name: FAILED ($resultCode - $resultMsg)');
      }
    } catch (e) {
      debugPrint('⚠️ $name: ERROR ($e)');
    }
  }
}
