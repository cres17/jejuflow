import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/constants/api_keys.dart';

class ApiLab {
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    // [지침 반영] 헤더에 컨텐츠 타입 명시
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    validateStatus: (status) => true,
  ));

  static Future<void> testEverything() async {
    await dotenv.load(fileName: '.env', isOptional: true);
    debugPrint('\n🧪 --- [9차] 정밀 실험: URL 키 + 파라미터 배열 바디 ---');

    // 실험 1: 관광공사 - URL에 키 포함 + 바디는 파라미터를 배열로 전달
    await _testFinalPattern(
        'Tour (관광공사)',
        '${ApiKeys.tourBase}/KorService1/areaCode1?serviceKey=${ApiKeys.tour}&_type=json',
        {
          'MobileOS': ['AND'], // 값을 배열 형태로 전달
          'MobileApp': ['JejuFlow'],
          'numOfRows': ['1'],
          'pageNo': ['1']
        });

    // 실험 2: 관광공사 - 다른 배열 형태 (바디 전체가 단일 배열 안의 객체)
    await _testFinalPattern(
        'Tour (관광공사-형태B)',
        '${ApiKeys.tourBase}/KorService1/areaCode1?serviceKey=${ApiKeys.tour}&_type=json',
        [
          {'MobileOS': 'AND', 'MobileApp': 'JejuFlow', 'numOfRows': '1'}
        ]);

    debugPrint('🧪 --- [9차] 실험 종료 ---\n');
  }

  static Future<void> _testFinalPattern(
      String name, String url, dynamic body) async {
    debugPrint('[$name] 호출중 (Body: $body)...');
    try {
      final res = await _dio.post(url, data: body);

      debugPrint('   상태코드: ${res.statusCode}');
      final dataStr = res.data.toString();
      debugPrint(
          '   응답본문: ${dataStr.substring(0, dataStr.length > 200 ? 200 : dataStr.length)}');

      if (dataStr.contains('resultCode') &&
          (dataStr.contains('00') || dataStr.contains('0000'))) {
        debugPrint('   ✅ $name 성공!!! 드디어 정답을 찾았습니다.');
      } else {
        debugPrint('   ❌ $name 여전히 실패');
      }
    } catch (e) {
      debugPrint('   ⚠️ $name 에러: $e');
    }
  }
}
