# JejuFlow AI 구현 지시서

> 목적: 이 문서는 JejuFlow를 실제로 개발할 AI 코딩 에이전트가 바로 읽고 구현할 수 있도록 정리한 제작용 명세서다.  
> 기준 문서: `docs/PRODUCT.md`, `docs/designreference/stitch_jejuflow_tourism_app/evergreen_modern/DESIGN.md`, `JejuFlow_5page_proposal.md`  
> 현재 앱: Flutter 기반 iOS/Android 앱. Expo/Zustand가 아니라 Flutter + Riverpod 구조를 기준으로 구현한다.

---

## 1. 제품 한 줄 정의

JejuFlow는 렌터카 없이 제주를 여행하는 국내외 관광객에게 **지금 날씨에 맞고, 지금 대중교통으로 갈 수 있는 관광지**를 10초 안에 추천하는 제주 특화 관광 안내 앱이다.

핵심 질문은 하나다.

> 지금 날씨에, 지금 버스로, 지금 당장 어디 가면 돼?

---

## 2. 구현 원칙

1. 기존 Flutter 코드베이스를 유지한다.
   - 상태관리는 `flutter_riverpod`을 사용한다.
   - HTTP는 `dio`를 사용한다.
   - 로컬 저장은 `hive_flutter`을 사용한다.
   - 이미지는 `cached_network_image`와 `palette_generator`를 사용한다.
   - 폰트는 `google_fonts`를 사용한다.

2. 앱 구조는 3탭을 유지한다.
   - `Now`: 지금 갈 수 있는 추천 관광지
   - `Move`: 관광지 탐색 및 경로 확인
   - `Routes`: 저장한 경로 관리

3. “관광정보 + 날씨 + 교통”을 항상 한 화면 안에서 결합한다.
   - 관광지만 보여주는 목록 앱으로 만들지 않는다.
   - 버스 정보만 보여주는 교통 앱으로 만들지 않는다.
   - 날씨만 보여주는 대시보드로 만들지 않는다.

4. 공공데이터 API 실패 시에도 앱이 깨지지 않아야 한다.
   - 정적 관광지 데이터 `lib/core/constants/spot_data.dart`를 fallback으로 사용한다.
   - 네트워크 실패 시 skeleton, 빈 상태, cached 데이터 표시를 제공한다.

---

## 3. 현재 코드베이스 기준 파일 구조

주요 파일은 다음 구조를 따른다.

```text
lib/
  app.dart
  main.dart
  providers/app_providers.dart
  core/
    constants/
      api_keys.dart
      colors.dart
      spot_data.dart
    models/
      spot.dart
      weather.dart
      bus_arrival.dart
      saved_route.dart
      place.dart
      crowd_data.dart
    services/
      weather_service.dart
      transit_service.dart
      tour_service.dart
      cache_service.dart
      color_extract_service.dart
    utils/
      location_utils.dart
      route_utils.dart
      weather_utils.dart
      weather_themes.dart
      time_utils.dart
  features/
    now/now_screen.dart
    move/move_screen.dart
    routes/routes_screen.dart
  shared/widgets/
```

새 기능을 추가할 때는 이 구조를 우선 사용하고, 불필요한 새 아키텍처를 만들지 않는다.

---

## 4. 핵심 사용자

### 주 타깃

- 제주 방문 외국인 관광객
- 렌터카 없이 이동하는 여행자
- 영어, 일본어, 중국어 사용자

### 보조 타깃

- 렌터카를 이용하지 않는 한국인 여행자
- 1인 여행자
- 운전 부담이나 렌터카 비용 때문에 대중교통 여행을 선택한 사용자

---

## 5. MVP 화면 요구사항

## 5.1 Now 탭

역할: 앱을 열자마자 “지금 갈 만한 곳 TOP 3”를 보여준다.

필수 구성:

- 상단 브랜드 헤더
- 현재 지역과 날씨를 보여주는 히어로 카드
- 비, 강풍, 폭풍 등 bad weather일 때 실내 대체 추천 배너
- 오늘의 추천 관광지 TOP 3
- 관광지별 버스 대기시간, 도보시간, 총 이동 예상시간
- 현재 기준 다음 버스 정보
- TourAPI 기반 추가 추천 관광지 카드

