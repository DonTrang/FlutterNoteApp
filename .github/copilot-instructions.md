<!-- Copilot / AI agent instructions for flutter_application_1 -->

# Purpose
This file gives practical, codebase-specific instructions for AI coding agents working on this repository (a Flutter multi-platform app).

## Quick tasks & commands
- **Install deps:** `flutter pub get`
- **Run on Windows (dev):** `flutter run -d windows`
- **Run on Android (dev):** `flutter run -d chrome` or `flutter run -d <android-device-id>`
- **Build APK (release):** `flutter build apk`
- **Run unit/widget tests:** `flutter test` or `flutter test test/widget_test.dart`
- **Analyze/lint:** `flutter analyze`
- **Use Gradle directly (Windows):** `cd android; .\gradlew.bat assembleRelease`

## Big-picture architecture
- This is a standard Flutter app scaffold (see `lib/main.dart`) targeting multiple platforms: `android/`, `ios/`, `windows/`, `linux/`, `macos/`, and `web/`.
- UI & app logic: `lib/` — `main.dart` is the app entrypoint and is imported by tests (`test/widget_test.dart`).
- Platform integration: platform-specific glue and plugin registrants live under each platform folder (e.g., `android/`, `ios/Runner/`, `windows/runner`).

## Project-specific conventions & patterns
- Linting: project uses `package:flutter_lints` configured in `analysis_options.yaml` — follow those style rules.
- Dependencies & assets are declared in `pubspec.yaml`. The project uses `uses-material-design: true` by default.
- Android uses Gradle Kotlin DSL (`android/app/build.gradle.kts`) and obtains compile/min/target SDK versions from the Flutter-managed `flutter` block (do not hardcode values without checking root `gradle.properties` or Flutter config).
- Java/Kotlin target: project compiles with Java 17 (see `compileOptions` / `kotlinOptions` in `android/app/build.gradle.kts`).

## Integration points and generated files
- Plugin registration and generated platform code live in platform-specific generated files (e.g., `android/app/src/main/.../GeneratedPluginRegistrant.*`, `ios/Runner/GeneratedPluginRegistrant.*`, `windows/.../generated_plugin_registrant.*`). Avoid editing generated registrant files; instead add plugins via `pubspec.yaml`.
- Native build config: `android/` and `ios/` subfolders — use `gradlew` / Xcode for platform-specific tasks when needed.

## Tests & examples
- A basic widget test exists at `test/widget_test.dart` that imports `lib/main.dart`. Use it as a template for widget tests and integration tests.
- To run tests locally: `flutter test`.

## Common developer workflows
- Local dev cycle: `flutter pub get` → `flutter run -d <device>` → make changes → press `r` for hot reload or `R` for hot restart.
- Release build (Android): typically `flutter build apk` or `cd android && .\gradlew.bat assembleRelease` on Windows.

## Files to check before making platform changes
- `pubspec.yaml`: versions, assets, package name.
- `android/app/build.gradle.kts`: Android `applicationId`, minSdk/targetSdk (sourced from `flutter` block), signing config.
- `ios/Runner/Info.plist` and `Runner.xcodeproj`: iOS bundle identifiers and entitlements.

## Notes & gotchas observed
- This repo appears to be the default Flutter template; be conservative about changing project structure without tests or CI.
- Generated files under `ios/`, `android/`, `windows/`, `linux/`, `macos/` should not be edited directly — instead change the Dart code or plugin declarations.
- If adding native dependencies, update platform build files and test a full platform build (use the platform's native tooling when debugging platform-specific issues).

## When in doubt — quick checklist for PRs
- Ensure `flutter analyze` passes.
- Run `flutter test` and verify widget tests pass.
- If touching Android/iOS native code, run a local platform build (`flutter build apk` / `flutter build ios`).

---
If you'd like changes, tell me what to emphasize or any missing workflows to include and I'll update this file.
