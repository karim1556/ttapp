# TT Manager (ttapp)

AI Automated College Timetable Management System — a Flutter app to create,
manage, and distribute college timetables for administrators, teachers,
and students.

Summary
- Mobile-first Flutter application using Riverpod for state management,
	GoRouter for navigation, Hive for local storage, Dio for HTTP, and
	optional Firebase push notifications.

Key capabilities
- Create and manage timetables (theory, lab, extra sessions).
- Role-based users: Admin, Teacher, Student.
- Export timetables to PDF and print using the `pdf` and `printing` packages.
- Offline-first local persistence with `hive` and secure values in
	`flutter_secure_storage`.

Quick start
1. Clone the repository:

```bash
git clone <repo-url>
cd ttapp
```

2. Install dependencies:

```bash
flutter pub get
```

3. Run on Android emulator/device:

```bash
flutter run -d android
```

Configuration notes (project-specific)
- App name shown in code: `TT Manager` (see `lib/core/constants/app_constants.dart`).
- Backend API base URL defaults to the value in `AppConstants.baseUrl`.
	Change it at runtime in the app Profile → Server URL, or update
	`lib/core/constants/app_constants.dart` for development.
- Hive boxes opened at startup: `userBox`, `timetableBox`, `settingsBox` (see `lib/main.dart`).
- Android Firebase config: `android/app/google-services.json` exists.
	iOS Firebase config is not included — add `GoogleService-Info.plist` to
	`ios/Runner/` if using Firebase on iOS.
- Firebase initialization is optional — the app will run without push
	notifications if Firebase isn't configured.

Developer notes
- Main entry: `lib/main.dart` (app initializes Hive and optional Firebase).
- State management: `flutter_riverpod` (providers live under `lib/providers`).
- Routing: `lib/navigation/app_router.dart`.

Build & tests
- Run unit/widget tests:

```bash
flutter test
```

- Build release APK:

```bash
flutter build apk --release
```

How you can help / Contributing
- Open issues for bugs or feature requests.
- Create a branch, implement changes, and open a pull request.

Notes
- Keep API keys and production credentials out of source control.
- If you want, I can update the README with screenshots, an architecture
	diagram, or CI/CD steps — tell me which you'd prefer.