추천 로직:

- 현재 위치를 기준으로 `SpotRegion.jejuCity` 또는 `SpotRegion.seogwipo`를 판별한다.
- 날씨가 좋으면 outdoor, indoor, both 관광지를 모두 노출한다.
- 날씨가 좋지 않으면 indoor 또는 both 관광지를 우선 노출한다.
- TOP 3는 대중교통 접근성이 높은 정적 관광지 `kSpots`를 우선 사용한다.
- 추가 추천은 `TourService.fetchWeatherSpots`를 사용한다.

날씨 bad 기준:

- 비
- 강풍
- 폭풍
- 강수확률 또는 풍속이 일정 기준 이상인 상태

사용자 액션:

- 추천 관광지를 누르면 `selectedSpotProvider`에 저장하고 Move 탭으로 이동한다.
- 날씨 배너의 전환 액션을 누르면 실내 관광지 탐색 상태로 이동한다.

---

## 5.2 Move 탭

역할: 목적지를 선택하고, 대중교통 경로와 관광지 정보를 한 화면에서 확인한다.

필수 구성:

- 관광지 탐색 탭
  - Sights
  - Food
  - Cafe
- 관광지 카드 grid
- 관광지 상세 bottom sheet
- 선택된 관광지의 route planner

Route Planner 필수 구성:

- 뒤로가기
- 관광지명, 이모지, 총 소요시간
- 출발지 → 도보 → 버스 → 도보 → 목적지 형태의 step UI
- 버스 번호, 대기시간, 정류장명, 도보시간
- 날씨가 좋지 않은데 outdoor 관광지를 선택한 경우 경고 카드
- 대체 실내 관광지 제안
- 저장 버튼

저장 동작:

- `buildSavedRoute`로 `SavedRoute`를 만든다.
- `savedRoutesProvider.notifier.add(route)`를 호출한다.
- 저장 완료 snackbar를 표시한다.

---

## 5.3 Routes 탭

역할: 사용자가 저장한 경로를 관리한다.

필수 구성:

- 저장된 route 목록
- 날짜별 grouping
- route card
- 날씨 영향 경고
- Use Now 버튼
- Delete 버튼
- Reorder 모드

날씨 영향 경고:

- 저장된 route가 outdoor 관광지를 포함한다.
- 현재 날씨가 bad weather다.
- 이 경우 카드 안에 `Weather affected` 성격의 경고를 표시한다.

Use Now 동작:

- 저장 route의 `spotId`로 `kSpotById`를 찾는다.
- `selectedSpotProvider`에 설정한다.
- Move 탭으로 이동한다.

---

## 6. 데이터 모델 요구사항

기존 `Spot` 모델을 중심으로 유지한다.

```dart
class Spot {
  final String id;
  final String nameEn;
  final String emoji;
  final String sub;
  final SpotCategory category;
  final SpotRegion region;
  final String nearestStop;
  final String stopId;
  final List<String> busRoutes;
  final int walkMinutes;
  final int busWaitMinutes;
  final Color bgColor;
  final Color accentColor;
  final int fee;
  final String hours;
  final List<String> tags;
  final String? altSpotId;
  final String contentId;
  final double lat;
  final double lng;
}
```

추가 확장 시 우선순위:

1. `photoUrl`
2. `descriptionEn`
3. `crowdLevel`
4. `relatedSpotIds`
5. 다국어 name/description

단, MVP에서는 정적 데이터와 API 데이터를 섞어서 동작하게 만들면 된다.

---

## 7. API 활용 요구사항

### 7.1 한국관광공사 TourAPI

필수 활용:

- 국문/영문 관광정보
- 지역 기반 관광지 목록
- 관광지 상세정보
- 관광지 이미지
- 연관 관광지
- 방문자 집중률 또는 관광지 집중률 데이터

활용 목적:

- 관광지명
- 설명
- 주소
- 대표 이미지
- 운영시간
- 입장료
- 전화번호
- 연관 관광지
- 혼잡도 badge

