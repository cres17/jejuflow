# JejuFlow — iOS Setup Guide

## Prerequisites (Mac)
- Flutter 3.x: `flutter --version`
- Xcode 15+
- CocoaPods: `sudo gem install cocoapods`

## Steps

### 1. Clone / copy this project to Mac, then:

```bash
cd jejuflow
flutter pub get
flutter create . --platforms=ios --org com.jejuflow
```

> `flutter create .` adds the missing ios/ native scaffolding.  
> It will NOT overwrite files in `lib/`.

### 2. Apply iOS config

The `ios/` files in this repo already contain the correct config:
- `ios/Runner/Info.plist` — location permission + Google Maps key
- `ios/Runner/AppDelegate.swift` — GMSServices init
- `ios/Podfile` — platform :ios, '17.0'

If `flutter create` overwrites them, restore from git.

### 3. Set Bundle ID in Xcode

Open `ios/Runner.xcworkspace` in Xcode:
- Signing & Capabilities → Bundle Identifier: `com.jejuflow.app`
- Select your Team

### 4. Install CocoaPods

```bash
cd ios && pod install && cd ..
```

### 5. Run on simulator

```bash
flutter run
```

### 6. Build for App Store

```bash
flutter build ios --release
```

Then archive and upload in Xcode → Product → Archive.

## API Keys

All keys are stored in `.env` (bundled as asset). Do NOT commit `.env` to git.

| Key | Usage |
|-----|-------|
| `EXPO_PUBLIC_WEATHER_API_KEY` | 기상청 단기예보 |
| `EXPO_PUBLIC_TAGO_API_KEY` | TAGO 버스 도착 |
| `EXPO_PUBLIC_TOUR_API_KEY` | 관광공사 사진/정보 |
| `EXPO_PUBLIC_GOOGLE_MAPS_KEY` | Google Maps iOS SDK |

## Troubleshooting

**`GoogleMaps` framework not found**  
→ Run `pod install` in `ios/` directory

**Location permission crash**  
→ Verify `NSLocationWhenInUseUsageDescription` in Info.plist

**API returns empty data**  
→ App falls back to mock data — check `.env` key values
