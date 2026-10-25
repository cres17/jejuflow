import 'package:flutter_test/flutter_test.dart';
import 'package:jejuflow/core/constants/api_keys.dart';

void main() {
  const mode = String.fromEnvironment('KEY_TEST_MODE');
  test('API configuration works without runtime dotenv', () {
    if (mode == 'new') {
      expect(ApiKeys.weather, 'key%2Bvalue%3D');
      expect(ApiKeys.weatherServiceKey, 'key+value=');
      expect(ApiKeys.tago, 'new-tago');
      expect(ApiKeys.tour, 'new-tour');
      expect(ApiKeys.kakaoMap, 'new-kakao');
    } else if (mode == 'legacy') {
      expect(ApiKeys.weather, 'old-weather');
      expect(ApiKeys.tago, 'old-tago');
      expect(ApiKeys.tour, 'old-tour');
      expect(ApiKeys.kakaoMap, 'old-kakao');
    } else {
      expect(ApiKeys.weather, isEmpty);
      expect(ApiKeys.tago, isEmpty);
      expect(ApiKeys.tour, isEmpty);
      expect(ApiKeys.kakaoMap, isEmpty);
    }
  });
}
