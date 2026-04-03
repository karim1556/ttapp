# Review 2 - Progress Update (Since Last Commit)

Date: 2026-04-03
Prepared for: Mentor update
Scope: Changes currently in working tree (frontend repo `ttapp` + backend repo `ttapp-backend`)

## 1) Change Summary at a Glance

### Frontend (`ttapp`)
- Files changed: 20 tracked files
- New files: 3
- Net diff (tracked): 859 insertions, 118 deletions

### Backend (`ttapp-backend`)
- Files changed: 10 tracked files
- New files: 3
- Net diff (tracked): 1593 insertions, 244 deletions

## 2) Frontend Updates (`ttapp`)

### A) API contract and integration updates
Files:
- `lib/core/api/api_endpoints.dart`
- `lib/core/api/api_client.dart`
- `lib/services/timetable_service.dart`
- `lib/providers/timetable_provider.dart`

What changed:
- Added support for new backend routes:
  - `POST /timetable/generate-all`
  - `GET /timetable/room/:room/weekly`
  - `GET /timetable/reports/classroom-usage`
  - `PUT /timetable/slots/:id/move`
- Endpoint corrections/alignment:
  - `profile`: `/auth/profile` -> `/profile`
  - `facultyTimetable`: `/faculty/timetable` -> `/timetable/faculty`
  - `constraintsByFaculty`: `/constraints/faculty/:id` -> `/constraints/:id`
- Added provider/service methods:
  - `generateAllTimetables(...)`
  - `moveLecture(...)`
  - `fetchRoomWeeklyTimetable(...)`
  - `fetchClassroomUsageReport(...)`
- DIO request/response logging made debug-only (`kDebugMode`) to reduce production log noise.

### B) Timetable screen and admin UX upgrades
Files:
- `lib/features/timetable/screens/timetable_screen.dart`
- `lib/features/admin/screens/admin_panel_screen.dart`
- `lib/navigation/app_router.dart`
- `lib/features/admin/screens/room_reports_screen.dart` (new)

What changed:
- Added admin drag-and-drop edit mode in weekly timetable view:
  - Long-press drag source lecture
  - Drop into target slot
  - Uses backend move/swap API
- Added CSV export action from timetable screen (shareable Excel-compatible CSV).
- Kept PDF export and upgraded export experience.
- Added admin action: "Generate All Classes (Single Click)".
- Added new admin route/screen: room-wise timetable + room usage analytics.

### C) Export improvements (PDF + CSV)
Files:
- `lib/services/timetable_export_service.dart`
- `test/timetable_export_service_test.dart` (new)

What changed:
- PDF redesign to premium layout:
  - branded header
  - generated timestamp
  - summary metric cards
  - cleaner table styling
  - legend row
- CSV export implemented (`buildTimetableCsv`) with proper escaping.
- Added tests for:
  - CSV contains subject/faculty/room data
  - PDF export returns non-empty bytes

### D) Weekday policy and base URL defaults
Files:
- `lib/core/constants/app_constants.dart`

What changed:
- Removed Saturday from main day constants used by app timetable flow.
- Updated default LAN API URL fallback to `http://192.168.0.117:3000/api`.

### E) Dependency/platform updates
Files:
- `pubspec.yaml`
- `pubspec.lock`
- generated plugin registrant files for Linux/macOS/Windows

What changed:
- Added direct dependencies:
  - `path_provider`
  - `share_plus`
- Regenerated plugin registrants for desktop targets.

## 3) Backend Updates (`ttapp-backend`)

### A) Scheduler engine overhaul + policy enforcement
File:
- `src/services/timetable.service.js`

What changed:
- Reworked generation logic to multi-attempt optimized scheduling.
- Added post-generation compaction to reduce internal timetable gaps.
- Global working days switched to Monday-Friday.
- Enforced per-class per-day lab cap:
  - Maximum one lab block/day/class
  - Lab block represented as 2 consecutive slots
- Room-aware placement integrated into scheduling.

### B) Timetable APIs and conflict-safe editing
Files:
- `src/controllers/timetable.controller.js`
- `src/routes/timetable.routes.js`

What changed:
- Added new APIs:
  - `POST /api/timetable/generate-all`
  - `GET /api/timetable/room/:roomNumber/weekly`
  - `GET /api/timetable/reports/classroom-usage`
  - `PUT /api/timetable/slots/:id/move`
- Updated weekly flows to 5-day output behavior.
- Added strict conflict checks for manual changes:
  - faculty conflict prevention
  - room conflict prevention
- Move/swap endpoint includes transactional updates with conflict validation.