### 7.2 기상청 단기예보

활용 목적:

- 현재 날씨 상태
- 강수 여부
- 강수확률
- 풍속
- 제주시/서귀포시 권역별 날씨

추천 분류:

- clear: 야외 관광지 추천
- cloudy: 야외/실내 모두 추천
- rain: 실내 관광지 우선
- windy: 실내 또는 짧은 도보 관광지 우선
- storm: 실내 대체지와 안전 안내 우선

### 7.3 TAGO 버스 정보

활용 목적:

- 관광지 인근 정류장 도착 예정 버스
- 버스 번호
- 대기시간
- 노선 방향
- 정류장 ID 기반 조회

### 7.4 지도

현재 의존성은 `google_maps_flutter`다. 제안서에는 카카오맵이 언급되어 있으나, 현재 코드베이스 기준으로는 Google Maps를 우선 사용한다. 카카오맵 SDK로 바꾸려면 별도 작업으로 분리한다.

지도 활용:

- 관광지 위치
- 인근 정류장 위치
- 정류장에서 관광지까지 도보 이동 안내

---

## 8. 디자인 시스템 적용

기준 디자인은 Evergreen Modern이다.

### 색상

기본 토큰:

```yaml
background: '#fcf9f2'
surface: '#ffffff'
surface-container: '#f0eee7'
primary: '#4b6450'
secondary: '#7a5645'
tertiary: '#a43d00'
on-surface: '#1c1c18'
outline: '#757873'
```

현재 앱의 `AppColors`는 아래 방향으로 조정한다.

- 배경은 따뜻한 off-white 계열
- primary는 forest green
- secondary는 warm taupe
- tertiary는 orange CTA
- 검정/회색은 너무 차갑지 않은 charcoal 계열

### 타이포그래피

디자인 레퍼런스:

- Heading: Montserrat
- Body: Inter

현재 앱은 `GoogleFonts.outfitTextTheme()`을 사용 중이다. 디자인 일관성을 우선한다면 다음 중 하나를 선택한다.

1. 전체 앱을 Montserrat + Inter로 변경
2. 현재 Outfit을 유지하되 색상/공간/컴포넌트만 Evergreen Modern으로 반영

추천: 구현 안정성을 위해 MVP에서는 Outfit 유지, 디자인 정리 단계에서 Montserrat + Inter로 교체한다.

### 형태

- 버튼: pill 또는 14~24px radius
- 카드: 18~24px radius
- bottom sheet: 상단 24px radius
- chip/tag: pill
- list divider는 강한 선보다 tonal layer를 사용

### 화면 톤

- 관광 앱이므로 이미지가 중요하다.
- 관광지 카드에는 가능하면 TourAPI 대표 이미지를 사용한다.
- 이미지가 없을 때만 색상 팔레트 fallback을 사용한다.
- 지나치게 어둡거나 단색 위주의 UI로 만들지 않는다.

---

## 9. 다이나믹 컬러 시스템

색상 우선순위:

1. 관광지 대표 이미지에서 추출한 색상
2. `spot_data.dart`에 저장된 관광지별 `bgColor`와 `accentColor`
3. 날씨와 시간대 기반 기본 테마

관광지 fallback 예:

| 관광지 | background | accent |
|---|---|---|
| Seongsan Sunrise Peak | `#2A1C08` | `#D4922A` |
| Hallim Park | `#0E2410` | `#4E9848` |
| Manjanggul Lava Tube | `#160C1C` | `#8A58A8` |
| Hyeopjae Beach | `#062232` | `#00B8A8` |
| Haenyeo Museum | `#08141E` | `#2878B0` |

구현 지침:

- `ColorExtractService.extract`를 우선 사용한다.
- 추출 실패 시 `Spot.accentColor`를 사용한다.
- 텍스트 대비가 부족하면 흰색 또는 charcoal로 자동 보정한다.

---

## 10. 다국어 요구사항

MVP 우선순위:

