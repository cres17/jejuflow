# JejuFlow Setup Guide

This guide explains how to run JejuFlow locally for development.

## Requirements

- Flutter SDK
- Dart SDK
- Android Studio or VS Code
- Android SDK for Android builds
- macOS and Xcode for iOS builds
- API keys for weather, transit, tourism, and maps features

Check your local Flutter environment:

```bash
flutter doctor
```

## Install Dependencies

```bash
flutter pub get
```

## Environment File

Create a `.env` file in the project root for local development. Use `.env.example` as the template.

```env
EXPO_PUBLIC_WEATHER_API_KEY=your_weather_key
EXPO_PUBLIC_TAGO_API_KEY=your_tago_key
EXPO_PUBLIC_TOUR_API_KEY=your_tour_key
EXPO_PUBLIC_GOOGLE_MAPS_KEY=your_google_maps_key
```

Notes:

- `.env` is intentionally ignored by Git
- data.go.kr keys should usually use the decoding key
- Release builds should pass API keys through `--dart-define` or local CI secrets

## Run the App

List available devices:

```bash
flutter devices
```

Run on the selected device:

```bash
flutter run
```

For the most realistic checks, use an Android emulator, iOS simulator, or physical device. Some location and map behavior may differ on web.

## Analyze and Test

```bash
flutter analyze
flutter test
```

## Common Project Areas

| Path | Purpose |
|---|---|
| `lib/features/now` | Weather-based recommendation screen |
| `lib/features/move` | Destination and route planning screen |
| `lib/features/routes` | Saved routes screen |
| `lib/core/services` | API and local service classes |
| `lib/providers` | Riverpod provider wiring |
| `lib/shared/widgets` | Reusable UI components |
| `docs` | Product, API, setup, and release policy documents |

## Development Checklist

- Confirm `.env` exists locally or release API keys are provided with `--dart-define`
- Run `flutter pub get`
- Run `flutter analyze`
- Open the Now screen and verify recommendations load
- Open the Move screen and verify route details render
- Save a route and confirm it appears in Routes
- Test behavior with API keys missing or network unavailable

## Release Preparation

Before release, check:

- App name and icons for Android and iOS
- Location permission text
- Google Maps key restrictions
- API key exposure and secret handling
- Privacy policy URL
- Store screenshots and metadata
