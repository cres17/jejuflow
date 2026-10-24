<div align="center">

<img src="assets/branding/jejuflow-logo.png" alt="JEJUFLOW 로고" width="140" height="140">

# JEJUFLOW

날씨를 보고, 지금 갈 곳을 고르고, 버스로 이어지는 제주 여행

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logoColor=white&logo=flutter)
![Riverpod](https://img.shields.io/badge/Riverpod-0553B1?style=flat&logoColor=white)
![Dio](https://img.shields.io/badge/Dio-0175C2?style=flat&logoColor=white)
![Hive](https://img.shields.io/badge/Hive-C27C0E?style=flat&logoColor=white)
![Kakao Maps](https://img.shields.io/badge/Kakao%20Maps-FFCD00?style=flat&logoColor=black&logo=kakao)
![기상청 API](https://img.shields.io/badge/%EA%B8%B0%EC%83%81%EC%B2%AD%20API-2B6CB0?style=flat&logoColor=white)
![TAGO](https://img.shields.io/badge/TAGO-1F7A5C?style=flat&logoColor=white)
![TourAPI](https://img.shields.io/badge/TourAPI-1F6F8B?style=flat&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=flat&logoColor=black&logo=android)

</div>

제주 여행 중 "그래서 지금 어디로 가지?"를 빠르게 정하도록 돕는 Flutter 앱입니다. 현재 위치로 제주시 · 서귀포시 권역을 나누고, 기상청 예보가 비 · 강풍이면 실내 장소를, 아니면 야외 장소를 먼저 카드로 보여 줍니다. 카드를 위로 밀면 일정에 담고 아래로 밀면 넘기며, 담은 장소는 날짜별 타임라인과 버스 도착 정보, 카카오맵 길찾기로 이어집니다. 한국어 · 영어 · 일본어 · 중국어를 지원합니다.

| 탭 | 기능 |
|----|------|
| Now | 날씨와 권역에 맞춘 추천 카드, 위로 밀어 일정 추가 · 아래로 밀어 건너뛰기 |
| Move | 관광지 · 음식점 · 카페 검색과 필터, 상세 정보, 버스 도착 정보, 지도 |
| Routes | 날짜별 일정 타임라인, 순서 변경, 이동 · 체류 시간 추정, 카카오맵 열기 |
| Settings | 언어 변경, 일정 30분 전 알림 |

## 화면

| 지금 | 탐색 | 일정 | 설정 |
|:----:|:----:|:----:|:----:|
| <img src="docs/screenshots/home.png" width="190"> | <img src="docs/screenshots/explore.png" width="190"> | <img src="docs/screenshots/itinerary.png" width="190"> | <img src="docs/screenshots/settings.png" width="190"> |

Flutter 웹 빌드를 API 키 없이 실행해 촬영했습니다. 날씨와 관광지는 API 키가 없을 때 쓰는 앱 내장 기본값(`weather_service.dart`, `app_providers.dart`의 fallback)이며, 일정 화면은 탐색 탭에서 3곳을 추가한 상태입니다.

## 전체 아키텍처

<p align="center">
  <img src="docs/assets/readme/architecture.svg" alt="JEJUFLOW 전체 아키텍처" width="100%">
</p>

서버 없이 Flutter 클라이언트가 공공 API를 직접 호출하는 구조입니다. 화면은 Riverpod Provider만 구독하고, 실제 통신과 캐시는 Service 계층이 맡습니다.

| 흐름 | 설명 |
|------|------|
| 시작 | `main.dart`가 Hive 박스(`cache`, `routes`)와 알림 서비스를 연 뒤 `appInitProvider`가 위치 → 권역 → 날씨를 순서대로 준비 |
| 추천 | 날씨를 `clear / cloudy / rain / windy / storm`으로 분류하고, TourAPI 후보와 앱에 내장한 대표 장소(`spot_data.dart`)를 섞어 카드 구성 |
| 조회 | Service가 공공 API를 호출하고 응답을 Hive에 TTL과 함께 저장. 실패하면 만료된 캐시나 내장 장소로 화면 유지 |
| 일정 | 일정은 Hive `routes` 박스에 저장하고, 알림이 켜져 있으면 출발 30분 전 로컬 알림 예약 |
| 지도 | 앱 안의 지도는 Kakao Maps JS SDK를 WebView로, 실제 길찾기는 카카오맵 앱 · 웹 딥링크로 연결 |

```text
lib/
├── features/      now · move · routes · settings 화면
├── providers/     app_providers.dart (Riverpod 상태와 비동기 조회)
├── core/
│   ├── services/  weather · transit · tour · cache · notification · color_extract
│   ├── models/    Spot · Place · Weather · BusArrival · SavedRoute
│   ├── utils/     날씨 분류 · 거리 · 시간 · 위치 계산
│   └── constants/ 내장 대표 장소 · API 키 · 색상
└── shared/widgets/ 카드 · 지도(Kakao WebView) · 경로 단계 위젯
```

## 기능 흐름

### 1. 앱 시작과 권역 판정

위치 권한이 없거나 좌표를 10초 안에 받지 못해도 제주시 권역으로 시작합니다.

```mermaid
flowchart TD
  A([앱 실행]) --> B[Hive 박스 열기 cache · routes<br/>로컬 알림 초기화]
  B --> D{위치 권한 있고<br/>10초 안에 좌표 수신?}
  D -- 예 --> E{위도 &lt; 33.38}
  E -- 예 --> F[서귀포시 권역]
  E -- 아니오 --> G[제주시 권역]
  D -- 아니오 --> G
  F --> H
  G --> H[권역 날씨 조회]
  H --> I[저장 일정 불러오기<br/>알림 켜짐이면 30분 전 알림 예약]
  I --> L[TourAPI 관광지 · 음식점 목록<br/>백그라운드 미리 받기]
```

### 2. 날씨 판정

기상청 단기예보 값을 다섯 가지 상태로 나누고, 그 결과로 Now 탭에 실내 카드만 보여 줄지 야외 카드만 보여 줄지 정합니다.

```mermaid
flowchart LR
  W[기상청 단기예보<br/>강수형태 PTY · 풍속 WSD · 하늘 SKY] --> P{비 · 눈<br/>PTY 1~4?}
  P -- 예 --> PW{풍속 ≥ 14m/s}
  PW -- 예 --> ST[storm]
  PW -- 아니오 --> RA[rain]
  P -- 아니오 --> WW{풍속 ≥ 14m/s}
  WW -- 예 --> WI[windy]
  WW -- 아니오 --> SK{SKY = 4<br/>흐림?}
  SK -- 예 --> CL[cloudy]
  SK -- 아니오 --> CE[clear]
  ST & RA & WI --> BAD[[실내 카드만]]
  CL & CE --> GOOD[[야외 카드만]]
  classDef bad fill:#fde8e4,stroke:#d9826f,color:#5b2a20
  classDef good fill:#e6f4ea,stroke:#6fae7f,color:#1f4a2b
  class ST,RA,WI,BAD bad
  class CL,CE,GOOD good
```

### 3. Now 탭 추천 카드

TourAPI 추천을 우선 쓰고, 응답이 비면 앱 내장 대표 장소로 채웁니다. TourAPI 장소는 관광지를 야외, 음식점 · 카페를 실내로 분류합니다.

```mermaid
flowchart LR
  subgraph SRC[카드 후보]
    T[TourAPI 무작위 추천<br/>관광지 12 · 음식점 6 · 카페 6] -->|비어 있으면| K[앱 내장 대표 장소<br/>현재 권역]
  end
  SRC --> F[날씨 필터<br/>실내 또는 야외]
  F --> X[일정에 담은 곳 ·<br/>넘긴 곳 제외 · 최대 20장]
  X --> C{{맨 위 카드 드래그}}
  C -- 위로 80px 이상 --> D[추가 대화상자<br/>시간 지정 선택] --> R[(일정 초안)]
  C -- 아래로 80px 이상 --> S[(넘긴 장소 목록)]
  C -- 그 외 --> Z[제자리로 복귀]
```

### 4. 공공 API 조회와 캐시

모든 조회는 같은 순서를 따르므로 네트워크가 끊겨도 화면이 비지 않습니다. 유효 시간은 버스 도착 1분, 날씨 10분, 버스 노선 1일, 장소 30일입니다.

```mermaid
flowchart LR
  Q([조회 요청]) --> H{Hive 캐시<br/>유효 시간 안?}
  H -- 예 --> OK([캐시 반환])
  H -- 아니오 --> API[공공 API 호출]
  API -- 성공 --> SAVE[data + cachedAt 저장] --> OK2([새 응답 반환])
  API -- 실패 --> STALE{만료된 캐시<br/>있음?}
  STALE -- 예 --> OK3([만료 캐시 반환])
  STALE -- 아니오 --> FB([내장 기본값<br/>날씨: 맑음 22°C<br/>장소: 대표 장소])
  classDef ok fill:#e6f4ea,stroke:#6fae7f
  classDef fb fill:#fff4dc,stroke:#d9b45f
  class OK,OK2,OK3 ok
  class FB fb
```

### 5. 일정 타임라인과 알림

```mermaid
flowchart LR
  A[장소 A] -->|"이동: 거리 ÷ 24km/h + 8분<br/>(최소 12분)"| B[장소 B]
  B -->|"체류: 55~110분<br/>(장소 태그로 결정)"| C[다음 장소]
  C -.-> S1[일정 저장 · 시간 변경] --> S2[기존 알림 취소] --> S3[출발 30분 전<br/>알림 다시 예약]
```

## 핵심 설계 결정

| 결정 | 방식 | 위치 |
|------|------|------|
| 서버 없이 클라이언트가 공공 API를 직접 호출 | 화면은 Provider만 `watch`하고 통신과 캐시는 Service 계층이 맡습니다. 모바일은 HTTPS로 직접 요청하고, Web은 CORS 때문에 `JEJUFLOW_API_PROXY`로 지정한 프록시를 거칩니다. | `lib/providers/app_providers.dart`, `core/services/` |
| API가 실패해도 화면 유지 | 응답을 `data`와 `cachedAt`을 담은 JSON으로 Hive에 저장합니다. 유효 시간은 버스 도착 1분, 날씨 10분, 버스 노선 1일, TourAPI 장소 · 상세 30일이며, 실패하면 `getStale`로 만료된 값이나 앱에 내장한 대표 장소를 돌려줍니다. | `core/services/cache_service.dart` |
| 날씨로 추천 후보를 거름 | 하늘 상태 · 강수 형태 · 풍속을 `clear / cloudy / rain / windy / storm`으로 분류하고, `rain` · `windy` · `storm`이면 실내 후보만, 그 밖에는 야외 후보만 카드로 보여 줍니다. | `core/utils/weather_utils.dart`, `features/now/now_screen.dart` |
| 권한이 없어도 동작하는 위치 처리 | 현재 위치의 위도가 33.38보다 낮으면 서귀포시, 아니면 제주시 권역으로 정합니다. 권한이 없거나 10초 안에 위치를 받지 못하면 제주시를 기본값으로 쓰며 이동 경로는 기록하지 않습니다. | `lib/core/utils/location_utils.dart` |
| 일정 시간은 규칙으로 추정 | 장소 간 Haversine 거리를 평균 24km/h로 이동하는 시간에 8분 여유(최소 12분)를 더하고, 장소 태그에 따라 55~110분을 체류 시간으로 잡아 하루 타임라인을 만듭니다. | `lib/core/utils/route_utils.dart` |
| 알림은 일정 변경에 맞춰 다시 예약 | 알림을 켜면 권한을 요청하고, 미래 일정마다 30분 전 알림을 `Asia/Seoul` 기준으로 예약합니다. 일정을 지우거나 시간을 바꾸면 기존 알림을 취소하고 다시 예약합니다. | `core/services/local_notification_service.dart` |

## 실행

API 키는 소스에 넣지 않고 `--dart-define`으로 주입합니다. `.env.example`을 `.env`로 복사해 키를 채웁니다.

| 키 | 용도 |
|----|------|
| `WEATHER_API_KEY` | 기상청 단기예보 (공공데이터포털 서비스 키) |
| `TAGO_API_KEY` | 국토교통부 TAGO 버스 정보 |
| `TOUR_API_KEY` | 한국관광공사 TourAPI · Tour DataLab |
| `KAKAO_MAP_KEY` | Kakao Developers JavaScript 키 |

```bash
cp .env.example .env
flutter pub get
flutter run --dart-define-from-file=.env                # Android
flutter run -d chrome --dart-define-from-file=.env \
  --dart-define=JEJUFLOW_API_PROXY=http://127.0.0.1:8787/   # Web (프록시는 별도 준비)
```

```bash
flutter analyze
flutter test
```

## 기술 구성

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