1. 영어 UI 기본 제공
2. 한국어 관광객도 이해 가능한 간단한 용어 사용
3. 이후 Settings에서 한국어/영어/일본어/중국어 선택

다국어가 들어갈 위치:

- 탭명
- 날씨 상태
- 관광지 설명
- 정류장명
- 경로 step
- 저장/삭제/사용 버튼
- 오류/빈 상태 메시지

초기에는 hardcoded text를 유지하되, 다음 단계에서 `AppLocalizations` 또는 간단한 translation map으로 분리한다.

---

## 11. 구현 작업 순서

### Step 1. 디자인 토큰 정리

- `lib/core/constants/colors.dart`를 Evergreen Modern에 맞게 조정한다.
- 카드, 버튼, chip에서 같은 radius와 spacing을 쓰도록 정리한다.
- 배경, surface, separator, text 색상 대비를 확인한다.

### Step 2. Now 탭 완성도 향상

- 날씨 히어로 카드의 정보 밀도를 정리한다.
- TOP 3 추천 카드에 총 이동시간, 버스 대기시간, 도보시간을 명확히 표시한다.
- bad weather 배너에서 실내 대체지 이동 동작을 확실하게 만든다.
- TourAPI 추천 카드가 실패해도 정적 추천이 보이게 한다.

### Step 3. Move 탭 경로 경험 강화

- 관광지 선택 후 route planner가 바로 이해되도록 step UI를 다듬는다.
- outdoor 관광지 + bad weather 조합이면 대체 관광지 CTA를 제공한다.
- 관광지 상세 bottom sheet에 이미지, 주소, 전화번호, 운영시간, 입장료를 표시한다.
- `altSpotId`가 있으면 대체 관광지로 즉시 전환할 수 있게 한다.

### Step 4. Routes 탭 저장 경험 강화

- 저장된 route card에 관광지명, 저장일, 총 이동시간, 요금, 버스 정보를 표시한다.
- 현재 날씨가 route에 영향을 주면 경고 badge를 표시한다.
- Use Now, Delete, Reorder를 안정적으로 동작하게 한다.

### Step 5. API 안정성 및 캐시

- API key가 없는 경우에도 앱이 fallback 데이터로 실행되게 한다.
- Dio 에러는 사용자에게 과하게 노출하지 않는다.
- Hive 또는 memory cache로 최근 API 응답을 재사용한다.

### Step 6. 출시 전 점검

- `flutter analyze` 통과
- iOS simulator 또는 Android emulator 실행 확인
- API 실패/느린 네트워크 상태 확인
- 위치 권한 거부 상태 확인
- 저장 route persistence 확인

---

## 12. 완료 기준

다음 조건을 만족하면 MVP 구현 완료로 본다.

- 앱 실행 후 Now 탭에서 현재 날씨와 추천 관광지 TOP 3가 보인다.
- 날씨가 bad일 때 실내 관광지가 우선 추천된다.
- 관광지를 누르면 Move 탭에서 경로 step을 볼 수 있다.
- 버스 대기시간, 도보시간, 총 이동시간이 표시된다.
- Route를 저장하고 Routes 탭에서 다시 사용할 수 있다.
- 저장 route가 현재 bad weather에 영향을 받으면 경고가 표시된다.
- TourAPI, 기상청, TAGO API 중 일부가 실패해도 앱 전체가 중단되지 않는다.
- Evergreen Modern 디자인 방향이 앱 전체에 반영되어 있다.

---

## 13. 주의사항

- 과거 Expo, Zustand, React Native 기준 문서나 코드 예시는 현재 저장소에는 적용하지 않는다.
- 현재 저장소는 Flutter 앱이며, `pubspec.yaml`의 의존성을 기준으로 작업한다.
- 대규모 리팩터링보다 현재 동작을 유지하면서 화면 완성도와 API 안정성을 높이는 것이 우선이다.
- API 키는 코드에 하드코딩하지 않는다. `.env`와 `api_keys.dart`의 기존 방식을 확인한 뒤 따른다.
- 공모전/제안서 제출용 화면이 필요하면 Home/Now 화면과 Route/Move 화면을 우선 캡처한다.