### C) Security and platform hardening
Files:
- `src/app.js`
- `package.json`
- `package-lock.json`
- `.env.example`

What changed:
- Added `helmet` middleware.
- Added API rate limiting (`express-rate-limit`).
- Added CORS allowlist parsing from environment.
- Added related env defaults (`CORS_ORIGIN`, `RATE_LIMIT_MAX`).

### D) Auth/constraints quality improvements
Files:
- `src/controllers/auth.controller.js`
- `src/routes/auth.routes.js`
- `src/controllers/constraint.controller.js`

What changed:
- Added logout API handler (`POST /api/auth/logout`).
- Constraint APIs now resolve faculty by `faculty_id` or `uid`.
- Constraint create flow changed to upsert semantics.

### E) Operational scripts added
Files:
- `scripts/reset_seed_even_sem.js` (new)
- `scripts/full_flow_check_even_sem.js` (new)
- `scripts/make_sem4_timetable_ab.js` (new)

What changed:
- Reset/seed script:
  - preserves admin
  - clears non-admin/domain data
  - seeds rooms, time slots, faculty, constraints, even-sem subjects
- Full-flow script:
  - login
  - generate-all
  - verify weekly integrity
  - verify room APIs
  - assert Mon-Fri and lab duration constraints
- Sem 4 focused script:
  - seeds provided sem-4 subjects for Div A/B
  - runs generation
  - verifies no conflicts, 9-5 bounds, continuity, and max daily lab block rule

## 4) Validation and Build Evidence

Executed and verified:
- Backend sem-4 generation:
  - `classCount: 2`
  - `slotsAssigned: 52`
  - `unplacedLectures: 0`
  - `maxLabSlotsInDay: 2`
  - `worstInternalGapSlots: 0`
- Backend full even-sem flow check:
  - PASS
  - classes validated: 12
  - semester set: 2, 4, 6, 8
  - divisions: A, B, C
  - unplaced lectures: 0
- Frontend tests:
  - `flutter test test/timetable_export_service_test.dart` -> PASS
- Frontend analyzer:
  - `flutter analyze lib/services/timetable_export_service.dart` -> PASS
- Fresh Android release build:
  - artifact: `build/app/outputs/flutter-apk/app-release.apk`
  - size: ~55 MB
  - SHA-256: `5a53a9b65313bf77025b9f3834fb52e0086926e8adcbed171e7f298e996948d3`

## 5) Important Pending Cleanup Before Final Commit

### In frontend repo (`ttapp`)
- Deleted tracked file:
  - `android/app/src/main/kotlin/com/ttapp/ttapp/MainActivity.kt`
- New duplicate/unwanted file:
  - `lib/services/timetable_export_service 2.dart`

These should be reviewed and resolved before final commit to avoid runtime/package confusion.

## 6) Full Changed File List (Current Working Tree)

### Frontend tracked changes
- `android/app/src/main/kotlin/com/ttapp/ttapp/MainActivity.kt` (deleted)
- `lib/core/api/api_client.dart`
- `lib/core/api/api_endpoints.dart`
- `lib/core/constants/app_constants.dart`
- `lib/features/admin/screens/admin_panel_screen.dart`
- `lib/features/timetable/screens/timetable_screen.dart`
- `lib/navigation/app_router.dart`
- `lib/providers/timetable_provider.dart`
- `lib/services/faculty_service.dart`
- `lib/services/holiday_service.dart`
- `lib/services/subject_service.dart`
- `lib/services/timetable_export_service.dart`
- `lib/services/timetable_service.dart`
- `linux/flutter/generated_plugin_registrant.cc`
- `linux/flutter/generated_plugins.cmake`
- `macos/Flutter/GeneratedPluginRegistrant.swift`
- `pubspec.lock`
- `pubspec.yaml`
- `windows/flutter/generated_plugin_registrant.cc`
- `windows/flutter/generated_plugins.cmake`

### Frontend untracked files
- `lib/features/admin/screens/room_reports_screen.dart`
- `lib/services/timetable_export_service 2.dart`
- `test/timetable_export_service_test.dart`

### Backend tracked changes
- `.env.example`
- `package-lock.json`
- `package.json`
- `src/app.js`
- `src/controllers/auth.controller.js`
- `src/controllers/constraint.controller.js`
- `src/controllers/timetable.controller.js`
- `src/routes/auth.routes.js`
- `src/routes/timetable.routes.js`
- `src/services/timetable.service.js`

### Backend untracked files
- `scripts/full_flow_check_even_sem.js`
- `scripts/make_sem4_timetable_ab.js`
- `scripts/reset_seed_even_sem.js`

---
This document reflects current working changes after the last commit and before final cleanup/commit.
