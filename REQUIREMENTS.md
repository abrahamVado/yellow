# yellow (Client App) Requirements

This is a Flutter application typically used as the Client/Passenger App.

## Configuration Files

### Firebase
Required for Authentication and Cloud Messaging.
- **Android**: Place `google-services.json` in `android/app/`.
- **iOS**: Place `GoogleService-Info.plist` in `ios/Runner/`.

### Google Maps & Places
- **Android**: Add API Key to `android/app/src/main/AndroidManifest.xml` (meta-data `com.google.android.geo.API_KEY`).
- **iOS**: Add API Key to `ios/Runner/AppDelegate.swift` or `Info.plist`.
- **Google Places SDK**: This app uses `flutter_google_places_sdk`, which requires native setup for the Places API Key if distinct from Maps.

## Payments
- **Google Pay / Apple Pay**: Requires Merchant ID configuration in the `pay` package setup files (typically in `assets/default_payment_profile/` or code constants).

## System Permissions (Runtime)
The app requires the following permissions to be granted on the device:
- **Location**: `ACCESS_FINE_LOCATION` (For pickup/dropoff selection).
- **Notifications**: For trip updates.
- **Storage/Camera**: For profile picture uploads.

## Dependencies
- **Flutter SDK**: Version 3.10.1+ (as per `pubspec.yaml`).
- **CocoaPods** (for iOS builds).

## Backend
- Ensure the backend API (Yamato-Go-Gin-API) is reachable.

## Setup Instructions

### 1. Firebase Configuration
1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Create or select your project.
3. **Android**:
   - Add Android app (Package Name: check `android/app/build.gradle`).
   - Download `google-services.json`.
   - Place in `c:\workspace\20k\yellow\android\app\google-services.json`.
4. **iOS**:
   - Add iOS app (Bundle ID: check Xcode project).
   - Download `GoogleService-Info.plist`.
   - Place in `c:\workspace\20k\yellow\ios\Runner\GoogleService-Info.plist`.

### 2. Google Maps & Places API Keys
1. Go to the [Google Cloud Console](https://console.cloud.google.com/).
2. Create/Select project working with Firebase.
3. **Enable APIs**:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Places API (New) or Places API
   - Geocoding API
4. **Create API Keys**:
   - **Android Key**: Restrict to Android App (Package Name + SHA-1). Update `AndroidManifest.xml`.
   - **iOS Key**: Restrict to iOS App (Bundle ID). Update `AppDelegate.swift`/`Info.plist`.
5. **Important**: Ensure **Places API** is enabled for the keys used in the app, as `flutter_google_places_sdk` relies on it.

### 3. Payments (Google Pay)
1. Go to [Google Pay & Wallet Console](https://pay.google.com/business/console/).
2. Create a Business Profile and get your **Merchant ID**.
3. Update the payment profile JSON files in `assets/default_payment_profile/` with your Merchant ID and Gateway configuration.

### 4. Generate SHA-1
- Run `cd android` and `./gradlew signingReport`.
- Add the SHA-1 to Firebase Project Settings and Google Cloud Console API Key restrictions.
