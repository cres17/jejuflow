# JejuFlow iOS Setup

This guide covers the basic steps for running and preparing JejuFlow on iOS.

## Requirements

- macOS
- Xcode 15 or later
- Flutter 3.x
- CocoaPods

Check Flutter first:

```bash
flutter --version
flutter doctor
```

Install CocoaPods if needed:

```bash
sudo gem install cocoapods
```

## Prepare the Project

From the project root:

```bash
flutter pub get
flutter create . --platforms=ios --org com.jejuflow
```

`flutter create .` restores missing native iOS scaffolding when needed. It should not replace the Dart application code under `lib/`.

## iOS Configuration

Important files:

| File | Purpose |
|---|---|
| `ios/Runner/Info.plist` | Location permission text and iOS app settings |
| `ios/Runner/AppDelegate.swift` | Native startup configuration |
| `ios/Podfile` | CocoaPods and iOS deployment target |

If generated files overwrite project-specific settings, restore the intended version from Git.

## Bundle Identifier

Open the workspace in Xcode:

```bash
open ios/Runner.xcworkspace
```

In Signing & Capabilities:

- Set the bundle identifier, for example `com.jejuflow.app`
- Select the correct Apple Developer Team
- Confirm signing works for the target device or simulator

## Install Pods

```bash
cd ios
pod install
cd ..
```

## Run on iOS

```bash
flutter run
```

## Build for Release

```bash
flutter build ios --release
```

For App Store distribution, open Xcode and use Product > Archive.

## API Keys

Runtime keys are loaded from `.env`.

| Key | Purpose |
|---|---|
| `EXPO_PUBLIC_WEATHER_API_KEY` | Weather forecast data |
| `EXPO_PUBLIC_TAGO_API_KEY` | Bus arrival and route data |
| `EXPO_PUBLIC_TOUR_API_KEY` | Tourism place and image data |
| `EXPO_PUBLIC_GOOGLE_MAPS_KEY` | Google Maps features |

Do not commit `.env` or signing credentials.

## Troubleshooting

| Problem | Check |
|---|---|
| Google Maps does not load | Confirm the iOS API key and bundle restriction |
| Location prompt does not appear | Check `NSLocationWhenInUseUsageDescription` in `Info.plist` |
| Pods fail to install | Run `pod repo update`, then `pod install` again |
| API data is empty | Confirm `.env` values and data.go.kr key type |
