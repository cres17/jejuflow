# JejuFlow 개발 환경 세팅

> 현재 저장소는 Flutter 앱이다. Expo/React Native 기준 명령어를 사용하지 않는다.

---

## 1. 요구사항

- Flutter SDK
- Dart SDK
- Android Studio 또는 VS Code
- Android SDK
- iOS 빌드가 필요하면 macOS + Xcode
- data.go.kr API 키
- Google Maps 키, 지도 기능 사용 시

현재 의존성은 `pubspec.yaml`을 기준으로 한다.

```yaml
flutter_riverpod
dio
hive_flutter
geolocator
google_maps_flutter
cached_network_image
palette_generator
google_fonts
flutter_dotenv
flutter_animate
intl
collection
```

---

## 2. 설치

```bash
flutter pub get
```

Flutter doctor 확인:

```bash
flutter doctor
```

---

## 3. `.env` 작성

프로젝트 루트에 `.env` 파일을 둔다.

```env
EXPO_PUBLIC_WEATHER_API_KEY=기상청_Decoding_키
EXPO_PUBLIC_TAGO_API_KEY=TAGO_Decoding_키
EXPO_PUBLIC_TOUR_API_KEY=TourAPI_Decoding_키
EXPO_PUBLIC_GOOGLE_MAPS_KEY=Google_Maps_키
```

이름은 과거 Expo prefix가 남아 있지만 현재 Flutter 앱에서도 그대로 읽는다.

주의:

- `.env`는 커밋하지 않는다.
- data.go.kr 키는 Decoding 키를 권장한다.
- `pubspec.yaml`의 assets에 `.env`가 포함되어 있어야 한다.

---

## 4. 실행

연결된 디바이스 확인:

```bash
flutter devices
```

앱 실행:

```bash
flutter run
```

Chrome/web 실행은 지도/위치/API 동작이 모바일과 다를 수 있으므로 MVP 검증은 Android emulator 또는 iOS simulator를 우선한다.

---

## 5. 분석과 테스트

정적 분석:

```bash
flutter analyze
```

테스트:

```bash
flutter test
```

특정 Dart 파일 분석이 필요하면 기존 승인된 방식처럼 `dart analyze`를 사용할 수 있다.

---

## 6. 주요 문서

| 문서 | 역할 |
|---|---|
| `docs/AI_IMPLEMENTATION_BRIEF.md` | AI 구현 지시서, 가장 먼저 볼 문서 |
| `docs/PRODUCT.md` | 제품 기획과 기능 범위 |
| `docs/API.md` | API, env, provider 연결 |
| `docs/designreference/.../DESIGN.md` | Evergreen Modern 디자인 시스템 |

---

## 7. 개발 시작 순서

1. `.env` 키 확인
2. `flutter pub get`
3. `flutter analyze`
4. Now 탭에서 날씨와 추천 관광지가 보이는지 확인
5. Move 탭에서 관광지 선택과 route planner 확인
6. Routes 탭에서 저장/삭제/재사용 확인
7. API 실패 상태에서도 fallback UI가 유지되는지 확인

---

## 8. 출시 전 체크리스트

- 위치 권한 문구 확인
- Android/iOS 앱 이름과 아이콘 확인
- API 키 노출 여부 확인
- Google Maps 키 플랫폼 제한
- 개인정보 처리방침 URL 준비
- App Store/Play Store 스크린샷 준비
