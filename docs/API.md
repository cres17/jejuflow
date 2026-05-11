# JejuFlow API 명세

> 현재 앱 기준: Flutter + Dio + Riverpod  
> 관련 코드: `lib/core/services`, `lib/providers/app_providers.dart`, `lib/core/constants/api_keys.dart`

---

## 1. 환경 변수

현재 `ApiKeys`는 다음 `.env` 키를 읽는다.

```env
EXPO_PUBLIC_WEATHER_API_KEY=
EXPO_PUBLIC_TAGO_API_KEY=
EXPO_PUBLIC_TOUR_API_KEY=
EXPO_PUBLIC_GOOGLE_MAPS_KEY=
```

이름은 과거 Expo 시절 prefix가 남아 있지만, 현재 Flutter 앱에서도 그대로 사용한다. 키는 `.env`에만 두고 코드에 하드코딩하지 않는다.

주의:

- data.go.kr 키는 Decoding 키를 권장한다.
- Encoding 키가 들어와도 `ApiKeys._decoded`에서 한 번 decode한다.
- `.env`는 `pubspec.yaml` assets에 포함되어 있다.

---

## 2. API 키 클래스

파일: `lib/core/constants/api_keys.dart`

```dart
class ApiKeys {
  static String get weather => dotenv.env['EXPO_PUBLIC_WEATHER_API_KEY'] ?? '';
  static String get tago => dotenv.env['EXPO_PUBLIC_TAGO_API_KEY'] ?? '';
  static String get tour => dotenv.env['EXPO_PUBLIC_TOUR_API_KEY'] ?? '';
  static String get maps => dotenv.env['EXPO_PUBLIC_GOOGLE_MAPS_KEY'] ?? '';
}
```

Base URL:

| API | Base |
|---|---|
| 기상청 | `https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0` |
| TAGO | `https://apis.data.go.kr/1613000` |
| TourAPI | `https://apis.data.go.kr/B551011/KorService2` |

---

## 3. 기상청 단기예보

파일: `lib/core/services/weather_service.dart`

사용 목적:

- 현재 날씨 카드
- 지역별 추천 필터
- bad weather 판단
- 날씨별 accent/background theme

엔드포인트:

```text
GET /1360000/VilageFcstInfoService_2.0/getVilageFcst
```

주요 파라미터:

| 파라미터 | 값 |
|---|---|
| serviceKey | `ApiKeys.weatherServiceKey` |
| dataType | `JSON` |
| nx, ny | 제주시 `53,38`, 서귀포시 `52,33` |
| base_date, base_time | `getKMABaseDateTime()` |

날씨 분류:

| 조건 | 앱 상태 |
|---|---|
| PTY가 비/눈/소나기 | rain |
| WSD가 강풍 기준 이상 | windy |
| 비와 강풍 동시 | storm |
| SKY 흐림 | cloudy |
| 그 외 | clear |

캐시:

- key: `weather:{region.name}`
- TTL: 10분
- 실패 시 stale cache 사용
- stale cache도 없으면 mock clear weather 사용

---

## 4. TAGO 버스 정보

파일: `lib/core/services/transit_service.dart`

사용 목적:

- 관광지 인근 정류장의 다음 버스 도착 정보
- 경로 step 내 버스 번호, 대기시간 표시
- 장시간 대기 여부 표시

### 4.1 버스도착정보

엔드포인트:

```text
GET /1613000/ArvlInfoInqireService/getSttnAcctoArvlPrearngeInfoList
```

주요 파라미터:

| 파라미터 | 값 |
|---|---|
| serviceKey | `ApiKeys.tagoServiceKey` |
| cityCode | `39` |
| nodeId | `Spot.stopId` |
| _type | `json` |

캐시:

- key: `bus:{stopId}`
- TTL: 1분
- 실패 시 stale cache 사용
- stale cache도 없으면 빈 배열 반환

### 4.2 버스노선정보

엔드포인트:

```text
GET /1613000/BusRouteInfoInqireService/getRouteInfoIem
```

주요 파라미터:

