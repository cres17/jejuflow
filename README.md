<h1 align="center">JejuFlow</h1>

<p align="center">
  Weather-aware travel recommendations for Jeju Island.
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white" />
  <img alt="Dart" src="https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white" />
  <img alt="Platform" src="https://img.shields.io/badge/Platform-iOS%20%7C%20Android-lightgrey?style=flat-square" />
</p>

JejuFlow is a travel assistant for Jeju Island. It helps visitors decide where to go next by combining weather, nearby attractions, public transit information, and saved routes in one simple app.

## Overview

JejuFlow focuses on one practical travel moment: choosing the next place to visit. Instead of asking users to compare weather, bus arrivals, and tourism pages separately, the app brings those signals together and presents travel-ready options.

## What It Does

- Recommends Jeju attractions based on current weather and region
- Shows bus arrival and route information for selected places
- Helps users save and revisit travel routes
- Suggests indoor alternatives when the weather is poor
- Provides a clean mobile-first interface for quick travel decisions

## Main Screens

| Screen | Description |
|---|---|
| Now | Shows current weather, nearby recommendations, and quick travel suggestions |
| Move | Lets users browse destinations and check transit-friendly routes |
| Routes | Stores saved routes and highlights routes affected by weather |
| Settings | Provides app preferences and language-related options |

## Tech Stack

- Flutter
- Dart
- Riverpod
- Dio
- Hive
- Google Maps
- TourAPI, TAGO, and Korea Meteorological Administration APIs

## Getting Started

```bash
git clone https://github.com/cres17/jejuflow.git
cd jejuflow
flutter pub get
flutter run
```

Create a `.env` file in the project root before running API-backed features. Use `.env.example` as the template and keep real keys local.

```env
EXPO_PUBLIC_WEATHER_API_KEY=
EXPO_PUBLIC_TAGO_API_KEY=
EXPO_PUBLIC_TOUR_API_KEY=
EXPO_PUBLIC_GOOGLE_MAPS_KEY=
```

## Documentation

| Document | Purpose |
|---|---|
| [Play Console Notes](docs/PLAY_CONSOLE_SUBMISSION.md) | Android release policy and app content answers |
| [Privacy Policy](docs/PRIVACY_POLICY.md) | Privacy policy draft for release |

## Repository Notes

Generated files, local IDE settings, build outputs, and API secrets are excluded from Git. Keep `.env`, signing keys, and platform-specific secrets out of commits.

## License

This project is currently maintained as a JejuFlow application prototype.
