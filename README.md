<p align="center">
  <img src="assets/branding/jejuflow-logo.png" alt="JEJUFLOW 로고" width="140">
</p>

<h1 align="center">JEJUFLOW</h1>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=flat&amp;logoColor=white&amp;logo=flutter" alt="Flutter" height="20">
  <img src="https://img.shields.io/badge/Riverpod-0553B1?style=flat&amp;logoColor=white" alt="Riverpod" height="20">
  <img src="https://img.shields.io/badge/Dio-0175C2?style=flat&amp;logoColor=white" alt="Dio" height="20">
  <br>
  <img src="https://img.shields.io/badge/Hive-C27C0E?style=flat&amp;logoColor=white" alt="Hive" height="20">
  <img src="https://img.shields.io/badge/Kakao%20Maps-FFCD00?style=flat&amp;logoColor=black&amp;logo=kakao" alt="Kakao Maps" height="20">
  <img src="https://img.shields.io/badge/%EA%B8%B0%EC%83%81%EC%B2%AD%20API-2B6CB0?style=flat&amp;logoColor=white" alt="기상청 API" height="20">
  <br>
  <img src="https://img.shields.io/badge/TAGO-1F7A5C?style=flat&amp;logoColor=white" alt="TAGO" height="20">
  <img src="https://img.shields.io/badge/TourAPI-1F6F8B?style=flat&amp;logoColor=white" alt="TourAPI" height="20">
  <img src="https://img.shields.io/badge/Android-3DDC84?style=flat&amp;logoColor=black&amp;logo=android" alt="Android" height="20">
</p>

제주의 날씨와 현재 위치를 바탕으로 갈 곳을 고르고, 날짜별 여행 일정에 담는 Flutter 앱입니다. 관광지·음식점·카페를 탐색하면서 버스 도착 정보를 확인하고 카카오맵 길찾기로 이동할 수 있습니다. 한국어, 영어, 일본어, 중국어를 지원합니다.

## 화면

| Now | Move | Routes | Settings |
|:---:|:---:|:---:|:---:|
| <img src="docs/screenshots/home.png" alt="장소 추천" width="190"> | <img src="docs/screenshots/explore.png" alt="장소 탐색" width="190"> | <img src="docs/screenshots/itinerary.png" alt="여행 일정" width="190"> | <img src="docs/screenshots/settings.png" alt="설정" width="190"> |

API 키 없이 실행한 웹 빌드입니다. 날씨와 장소는 앱의 기본값이며, 일정에는 탐색 화면에서 선택한 세 장소를 담았습니다.

## 구조

![JEJUFLOW 구성](docs/assets/readme/architecture.svg)

화면은 Riverpod Provider를 구독하고, Service가 공공 API와 Hive 캐시를 다룹니다. 모바일은 공공 API에 직접 요청합니다. Web에서는 CORS 처리를 위해 `JEJUFLOW_API_PROXY`로 지정한 프록시를 사용합니다.

`lib/features/`에 네 탭의 화면이 있고, `lib/providers/app_providers.dart`에 상태와 비동기 조회를 모았습니다. 통신·캐시·알림은 `lib/core/services/`, 날씨·거리·시간 계산은 `lib/core/utils/`에 있습니다.

## 장소 추천

<p><img src="https://img.shields.io/badge/MAIN%20FEATURE-EA733B?style=flat-square" alt="MAIN 기능" height="20"></p>

앱을 열면 위치 권한과 좌표를 확인합니다. 위도가 33.38보다 낮으면 서귀포시, 그 외에는 제주시 권역을 사용합니다. 권한을 받지 못하거나 10초 안에 좌표가 오지 않으면 제주시에서 시작합니다.

기상청 단기예보의 강수 형태, 풍속, 하늘 상태로 추천 후보를 거릅니다.

| 예보 | 분류 | 추천 |
|---|---|---|
| 강수 있음 + 풍속 14m/s 이상 | `storm` | 실내 |
| 강수 있음 | `rain` | 실내 |
| 강수 없음 + 풍속 14m/s 이상 | `windy` | 실내 |
| 강수 없음 + 흐림 | `cloudy` | 야외 |
| 나머지 | `clear` | 야외 |

TourAPI 후보를 우선 사용하고 응답이 비어 있으면 해당 권역의 내장 장소로 채웁니다. 관광지는 야외, 음식점과 카페는 실내로 분류합니다. 이미 일정에 넣었거나 넘긴 장소는 빼고 최대 20장의 카드를 구성합니다.

카드를 위로 80px 이상 밀면 일정 추가 대화상자가 열립니다. 아래로 밀면 해당 장소를 넘깁니다. 기준에 못 미친 드래그는 원래 자리로 돌아갑니다.

## 조회와 캐시

<p><img src="https://img.shields.io/badge/SUB%20FEATURE-F4B395?style=flat-square" alt="SUB 기능" height="20"></p>

