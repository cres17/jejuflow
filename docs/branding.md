# JEJUFLOW 로고

길 모양의 무늬가 있는 걷는 귤을 공통 로고로 사용합니다.
선택된 귤 로고의 바깥 배경을 제거한 투명 PNG는 `assets/branding/jejuflow-logo.png`입니다.
귤 안쪽의 길 무늬와 눈의 흰 부분은 유지합니다.

- README: 원본 로고와 대체 설명.
- 앱 화면: 언어 선택, Now 헤더, 설정 화면의 `JejuFlowLogo`.
- Android: 5개 밀도별 실행 아이콘과 Android 8 이상 적응형 아이콘.
- 웹: 파비콘, Apple 터치 아이콘, 일반·maskable 설치 아이콘.
- iOS: `AppIcon.appiconset` 리소스. 현재 저장소에는 Xcode 프로젝트가 없어 iOS 실행·빌드는 별도 구성이 필요합니다.

README, 인앱 로고, 파비콘, 일반 웹 아이콘과 Android 전경은 투명 배경을 유지합니다.
아이콘은 원본을 비율대로 축소해 생성합니다. 적응형·maskable 아이콘은
둥근 홈 화면 마스크가 잎과 발을 자르지 않도록 더 넓은 여백을 사용합니다.
Android 적응형 아이콘의 배경 레이어와 웹 maskable·iOS 설치 아이콘에는 플랫폼 표시용
크림색 배경을 사용합니다. 인앱 로고에는 사각형 배경을 추가하지 않습니다.

## 다시 생성하기

저장소 루트에서 다음을 실행합니다.

```sh
flutter pub get
dart run tool/generate_brand_icons.dart
```

브랜드 글자가 함께 보이는 화면의 로고는 접근성 트리에서 장식 이미지로 처리합니다.
로고를 단독으로 사용할 때는 `JejuFlowLogo`의 기본 대체 설명 `JEJUFLOW`를 사용합니다.
