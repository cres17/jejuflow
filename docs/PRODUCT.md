# JejuFlow Product Overview

JejuFlow is a mobile travel app for people visiting Jeju Island. The app answers a common travel question:

> Where should I go next, considering the weather and the bus options available right now?

The goal is to reduce planning friction for travelers who want a simple, practical recommendation instead of switching between weather apps, map apps, tourism sites, and bus information services.

## Target Users

- Travelers visiting Jeju without a rental car
- Visitors who prefer public transportation
- Solo travelers or small groups making plans during the day
- International travelers who need clear, simple destination information
- Users who want weather-aware indoor and outdoor recommendations

## Core Value

JejuFlow connects three types of information:

| Information | Why It Matters |
|---|---|
| Weather | Jeju weather can change quickly, so outdoor plans may need alternatives |
| Transit | Many visitors rely on buses and need realistic travel timing |
| Attractions | Users need destination options that fit the current situation |

By combining these signals, JejuFlow recommends places that are easier to choose and easier to reach.

## Main Features

### Weather-Based Recommendations

The app checks the selected region's weather and recommends suitable places. Outdoor attractions are prioritized in clear weather, while indoor or mixed-use places are preferred during rain, strong wind, or storms.

### Transit-Friendly Destination Cards

Destination cards can show nearby stops, bus routes, estimated waiting time, and walking information. This keeps the recommendation practical rather than purely inspirational.

### Route Saving

Users can save routes and return to them later. Saved outdoor routes can show warnings when the current weather makes them less suitable.

### Tourism Information

The app uses public tourism data where available and keeps static fallback data so the experience does not become empty when a network request fails.

### Multilingual Direction

The current structure is prepared for English-centered travel guidance and can be expanded to Korean, Japanese, and Chinese.

## App Structure

| Screen | Role |
|---|---|
| Now | Quick recommendations based on weather and region |
| Move | Destination browsing and route details |
| Routes | Saved route management |
| Settings | Preferences and app-level settings |

## Success Criteria

- Users can open the app and see relevant Jeju recommendations quickly
- Poor weather leads to indoor or safer alternatives
- Route information remains understandable and practical
- API failures are handled with cache, fallback data, or empty states
- The app remains usable on common mobile screen sizes

## Future Improvements

- More detailed multilingual content
- Better route comparison and transfer guidance
- Personalized recommendations based on saved places
- Offline-friendly cached tourism information
- Store-ready privacy policy, screenshots, and release metadata