API를 호출하기 전에 Hive에서 유효한 캐시를 찾습니다. 새 응답에는 데이터와 저장 시각을 함께 기록합니다. 호출이 실패하면 만료 캐시를 사용하고, 그것도 없으면 내장값을 반환합니다. 기본 날씨인 맑음 22°C는 이 대체 경로의 값입니다.

| 데이터 | 캐시 유효 시간 |
|---|---:|
| 버스 도착 | 1분 |
| 날씨 | 10분 |
| 버스 노선 | 1일 |
| 장소 목록·상세 | 30일 |

버스 정보는 TAGO, 장소 정보는 TourAPI에서 가져옵니다. Tour DataLab은 관련 장소와 혼잡도 보조 지표에 사용합니다. 지도 표시는 Kakao Maps JS SDK를 쓰고, 길찾기는 카카오맵 앱 또는 웹으로 연결합니다.

## 일정과 알림

<p><img src="https://img.shields.io/badge/MAIN%20FEATURE-EA733B?style=flat-square" alt="MAIN 기능" height="20"></p>

일정은 Hive의 `routes` 박스에 저장합니다. 장소 간 이동 시간은 Haversine 거리와 평균 24km/h를 기준으로 계산한 뒤 8분을 더하며, 최소 12분으로 잡습니다. 체류 시간은 장소 태그에 따라 55~110분을 배정합니다. 실제 버스 배차나 도로 경로를 반영한 소요 시간은 아닙니다.

알림을 켜면 `Asia/Seoul` 기준으로 일정 출발 30분 전 알림을 예약합니다. 시간을 바꾸거나 일정을 삭제하면 기존 알림을 취소하고 다시 예약합니다.

## 기술별 역할

| 기술 | 용도 | 위치 |
|------|------|------|
| Flutter · Dart | Android와 Web을 한 코드로 빌드. 하단 탭은 `PageView`로 구성해 스와이프로 이동하고 `tabIndexProvider`와 동기화. 언어를 바꾸면 문구 · 글꼴 · TourAPI 요청 언어가 함께 바뀌고, 장소 사진에서 `palette_generator`로 대표 색을 뽑아 상세 카드에 사용 | `lib/features/` |
| Riverpod | 탭 · 필터 · 언어는 `StateProvider`, 날씨 · 장소 · 버스 조회는 `FutureProvider`, 저장 일정은 `AsyncNotifierProvider`(`SavedRoutesNotifier`) | `lib/providers/app_providers.dart` |
| Dio · Service 계층 | `WeatherService`, `TransitService`, `TourService`가 공공 API를 호출 | `lib/core/services/` |
| Hive | 응답 캐시(`cache` 박스)와 저장 일정(`routes` 박스), 언어 · 알림 설정을 기기 로컬에 저장 | `core/services/cache_service.dart` |
| 기상청 단기예보 API | 권역 좌표의 하늘 상태 · 강수 형태 · 풍속 · 기온 | `WeatherService` |
| TAGO 버스 API | 정류장별 도착 예정(`ArvlInfoInqireService`)과 노선(`BusRouteInfoInqireService`). 정류장 ID가 있는 장소의 상세 화면에 표시 | `TransitService` |
| TourAPI · Tour DataLab | `KorService2`로 관광지 · 음식점 · 카페 목록, 이미지(`detailImage2`), 소개 · 운영시간(`detailIntro2`). `DataLabService1`로 관련 장소와 혼잡도 보조 지표. 음식점과 카페가 같은 콘텐츠 타입이라 카테고리 코드 `A05020900`으로 카페를 구분 | `TourService` |
| Geolocator | 현재 위치로 권역 판정 | `lib/core/utils/location_utils.dart` |
| Kakao Maps · WebView · url_launcher | 지도는 Kakao Maps JS SDK(모바일 `webview_flutter`, Web `web/kakao_map.js`), 길찾기는 `kakaomap://` 딥링크나 웹으로 연결 | `shared/widgets/kakao_map_view_*.dart` |

### 화면 표현과 알림

장소 사진은 cached_network_image로 표시하고 palette_generator가 뽑은 대표색을 상세 카드에 사용합니다. google_fonts와 Flutter 다국어 설정은 언어별 표시를 담당합니다. flutter_local_notifications와 timezone은 일정 알림에 사용합니다. 일정 저장과 API 캐시를 모두 Hive에 두지만 서로 다른 박스로 관리합니다.

## 실행

`.env.example`을 복사하고 키를 입력합니다.

| 키 | 발급 서비스 |
|---|---|
| `WEATHER_API_KEY` | 기상청 단기예보 |
| `TAGO_API_KEY` | 국토교통부 TAGO |
| `TOUR_API_KEY` | 한국관광공사 TourAPI |
| `KAKAO_MAP_KEY` | Kakao Developers JavaScript |

```bash
cp .env.example .env
flutter pub get
flutter run --dart-define-from-file=.env
```

웹 실행에는 별도 프록시가 필요합니다.

```bash
flutter run -d chrome --dart-define-from-file=.env \
  --dart-define=JEJUFLOW_API_PROXY=http://127.0.0.1:8787/
```

```bash
flutter analyze
flutter test
```
