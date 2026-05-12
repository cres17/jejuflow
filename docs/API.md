# JejuFlow API Guide

JejuFlow uses public data APIs for weather, public transportation, and tourism content. The app is designed to keep working with cached or fallback data when one of these services is unavailable.

## Environment Variables

Create a `.env` file in the project root for local development. Use `.env.example` as the template.

```env
EXPO_PUBLIC_WEATHER_API_KEY=
EXPO_PUBLIC_TAGO_API_KEY=
EXPO_PUBLIC_TOUR_API_KEY=
EXPO_PUBLIC_GOOGLE_MAPS_KEY=
```

The variable names keep the existing `EXPO_PUBLIC_` prefix for compatibility with earlier project files, even though the main app is Flutter-based.

Do not commit `.env` to Git.

For release builds, provide the same keys through `--dart-define`, `--dart-define-from-file=.env`, or CI secrets instead of bundling a committed `.env` file.

## API Keys

API keys are read through `lib/core/constants/api_keys.dart`.

| Key | Used For |
|---|---|
| `EXPO_PUBLIC_WEATHER_API_KEY` | Korea Meteorological Administration village forecast |
| `EXPO_PUBLIC_TAGO_API_KEY` | TAGO bus arrival and route information |
| `EXPO_PUBLIC_TOUR_API_KEY` | Korea Tourism Organization TourAPI |
| `EXPO_PUBLIC_GOOGLE_MAPS_KEY` | Google Maps platform features |

For data.go.kr services, use a decoding key unless a specific endpoint requires otherwise.

## Services

| Service | Main File | Purpose |
|---|---|---|
| Weather | `lib/core/services/weather_service.dart` | Weather state, forecast, and weather theme selection |
| Transit | `lib/core/services/transit_service.dart` | Bus arrivals and route details |
| Tourism | `lib/core/services/tour_service.dart` | Places, images, related attractions, and detail information |
| Cache | `lib/core/services/cache_service.dart` | Local cache and stale data fallback |

## Weather API

The weather service uses the Korea Meteorological Administration village forecast API.

Typical usage:

- Determine clear, cloudy, rainy, windy, or stormy conditions
- Select weather-aware recommendation filters
- Apply weather colors and messages in the UI
- Warn users when saved outdoor routes may be affected

Fallback behavior:

- Use cached weather when available
- Use a basic clear-weather fallback when no data exists
- Avoid blocking the entire screen on request failure

## TAGO Transit API

The transit service uses TAGO public transportation endpoints.

Typical usage:

- Show bus arrival estimates near a destination
- Display bus route names and waiting times
- Support route steps in the Move screen

Fallback behavior:

- Use stale cache when available
- Return an empty list when no arrival data exists
- Keep destination cards visible even without live bus data

## TourAPI

TourAPI provides tourism place lists, detail information, images, and related destination data.

Typical usage:

- Load Jeju attractions, restaurants, and cafes
- Show attraction photos and descriptions
- Add related-place recommendations
- Support fallback static destination data

Fallback behavior:

- Use local static spots when API calls fail
- Hide optional image or related-place sections when data is missing
- Keep core recommendations available through bundled data

## Provider Layer

The provider layer lives in `lib/providers/app_providers.dart`.

| Provider | Purpose |
|---|---|
| `weatherProvider(region)` | Loads weather for a selected region |
| `currentWeatherProvider` | Provides the current selected region's weather |
| `busArrivalsProvider(stopId)` | Loads bus arrivals for a stop |
| `placeListProvider(type)` | Loads places by type |
| `weatherSpotsProvider` | Builds weather-aware recommendations |
| `savedRoutesProvider` | Manages saved route persistence |

## Error Handling Principles

- Never expose raw API errors as the main user experience
- Prefer cached data over an empty screen
- Use local fallback data for key destination lists
- Make optional sections disappear gracefully when data is unavailable
