# JejuFlow 🌿

> **렌터카 없는 외국인 여행자를 위한 제주 스마트 여행 앱**  
> Korea Tourism Organization Open Contest 2026

---

## 핵심 가치

"나 지금 여기 있고, 날씨 이렇고, 다음 버스 언제야 — 지금 당장 어디 가면 돼?"

이 한 문장에 답하는 앱입니다.

---

## 3-Tab 구조

| 탭 | 역할 |
|---|---|
| ⚡ **Now** | 현재 날씨·위치 기반으로 "지금 버스 타면 몇 시 도착" 즉시 계산 |
| 🗺 **Move** | 목적지 선택 → 버스 대기·도보·도착시각 단계별 경로 |
| 📋 **Routes** | 저장한 루트 모아보기, 날씨 악화 시 자동 경고 |

---

## 차별화 기능

- **배차 30분↑** → 택시 추천 자동 표시
- **날씨 악화 감지** → 실내 대안 루트 한번에 스왑
- **도착 예정시각 실시간 계산** (버스 대기 + 도보 합산)
- **Pantone 기반 관광지별 컬러 팔레트** (성산일출봉·만장굴·협재해수욕장 등)
- **시간대 × 날씨 25가지 다이나믹 컬러** (아침 초록 → 낮 바다파랑 → 저녁 노을)
- **위치 기반 자동 지역 감지** (제주시 / 서귀포 자동 판별)

---

## 사용 API (실제 연동 예정)

| API | 용도 |
|---|---|
| 기상청 단기예보 (data.go.kr) | 제주시·서귀포 날씨 |
| TAGO 버스도착정보 (data.go.kr) | 실시간 버스 도착 |
| OpenStreetMap | 지도 렌더링 |

---

## 로컬 실행

```bash
# 클론
git clone https://github.com/cres17/jejuflow.git
cd jejuflow

# 브라우저에서 바로 열기 (빌드 불필요)
open index.html
```

---

## 기술 스택 (MVP 데모)

- **Frontend**: Vanilla HTML/CSS/JS (단일 파일)
- **폰트**: Outfit (Google Fonts)
- **상태관리**: 순수 JS 객체
- **빌드 불필요** — `index.html` 하나로 동작

### 풀버전 계획

- React Native (Expo) — iOS/Android 동시 배포
- Zustand 상태관리
- Firebase Functions — API 키 프록시

---

## 데모 조작

우측 하단 버튼으로 시뮬레이션:

| 버튼 | 동작 |
|---|---|
| 🌤 Weather | 날씨 5단계 순환 |
| 🕐 Time of Day | 시간대 5단계 순환 (컬러 변화) |
| 📍 Region | 제주시 ↔ 서귀포 전환 |
| ⛈ Weather Alert | 폭풍 상황 시뮬레이션 |

---

## 팀

JejuFlow Team · jejuflow.app