| 파라미터 | 값 |
|---|---|
| serviceKey | `ApiKeys.tagoServiceKey` |
| cityCode | `39` |
| routeId | 노선 ID |
| _type | `json` |

캐시:

- key: `route:{routeId}`
- TTL: 1일
- 실패 시 stale cache 사용

---

## 5. 한국관광공사 TourAPI

파일: `lib/core/services/tour_service.dart`

공통 파라미터:

| 파라미터 | 값 |
|---|---|
| serviceKey | `ApiKeys.tourServiceKey` |
| MobileOS | `ETC` |
| MobileApp | `JejuFlow` |
| _type | `json` |

### 5.1 지역 기반 관광지 목록

메서드:

```dart
TourService.fetchPlaces(PlaceType type)
```

엔드포인트:

```text
GET /B551011/KorService2/areaBasedList2
```

사용:

- Move 탭 Sights/Food/Cafe 목록
- Now 탭 추가 추천

주요 파라미터:

| 파라미터 | 값 |
|---|---|
| areaCode | `39` 제주 |
| contentTypeId | 관광지 `12`, 음식점/카페 `39` |
| arrange | `C` |

### 5.2 관광지 이미지

메서드:

```dart
TourService.fetchPhotos(String contentId)
```

엔드포인트:

```text
GET /B551011/KorService2/detailImage2
```

사용:

- 관광지 카드 대표 이미지
- 상세 bottom sheet 이미지
- 색상 추출 소스

### 5.3 영문 관광정보

메서드:

```dart
TourService.fetchInfoEN(String contentId)
```

엔드포인트:

```text
GET /B551011/EngService2/detailCommon2
```

사용:

- 외국인 대상 관광지 설명
- 영문 주소
- 전화번호
- 홈페이지
- 운영시간/입장료

### 5.4 연관 관광지

메서드:

```dart
TourService.fetchRelated(String contentId)
```

엔드포인트:

```text
GET /B551011/TourSpotsDataLabService1/getRltdTuristSpotsInfo
```

사용:

- Move 탭 `You might also like`
- bad weather 시 indoor/both 중심 대체 추천으로 확장 가능

### 5.5 관광지 집중률

메서드:

```dart
TourService.fetchCrowdIndex(String contentId)
```

엔드포인트:

```text
GET /B551011/DataLabService1/areaBasedList1
```

사용:

- 혼잡도 badge
- `CrowdData.classify(index)`로 low/moderate/high 분류

---

## 6. Provider 연결

파일: `lib/providers/app_providers.dart`

| Provider | 역할 |
|---|---|
| `weatherProvider(region)` | 지역별 날씨 조회 |
| `currentWeatherProvider` | 현재 선택 지역의 날씨 |
| `busArrivalsProvider(stopId)` | 정류장별 버스 도착 정보 |
| `placeListProvider(type)` | TourAPI 관광지/음식점/카페 목록 |
| `weatherSpotsProvider` | 날씨 기반 추천 관광지 |
| `spotPhotosProvider(contentId)` | 관광지 이미지 |
| `spotInfoProvider(contentId)` | 영문 관광지 상세 |
| `relatedSpotsProvider(contentId)` | 연관 관광지 |
| `crowdProvider(contentId)` | 혼잡도 |
| `savedRoutesProvider` | 저장 경로 Hive persistence |

---

## 7. 장애 처리 원칙

| API | 실패 시 |
|---|---|
| 기상청 | stale cache, 없으면 mock weather |
| TAGO 버스도착 | stale cache, 없으면 빈 배열 |
| TAGO 노선 | stale cache, 없으면 null |
| TourAPI 목록 | 빈 배열 |
| TourAPI 이미지 | 이미지 없는 카드 fallback |
| TourAPI 영문정보 | 정적 spot 정보 유지 |
| 연관 관광지 | 섹션 숨김 |
| 집중률 | badge 숨김 |

화면은 API 실패로 비어 있으면 안 된다. 정적 데이터 `kSpots`와 skeleton/empty state를 함께 사용한다.
