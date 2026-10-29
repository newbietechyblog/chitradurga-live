# Chitradurga Live: native Android app (Flutter)

Milestone 1: app shell with the live news feed from chitradurgalive.com.
Community, polls, calendar, profiles and alerts come in later milestones.

**Status:** this code has not been compiled yet. It was written without access to the Flutter SDK, so the first build may show small errors. Send them back and they will be fixed.

## Set up (on a Windows or Mac computer)

1. Install **Flutter** (flutter.dev/docs/get-started/install) and **Android Studio** (for the Android build tools).
2. Turn on **Developer options** on your Android phone and enable **USB debugging**.
3. Open a terminal in an empty folder and run:
   ```
   flutter create chitradurga_live
   ```
4. Replace the generated `pubspec.yaml` and `lib` folder with the ones in this package.
5. In the `chitradurga_live` folder, run:
   ```
   flutter pub get
   flutter run
   ```
   This installs the app on your connected phone.

## Build an installable file for testing

```
flutter build apk --release
```

The file is at `build/app/outputs/flutter-apk/app-release.apk`. Copy it to the phone and install it.

## Publishing (later)

- Create a **signing key** and keep it safe. Google Play needs the same key for every future update.
- Build an app bundle: `flutter build appbundle --release`, then upload it in the Play Console.
- Google Play requires the privacy policy, account deletion and content reporting that are already part of the web app.

## Files

```
lib/
  main.dart                  App theme and start screen
  config.dart                Website address and page size
  models/post.dart           News article data and time formatting
  services/wp_api.dart       Talks to the WordPress site
  screens/home_screen.dart   News feed (lead story, rows, refresh, load more)
```
