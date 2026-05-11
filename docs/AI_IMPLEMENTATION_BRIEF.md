# JejuFlow AI Implementation Brief

This document gives AI coding assistants and future contributors a compact overview of how to work in the JejuFlow codebase.

## Product Summary

JejuFlow is a Flutter app that recommends Jeju Island destinations based on weather, tourism data, and public transit information.

The main user question is:

> Where can I go next in Jeju, given the current weather and bus options?

## Implementation Principles

- Keep the existing Flutter and Riverpod structure
- Prefer small, focused changes over broad rewrites
- Keep the Now, Move, Routes, and Settings screens easy to understand
- Use cached or fallback data when public APIs fail
- Avoid exposing raw API errors to end users
- Keep API keys in `.env`, never in source code

## Current Architecture

```text
lib/
  main.dart
  app.dart
  providers/
    app_providers.dart
  core/
    constants/
    models/
    services/
    utils/
  features/
    now/
    move/
    routes/
    settings/
  shared/
    widgets/
```

## Important Areas

| Area | Notes |
|---|---|
| `lib/core/services` | API clients, cache services, and data loading |
| `lib/providers/app_providers.dart` | Riverpod wiring for screen data |
| `lib/core/constants/spot_data.dart` | Static fallback places |
| `lib/features/now` | Weather-aware recommendation experience |
| `lib/features/move` | Destination browsing and route planning |
| `lib/features/routes` | Saved route management |
| `lib/shared/widgets` | Reusable UI components |

## Data Sources

| Source | Use |
|---|---|
| Korea Meteorological Administration | Weather and forecast state |
| TAGO | Bus arrival and route information |
| Korea Tourism Organization TourAPI | Tourism places, images, and details |
| Local fallback data | Basic app continuity when APIs fail |

## UI Expectations

- Keep screens mobile-first
- Make destination cards scannable
- Show practical details such as time, weather suitability, and transit options
- Prefer clear empty states over broken UI
- Keep text concise and friendly

## Safe Change Checklist

Before finishing a code change:

- Run `flutter analyze` when possible
- Run relevant tests when available
- Check that screens still render with missing API data
- Confirm `.env` and generated files are not committed
- Keep documentation updated when setup or API behavior changes

## Common Tasks

### Add a new public API call

1. Add the service method under `lib/core/services`
2. Add or update a model under `lib/core/models`
3. Wire the service through `lib/providers/app_providers.dart`
4. Add cache or fallback behavior
5. Update `docs/API.md`

### Add a new recommendation rule

1. Check weather utilities and spot metadata
2. Add the rule near the existing recommendation logic
3. Keep the UI explanation short
4. Make sure bad weather still produces useful alternatives

### Add a new screen section

1. Reuse existing shared widgets where possible
2. Keep the section responsive on small screens
3. Provide loading, empty, and error states
4. Avoid adding unrelated visual styles
