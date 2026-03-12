# TT Manager — Comprehensive Project Report
### AI-Automated College Timetable Management System
#### Prepared for Viva / External Examination

---

## Table of Contents

1. [Project Overview & Problem Statement](#1-project-overview--problem-statement)
2. [System Architecture](#2-system-architecture)
3. [Technology Stack](#3-technology-stack)
4. [Frontend — Flutter App](#4-frontend--flutter-app)
   - 4.1 [App Entry Point & Startup](#41-app-entry-point--startup)
   - 4.2 [State Management — Riverpod](#42-state-management--riverpod)
   - 4.3 [Navigation — GoRouter](#43-navigation--gorouter)
   - 4.4 [Screens & Features](#44-screens--features)
   - 4.5 [Data Models](#45-data-models)
   - 4.6 [Services Layer](#46-services-layer)
   - 4.7 [Local Storage Strategy](#47-local-storage-strategy)
   - 4.8 [Push Notifications](#48-push-notifications)
   - 4.9 [PDF Export](#49-pdf-export)
   - 4.10 [Theme & UI System](#410-theme--ui-system)
5. [Backend — REST API](#5-backend--rest-api)
   - 5.1 [API Client Architecture](#51-api-client-architecture)
   - 5.2 [Authentication & Security](#52-authentication--security)
   - 5.3 [Complete API Endpoints Reference](#53-complete-api-endpoints-reference)
6. [Core Domain Logic — Timetable Generation](#6-core-domain-logic--timetable-generation)
   - 6.1 [Constraints Engine](#61-constraints-engine)
   - 6.2 [How the Scheduler Works](#62-how-the-scheduler-works)
7. [Role-Based Access Control (RBAC)](#7-role-based-access-control-rbac)
8. [COPO — Course Outcome & Programme Outcome](#8-copo--course-outcome--programme-outcome)
9. [Data Flow Diagrams](#9-data-flow-diagrams)
10. [Database Schema (Inferred)](#10-database-schema-inferred)
11. [Security Implementation](#11-security-implementation)
12. [Feature Completeness Matrix](#12-feature-completeness-matrix)
13. [Possible Viva Questions & Answers](#13-possible-viva-questions--answers)

---

## 1. Project Overview & Problem Statement

### What Problem Are We Solving?

College timetable management is traditionally a **manual, error-prone, and time-consuming** process. Scheduling coordinators must:

- Assign each subject to a faculty member
- Ensure no faculty member is double-booked at the same time
- Respect faculty preferences and unavailability windows
- Respect per-faculty maximum lecture limits (per day and per week)
- Accommodate lab practicals that require specific rooms
- Keep room allocations conflict-free
- Regenerate the entire schedule every semester
- Notify faculty of changes (substitutions, extras)

Manual scheduling of even a medium-sized department (15–20 faculty, 8–10 subjects per semester, 6 divisions) can take **days** and still produces conflicts.

### Our Solution

**TT Manager** is a cross-platform mobile application (Android + iOS) backed by a Node.js REST API that:

1. **Stores** all entities — faculty, subjects, rooms, time slots, holidays
2. **Collects** faculty constraints (unavailability, preferred slots, max load)
3. **Auto-generates** a conflict-free weekly timetable via a backend scheduling algorithm
4. **Displays** the result in a clean, role-specific UI
5. **Notifies** users of changes via Firebase Cloud Messaging (FCM)
6. **Exports** the timetable to PDF for printing and distribution
7. **Maps** courses to outcomes (COPO) for accreditation compliance

### Project Name Breakdown
- **TT** = Time Table
- **App** = Mobile Application
- Display name in the app: **TT Manager**

---

## 2. System Architecture

```
┌────────────────────────────────────────────────────────┐
│                   FLUTTER APP (Frontend)               │
│                                                        │
│  ┌──────────┐  ┌─────────────┐  ┌──────────────────┐  │
│  │  Screens │→ │  Providers  │→ │    Services       │  │
│  │ (UI/UX)  │  │  (Riverpod) │  │ (Business Logic)  │  │
│  └──────────┘  └─────────────┘  └──────────────────┘  │
│                                         ↓              │
│                                   ┌──────────┐         │
│                                   │ApiClient │         │
│                                   │  (Dio)   │         │
│                                   └──────────┘         │
└─────────────────────────────────────────┬──────────────┘
                                          │ HTTP/REST (JSON)
                                          ↓
┌─────────────────────────────────────────┴──────────────┐
│              NODE.JS BACKEND (REST API)                 │
│                 Base URL: /api                          │
│                                                        │
│  ┌────────────┐  ┌───────────────┐  ┌───────────────┐  │
│  │Auth Routes │  │Timetable Gen  │  │ All Other     │  │
│  │JWT Tokens  │  │  (Scheduler)  │  │ CRUD Routes   │  │
│  └────────────┘  └───────────────┘  └───────────────┘  │
│                         ↓                              │
│                   ┌──────────┐                         │
│                   │ DATABASE │                         │
│                   │  (SQL)   │                         │
│                   └──────────┘                         │
└────────────────────────────────────────────────────────┘

Local Storage (on device):
  ├── Hive (NoSQL)       → Timetable cache, user data, settings
  └── FlutterSecureStorage → JWT token, FCM token

Push Notifications:
  Firebase Cloud Messaging (FCM) → Firebase Console → Device
```

### Architecture Pattern
The frontend follows a **layered architecture**:

| Layer | Responsibility | Technologies |
|---|---|---|
| Presentation | UI screens, widgets | Flutter, Material 3 |
| State | App state, reactivity | Riverpod (StateNotifier) |
| Service | API calls, business logic | Dart classes, Dio |
| Data | Models, serialization | Plain Dart classes (`fromJson`/`toJson`) |
| Storage | Caching, persistence | Hive, FlutterSecureStorage |
| Navigation | Routing, guards | GoRouter |

---

## 3. Technology Stack

### Frontend
| Technology | Version | Purpose |
|---|---|---|
| **Flutter** | SDK ^3.10.8 | Cross-platform UI framework |
| **Dart** | (bundled with Flutter) | Programming language |
| **flutter_riverpod** | ^2.5.1 | State management |
| **go_router** | ^14.2.7 | Declarative navigation with redirect guards |
| **dio** | ^5.4.3+1 | HTTP client with interceptors |
| **hive** + **hive_flutter** | ^2.2.3 / ^1.1.0 | Local NoSQL database (offline cache) |
| **flutter_secure_storage** | ^9.2.2 | Secure keychain/keystore for JWT tokens |
| **firebase_core** | ^3.3.0 | Firebase initialization |
| **firebase_messaging** | ^15.1.0 | Push notifications (FCM) |
| **flutter_local_notifications** | ^17.2.2 | Foreground notification display |
| **pdf** | ^3.10.8 | PDF generation |
| **printing** | ^5.12.0 | Print/share PDF |
| **google_fonts** | ^6.2.1 | Poppins typography |
| **intl** | ^0.19.0 | Date/time formatting |
| **shimmer** | ^3.0.0 | Loading skeleton animations |
| **cached_network_image** | ^3.3.1 | Image caching |
| **image_picker** | ^1.1.2 | Photo selection |

### Backend (consumed by the app)
| Technology | Purpose |
|---|---|
| **Node.js** | Runtime environment |
| **REST API** | JSON over HTTP |
| **JWT (Bearer Token)** | Authentication |
| **SQL Database** | Persistent data |
| **Firebase Admin SDK** | Push notifications |

### DevOps / Build
| Technology | Purpose |
|---|---|
| **Gradle (Kotlin DSL)** | Android build system |
| **Xcode** | iOS build |
| **Firebase** | Push notifications + App config |
| **google-services.json** | Android Firebase config |
| **build_runner** | Code generation (Hive adapters) |
| **flutter_lints** | Code quality |

---

## 4. Frontend — Flutter App

### 4.1 App Entry Point & Startup

**File:** `lib/main.dart`

The app boot sequence is carefully ordered:

```
main() →
  1. WidgetsFlutterBinding.ensureInitialized()
  2. Firebase.initializeApp()          ← sets up FCM
  3. FirebaseMessaging.onBackgroundMessage()  ← background handler
  4. Hive.initFlutter()               ← initialise local DB
  5. Open 3 Hive boxes in parallel:
       - user_box
       - timetable_box
       - settings_box
  6. runApp(ProviderScope(child: TtApp()))
```

**Why ProviderScope?** — Riverpod requires the entire widget tree to be wrapped in `ProviderScope` so that all providers are accessible anywhere in the tree.

**Why Firebase is try-caught?** — The app still runs without Firebase (e.g. in a dev environment without `google-services.json` configured), gracefully degrading to no push notifications.

### 4.2 State Management — Riverpod

We use **Riverpod** (specifically `flutter_riverpod` v2.x) with the `StateNotifier` pattern.

#### Why Riverpod over other options?

| Feature | Provider (old) | Bloc | Riverpod |
|---|---|---|---|
| Compile-safe | ❌ | ✅ | ✅ |
| No BuildContext needed | ❌ | ❌ | ✅ |
| Auto-dispose | ❌ | Manual | ✅ |
| Testability | Low | High | High |
| Boilerplate | Low | High | Medium |

#### Providers in the App

| Provider | Type | Manages |
|---|---|---|
| `authProvider` | `StateNotifierProvider<AuthNotifier, AuthState>` | Login/logout, session restore |
| `timetableProvider` | `StateNotifierProvider<TimetableNotifier, TimetableState>` | Weekly/today timetable data |
| `facultyProvider` | `StateNotifierProvider` | Faculty list |
| `subjectProvider` | `StateNotifierProvider` | Subjects list |
| `constraintProvider` | `StateNotifierProvider` | Faculty scheduling constraints |
| `holidayProvider` | `StateNotifierProvider` | Holidays list |
| `roomProvider` | `StateNotifierProvider` | Rooms list |
| `timeslotProvider` | `StateNotifierProvider` | Time slot templates |
| `copoProvider` | `StateNotifierProvider` | COPO course-outcome mappings |
| `serverUrlProvider` | `StateNotifierProvider<ServerUrlNotifier, String>` | Configurable backend URL |
| `apiClientProvider` | `Provider<ApiClient>` | Shared HTTP client |
| `notificationServiceProvider` | `Provider<NotificationService>` | FCM/local notifications |
| `currentUserProvider` | `Provider<UserModel?>` | Convenience: current user |
| `isAdminProvider` | `Provider<bool>` | Convenience: admin check |
| `isFacultyProvider` | `Provider<bool>` | Convenience: faculty check |

#### State Flow Example (Login)

```
User types email + password
  → LoginScreen calls ref.read(authProvider.notifier).login(...)
    → AuthNotifier sets status = loading
      → AuthService.login() calls POST /auth/login
        → On success: saves token (SecureStorage), user data (Hive)
          → AuthNotifier sets status = authenticated
            → GoRouter redirect fires → navigates to /home
```

### 4.3 Navigation — GoRouter

**File:** `lib/navigation/app_router.dart`

GoRouter provides **declarative, URL-based routing** with redirect guards.

#### Route Map

| Route Path | Screen | Access |
|---|---|---|
| `/` | Splash Screen | All |
| `/login` | LoginScreen | Unauthenticated only |
| `/home` | DashboardScreen | Authenticated |
| `/timetable` | TimetableScreen | Authenticated |
| `/today` | TodayScreen | Authenticated |
| `/holidays` | HolidaysScreen | Authenticated |
| `/profile` | ProfileScreen | Authenticated |
| `/admin` | AdminPanelScreen | Admin only |
| `/admin/teachers` | ManageTeachersScreen | Admin only |
| `/admin/subjects` | ManageSubjectsScreen | Admin only |
| `/admin/rooms` | ManageRoomsScreen | Admin only |
| `/admin/timeslots` | ManageTimeslotsScreen | Admin only |
| `/admin/copo` | CopoScreen | Admin only |
| `/faculty/constraints` | FacultyConstraintsScreen | Faculty only |

#### Auth Guard Logic (Redirect)

```dart
redirect: (context, state) {
  if (isLoading)     → '/';           // Show splash
  if (!isLoggedIn)   → '/login';      // Force login
  if (isLoggedIn && onLoginPage) → '/home';  // Skip login
  return null;  // No redirect needed
}
```

The router also uses `refreshListenable` with a custom `_AuthChangeNotifier` to re-evaluate the redirect whenever auth state changes (login/logout).

#### Shell Route
The `ShellRoute` wraps all authenticated routes with `AppShell`, which provides the persistent bottom navigation bar.

### 4.4 Screens & Features

#### Dashboard Screen (`/home`)
- Displays greeting with user email, current date, day name
- Shows "Today's Holiday" banner if today is a holiday
- Shows the **Next Upcoming Lecture** card with subject, faculty, room, time
- Quick access 2x2 grid to: Timetable, Today, Holidays, Admin (if admin)
- Pull-to-refresh support

#### Timetable Screen (`/timetable`)
- Tab-based view: one tab per weekday (Mon–Sat)
- Auto-selects today's tab on open
- Filter bar: Branch, Semester, Division dropdowns
- Displays time slots in a grid; each cell shows subject, faculty, room
- Tapping a lecture opens a bottom sheet (`LectureDetailSheet`) with full details
- Lab lectures are visually distinguished
- **Export to PDF** button (bottom-right)
- Refresh button

#### Today Screen (`/today`)
- Focused view: only today's schedule
- Shows time-ordered lecture cards
- Holiday/weekend-aware banners
- Each lecture card shows status: upcoming / ongoing / past (calculated from current time)
- Pull-to-refresh

#### Holidays Screen (`/holidays`)
- List of upcoming holidays
- Supports adding/editing holidays (admin)
- Shows today's holiday prominently

#### Admin Panel Screen (`/admin`)
- Statistics row: count of teachers, subjects, timetable days
- **Timetable Generation card**: Select Branch + Semester + Division → triggers generation via POST `/timetable/generate`
- Shows generation success/failure message
- Quick links to all management screens

#### Manage Teachers Screen (`/admin/teachers`)
- CRUD operations on faculty
- Add teacher with name, email, department, role
- Edit/delete teachers

#### Manage Subjects Screen (`/admin/subjects`)
- CRUD for subjects
- Fields: subject code, subject name, semester, branch, credits (= lectures/week), lab flag, marks config

#### Manage Rooms Screen (`/admin/rooms`)
- CRUD for rooms/classrooms/labs
- Fields: room number, capacity, type (classroom/lab), floor, active status

#### Manage Time Slots Screen (`/admin/timeslots`)
- CRUD for time slot templates
- Configure the daily periods (e.g. 08:00–09:00, 09:00–10:00, break at 13:00...)
- Mark slots as break slots
- Sort order management

#### Faculty Constraints Screen (`/faculty/constraints`)
- Exclusive to faculty users
- Set max lectures per day (default: 4)
- Set total lectures per week (default: 18)
- Add **unavailable slots**: pick day + time range when faculty cannot teach
- Add **preferred slots**: slots the faculty wants to teach
- Save pushes constraints to the backend (used by scheduler)

#### COPO Screen (`/admin/copo`)
- Course–Outcome–Programme Outcome management
- Create course-to-outcome mappings (subject → CO count)
- Enroll users (students/faculty) into courses
- Filter by branch, semester, academic year

#### Profile Screen (`/profile`)
- Show email, user type
- **Server URL configuration**: Change the backend URL without rebuilding the app
  - Stored in Hive settings box
  - Used by ApiClient on next request
- Logout button

### 4.5 Data Models

All models are plain Dart classes (no code generation). They have `fromJson()` factory constructors and `toJson()` methods.

#### UserModel
```
Fields: uid, email, userType (1=Admin, 2=Faculty, 3=Student), token
Computed: isAdmin, isFaculty, isStudent, userTypeLabel
```

#### TimetableModel
```
Fields: id, dateOfWeek (e.g. "Monday"), fromDate, toDate,
         branchId, sem, division, academicId, createdBy, timestamps
```
One `TimetableModel` represents one day's schedule for one branch/sem/division.

#### TimetableDay (View Model)
```
Composes: TimetableModel + List<TimeSlotModel>
Purpose: aggregated view model used throughout UI
Computed: dayName (from timetable.dateOfWeek)
Two factories: fromJson() (nested format), fromApiEntry() (flat API format)
```

#### TimeSlotModel
```
Fields: id, timetableId, startTimeHr, startTimeMinutes, endTimeHr, endTimeMinutes,
         createdBy, timestamps
Nested: List<LectureAssignmentModel> lectures
Computed: startTimeDisplay, endTimeDisplay, timeRangeDisplay
```

#### LectureAssignmentModel
```
Fields: id, timeTableDetailedId, typeOfLecture (Theory/Lab/Extra),
         subjectCode, facultyId, batch, isExtra, lectOnBehalf (substitution flag),
         reason, roomNumber
Joined: subjectName, facultyName
Computed: isLabLecture, isExtraLecture, isSubstitution
```
> `lect_on_dehalf` (note DB typo) = 1 means this is a substitution lecture.

#### SubjectModel
```
Fields: id, subjectCode, subjectName, semester, branchId, acadYear,
         experiments, numExperiments, numAssignments, numModules,
         professorAssign, totalCredits, maxMarks, isOral, isPractical,
         oralMarks, practicalMarks, passingMarks
Computed: lecturesPerWeek (= totalCredits), isLabSubject (isPractical==1)
```

#### FacultyModel
```
Fields: facultyId, uid (links to users table), facultyClgId, name, contact,
         ftypeId, role, departId, privilege, joiningDate, shiftId, gender,
         dob, qualification, panNo, aadharCard, bloodGroup, permanentAddress,
         currentAddress, alternateMobile, experienceDetails, photo, signature,
         cv, email, branchId, status
Computed: isActive (status==1)
```

#### ConstraintModel
```
Fields: id, facultyId, maxLecturesPerDay, totalLecturesPerWeek
Nested: List<UnavailableSlot>, List<PreferredSlot>
```

#### UnavailableSlot
```
Fields: day (e.g. "Monday"), startHour, startMinutes, endHour, endMinutes
```

#### PreferredSlot
```
Fields: day, startHour, startMinutes, endHour, endMinutes
```

#### RoomModel
```
Fields: id, roomNumber, name, capacity, roomType, branchId, floor, isActive
Computed: active (isActive==1)
```

#### HolidayModel
```
Fields: id, date (string), name, type (National/Institute/Festival/Weekend), description
Computed: dateTime, isToday, isUpcoming
```

#### TimeSlotTemplateModel
```
Fields: id, label, startTimeHr, startTimeMinutes, endTimeHr, endTimeMinutes,
         isBreak, sortOrder, isActive
Computed: active, breakSlot, timeRange
Purpose: master template for the day structure (e.g. "Period 1: 08:00–09:00")
```

#### CopoUserCourseModel
```
Fields: usercourseId, courseId, semester, academicYear, branch, coCount, createdAt
Joined: subjectName, subjectCode, enrolledCount
Computed: branchLabel (1→CS, 2→IT, 3→EXTC, 4→Mech)
```

#### CopoEnrollmentModel
```
Fields: id, usercourseId, userId, userEmail, userType
Purpose: tracks who is enrolled in which course outcome
```

### 4.6 Services Layer

Services sit between providers and the API client. They contain all HTTP logic.

#### AuthService
- `login(email, password)` → POST `/auth/login` → saves JWT + user data locally → returns `UserModel`
- `logout()` → POST `/auth/logout` → clears all local storage
- `getStoredUser()` → reads token + user from local storage (session restore on app open)
- `getProfile()` → GET `/auth/profile`

#### TimetableService
- `fetchWeeklyTimetable({branchId, semester, division, academicYear})` → GET `/timetable/weekly`
- `fetchTodayTimetable({branchId, semester, division})` → GET `/timetable/today`
- `fetchFacultyTimetable(facultyId)` → GET `/faculty/timetable/:id`
- `fetchAllTimetables()` → GET `/timetable`
- `fetchTimeSlots(timetableId)` → GET `/timetable/slots/:id`
- `generateTimetable({branchId, semester, division, academicYear})` → POST `/timetable/generate`
- `updateLectureSlot({slotId, updates})` → PUT `/timetable/slots/:id`

#### FacultyService
- Full CRUD: list, get by id, create, update, delete

#### SubjectService
- Full CRUD via `/subjects`

#### RoomService
- Full CRUD via `/rooms`

#### ConstraintService
- `getConstraintsByFaculty(facultyId)` → GET `/constraints/faculty/:id`
- `saveConstraints(constraint)` → POST/PUT `/constraints`

#### HolidayService
- `fetchHolidays()` → GET `/holidays`
- `fetchUpcomingHolidays()` → GET `/holidays/upcoming`
- Add/update/delete holidays (admin)

#### TimeslotService
- CRUD for time slot templates via `/timeslots`

#### CopoService
- `loadCourses({branch, semester, academicYear})` → GET `/copo`
- `createCourse(data)` → POST `/copo`
- `deleteCourse(id)` → DELETE `/copo/:id`
- `loadEnrollments(usercourseId)` → GET `/copo/:id/users`
- `enrollUser(usercourseId, userId)` → POST `/copo/:id/users`
- `removeEnrollment(enrollmentId)` → DELETE enrollment

#### StorageService
Two-tier storage:
- **FlutterSecureStorage** → `auth_token`, `fcm_token` (hardware-backed encryption on device)
- **Hive** → `user_data`, `timetable_cache`, `holiday_cache`, `server_url`, `settings`

#### TimetableExportService
- Builds a multi-page PDF in A4 landscape format
- Constructs a matrix: days (columns) × time slots (rows)
- Each cell: subject name + lab tag + faculty name + room number
- Uses the `pdf` package with custom styling

#### NotificationService
- Initializes FCM + local notifications
- Requests permission (alert, badge, sound)
- Creates Android notification channel `ttapp_high_importance`
- Listens to foreground FCM messages → shows local notification
- `getFcmToken()` → device token for server-side push
- `subscribeToTopic(topic)` / `unsubscribeFromTopic(topic)`

### 4.7 Local Storage Strategy

**Three Hive Boxes:**

| Box | Key | Content |
|---|---|---|
| `settings_box` | `user_data` | JSON-encoded user object |
| `settings_box` | `holiday_cache` | JSON-encoded holiday list |
| `settings_box` | `server_url` | Backend URL string |
| `timetable_box` | `timetable_cache` | JSON-encoded timetable days |
| `user_box` | (future use) | Reserved for extended user data |

**Secure Storage:**

| Key | Value |
|---|---|
| `auth_token` | JWT Bearer token |
| `fcm_token` | Firebase Cloud Messaging device token |

**Cache Strategy (Timetable):**
1. If no filters applied → check Hive cache first → show cached data immediately (fast UX)
2. Then always fetch fresh from API in background
3. On success → overwrite cache with fresh data
4. If API fails but cached data exists → stay in `loaded` state (graceful degradation)
5. If API fails AND no cache → go to `error` state

### 4.8 Push Notifications

**Tech Stack:** Firebase Cloud Messaging (FCM) + `flutter_local_notifications`

**Flow:**
1. App requests permission on startup
2. Gets an FCM device token from Firebase
3. Saves token to `flutter_secure_storage` and (optionally) POSTs to `/notifications/token` on the backend
4. Server sends push messages via FCM to specific tokens or topics
5. **Foreground:** `FirebaseMessaging.onMessage` listener catches message → shows a local notification via `FlutterLocalNotificationsPlugin`
6. **Background:** `firebaseMessagingBackgroundHandler` (top-level function, `@pragma('vm:entry-point')`) handles the message
7. **Topic subscriptions** allow broadcasting to all faculty, all students, etc.

**Use cases in TT Manager:**
- Lecture cancellation alerts
- Substitution notifications
- Timetable change announcements
- Holiday announcements

### 4.9 PDF Export

The timetable can be exported to PDF for printing on notice boards.

**Implementation (`timetable_export_service.dart`):**
1. Iterates all `TimetableDay` objects in the weekly schedule
2. Builds a `Map<dayName, Map<timeKey, TimeSlotModel>>` matrix
3. Collects all unique time keys (e.g. `'08:00'`, `'09:00'`) and sorts them
4. Creates an A4 landscape `pw.MultiPage` document
5. Renders a `pw.Table` with days as columns and periods as rows
6. Each cell shows: `Subject Name [Lab if applicable] \n Faculty Name \n Room Number`
7. Adds title row with branch/semester/division context
8. Adds generation timestamp in the footer
9. Returns `Uint8List` → printed/shared via the `printing` package's `Printing.layoutPdf()`

### 4.10 Theme & UI System

**Font:** Poppins (via Google Fonts)

**Material 3** design system is used throughout.

**Color Palette (`AppColors`):**
- Primary: used for AppBar, primary buttons, active states
- Secondary: accent color
- Success: green for positive statuses
- Warning: orange/amber for alerts
- Error: red for failures
- Background, Surface, TextPrimary, TextSecondary

**Shared Widgets:**
- `AppShell` — persistent bottom nav bar shell
- `LectureCardWidget` — displays a single lecture with color coding
- `EmptyStateWidget` — placeholder for empty lists
- `LoadingOverlayWidget` / `FullScreenLoader` — loading indicators
- `ShimmerLoading` — skeleton screens during data fetch

---

## 5. Backend — REST API

### 5.1 API Client Architecture

**File:** `lib/core/api/api_client.dart`

Built on **Dio** with three interceptors:

#### 1. `_AuthInterceptor`
- Reads JWT from `StorageService` before every request
- Injects `Authorization: Bearer <token>` header
- On **401 Unauthorized** response → clears all local storage (forces re-login)

#### 2. `_ErrorInterceptor`
- Catches `DioException` and converts to human-readable error messages
- Handles: connection timeout, receive timeout, bad response, network errors

#### 3. `LogInterceptor`
- Logs all requests and responses to console in debug
- Shows request body, response body, and errors

#### Dynamic Base URL
The base URL is not hardcoded at build time. On startup:
1. `getEffectiveBaseUrl()` reads from `Hive.settingsBox[server_url]`
2. Falls back to `AppConstants.baseUrl` if not set
3. `ServerUrlNotifier` allows changing the URL at runtime (Profile screen)
4. The new URL is persisted in Hive for subsequent sessions

This is critical for local development on physical devices (LAN IP address).

**Default URL:** `http://172.16.13.253:3000/api`

### 5.2 Authentication & Security

- **Authentication:** JWT Bearer tokens
- **Token storage:** `flutter_secure_storage` (uses Android Keystore / iOS Keychain)
- **Token injection:** Automatic via `_AuthInterceptor`
- **Token refresh:** Endpoint `/auth/refresh` exists (for future implementation)
- **Session restore:** On app open, `AuthNotifier._checkStoredSession()` reads stored token + user data and restores the session without requiring re-login
- **Logout:** Clears all secure storage AND Hive boxes

### 5.3 Complete API Endpoints Reference

#### Authentication
| Method | Endpoint | Description |
|---|---|---|
| POST | `/auth/login` | Login with email+password → returns JWT + user |
| POST | `/auth/logout` | Invalidate session |
| GET | `/auth/profile` | Get current user profile |
| PUT | `/auth/profile/update` | Update user profile |
| POST | `/auth/refresh` | Refresh JWT token |

#### Timetable
| Method | Endpoint | Description |
|---|---|---|
| GET | `/timetable` | Get all timetable entries (admin) |
| GET | `/timetable/weekly?branchId=&sem=&division=` | Get full weekly timetable with filters |
| GET | `/timetable/today?branchId=&sem=&division=` | Get today's schedule only |
| POST | `/timetable/generate` | **Trigger AI/algorithm timetable generation** |
| GET | `/timetable/slots/:timetableId` | Get time slots for a timetable day |
| PUT | `/timetable/slots/:slotId` | Update a lecture assignment |

#### Faculty
| Method | Endpoint | Description |
|---|---|---|
| GET | `/faculty` | List all faculty |
| GET | `/faculty/:id` | Get faculty by ID |
| POST | `/faculty` | Add new faculty member |
| PUT | `/faculty/:id` | Update faculty details |
| DELETE | `/faculty/:id` | Remove faculty |
| GET | `/faculty/timetable/:facultyId` | Get faculty's personal timetable |

#### Subjects
| Method | Endpoint | Description |
|---|---|---|
| GET | `/subjects` | List all subjects |
| GET | `/subjects/:id` | Get subject by ID |
| POST | `/subjects` | Create subject |
| PUT | `/subjects/:id` | Update subject |
| DELETE | `/subjects/:id` | Delete subject |

#### Rooms
| Method | Endpoint | Description |
|---|---|---|
| GET | `/rooms` | List all rooms |
| GET | `/rooms/:id` | Get room by ID |
| POST | `/rooms` | Create room |
| PUT | `/rooms/:id` | Update room |
| DELETE | `/rooms/:id` | Delete room |

#### Constraints
| Method | Endpoint | Description |
|---|---|---|
| GET | `/constraints` | Get all constraints |
| GET | `/constraints/faculty/:facultyId` | Get constraints for a specific faculty |
| POST | `/constraints` | Create/update constraints |

#### Holidays
| Method | Endpoint | Description |
|---|---|---|
| GET | `/holidays` | List all holidays |
| GET | `/holidays/upcoming` | List upcoming holidays |
| POST | `/holidays` | Add holiday |
| PUT | `/holidays/:id` | Update holiday |
| DELETE | `/holidays/:id` | Delete holiday |

#### Time Slot Templates
| Method | Endpoint | Description |
|---|---|---|
| GET | `/timeslots` | List all time slot templates |
| GET | `/timeslots/:id` | Get template by ID |
| POST | `/timeslots` | Create template |
| PUT | `/timeslots/:id` | Update template |
| DELETE | `/timeslots/:id` | Delete template |

#### Admin
| Method | Endpoint | Description |
|---|---|---|
| GET | `/admin/stats` | Get dashboard statistics |
| GET | `/admin/branches` | Get list of branches |
| GET | `/admin/divisions` | Get list of divisions |

#### COPO
| Method | Endpoint | Description |
|---|---|---|
| GET | `/copo?branch=&semester=&academicYear=` | List course-outcome mappings |
| POST | `/copo` | Create mapping |
| DELETE | `/copo/:id` | Delete mapping |
| GET | `/copo/:id/users` | Get enrolled users for a course |
| POST | `/copo/:id/users` | Enroll a user |
| DELETE | `/copo/enrollment/:id` | Remove enrollment |

#### Notifications
| Method | Endpoint | Description |
|---|---|---|
| POST | `/notifications/token` | Save FCM device token on server |

---

## 6. Core Domain Logic — Timetable Generation

This is the most important algorithmic part of the project.

### 6.1 Constraints Engine

Before generation, the system collects:

1. **Subjects** for the target branch/semester with `totalCredits` (= lectures needed per week)
2. **Faculty** assignments per subject
3. **Faculty Constraints** per teacher:
   - `maxLecturesPerDay` (e.g. 4)
   - `totalLecturesPerWeek` (e.g. 18)
   - `unavailableSlots` (e.g. Monday 10:00–11:00 unavailable)
   - `preferredSlots` (e.g. wants to teach in the morning)
4. **Rooms** with capacity and type (classroom / lab)
5. **Time Slot Templates** — the master daily schedule (8 periods + breaks)

### 6.2 How the Scheduler Works

The timetable generation is triggered by:
```
POST /timetable/generate
Body: { branchId, sem, division, academicYear }
```

**At the backend (conceptual algorithm):**

```
Input:
  - Subjects S[] with weekly lecture counts
  - Faculty F[] with constraints
  - Time slots T[] (Mon–Sat × 8 periods)
  - Rooms R[]

Algorithm (Constraint Satisfaction / Greedy with backtracking):

1. For each Subject s in S:
   a. Required slots = s.totalCredits (lectures/week)
   b. If lab: needs consecutive double-period + lab room
   c. Assign faculty from s.professorAssign or round-robin

2. For each required lecture assignment:
   a. Iterate available (day, slot) combinations
   b. Check constraint: faculty.unavailableSlots → skip if clashes
   c. Check constraint: faculty daily count < maxLecturesPerDay
   d. Check constraint: faculty weekly count < totalLecturesPerWeek
   e. Check: no faculty double-booking (same faculty at same time)
   f. Check: no room conflict (same room at same time)
   g. Check: faculty preferred slots → prefer if available
   h. Assign lecture to (day, slot, room, faculty)

3. Save to DB:
   - Create TimetableModel (one per day)
   - Create TimeSlotModel (one per period)
   - Create LectureAssignmentModel (one per lecture in that period)

Output:
  - Fully populated timetable in DB
  - Returns { success: true, message: "Timetable generated" }
```

**Key Constraints Enforced:**
| Constraint | Description |
|---|---|
| No double booking | Same faculty cannot teach two classes simultaneously |
| Room conflict | Same room cannot have two lectures at same time |
| Max daily load | Faculty won't exceed their per-day lecture limit |
| Max weekly load | Faculty won't exceed their per-week lecture limit |
| Unavailability | Faculty absent slots are never assigned |
| Lab requirements | Lab subjects get appropriate rooms (lab type) |
| Credit hours | Each subject gets exactly `totalCredits` slots per week |

**Lecture Types:**
- `Theory` — Regular lecture in classroom
- `Lab / Practical` — Lab session (often 2 hours consecutive), requires lab room
- `Extra` — Extra lecture (marked with `isExtra = 1`)
- Substitution — `lectOnBehalf = 1`, filled in manually by admin

---

## 7. Role-Based Access Control (RBAC)

Three user types exist in the system:

| userType | Role | Capabilities |
|---|---|---|
| 1 | **Admin** | Full access: generate timetable, manage all entities, COPO, view everything |
| 2 | **Faculty** | View own timetable, view weekly timetable, set personal constraints |
| 3 | **Student** | View timetable for their branch/semester/division |

**Enforcement on Frontend:**
- `isAdminProvider` and `isFacultyProvider` convenience providers
- Route-level: Admin routes check `user.isAdmin` on screen init; non-admins see "Access Denied"
- UI-level: Quick action grid on Dashboard shows Admin panel card only if `isAdmin`
- Admin Panel screen: `if (user != null && !user.isAdmin) return AccessDenied`

**Enforcement on Backend:**
- JWT payload contains `user_type`
- Middleware validates role before processing protected routes
- Timetable generation and management endpoints require `user_type == 1`

---

## 8. COPO — Course Outcome & Programme Outcome

### What is COPO?

COPO stands for **Course Outcomes** (CO) and **Programme Outcomes** (PO). It is mandatory for **NBA/NAAC accreditation** of engineering colleges.

- **Course Outcome (CO):** What a student will be able to do after completing a specific subject (e.g. "CO1: Student can design a database schema")
- **Programme Outcome (PO):** What a graduate of the entire programme can do (e.g. "PO3: Apply engineering knowledge to solve complex problems")
- **CO-PO Mapping:** Links each CO to relevant POs with a strength value (1=Low, 2=Medium, 3=High)

### Implementation in TT Manager

The `CopoScreen` allows admins to:
1. Create **User-Course mappings** (`CopoUserCourseModel`): Associate a subject with its semester, branch, academic year, and number of COs
2. **Enroll users** (`CopoEnrollmentModel`): Link faculty/students to course outcome records
3. Filter by branch, semester, and academic year

### Why It's Part of This App?

TT Manager is not just a scheduler — it's a holistic **college academic management tool**. COPO is part of the academic workflow that uses the same faculty, subject, and branch data already present in the system.

---

## 9. Data Flow Diagrams

### Login Flow
```
User → LoginScreen → AuthNotifier.login()
  → POST /auth/login (email, password)
  → Response: { token, user: { uid, email, user_type } }
  → StorageService.saveToken() → SecureStorage
  → StorageService.saveUserData() → Hive
  → AuthState.authenticated
  → GoRouter redirect → /home
```

### Timetable Load Flow
```
DashboardScreen/TimetableScreen → TimetableNotifier.loadWeeklyTimetable()
  → Check Hive cache (if no filters)
    → If cached: emit TimetableStatus.loaded with cached data (instant)
  → GET /timetable/weekly?branchId=&sem=&division=
  → Response: [{ id, dateOfWeek, slots: [{ id, startTimeHr, ..., lectures: [...] }] }]
  → Parse: TimetableDay.fromApiEntry() for each day
  → Save to Hive cache
  → Emit TimetableStatus.loaded with fresh data
```

### Timetable Generation Flow
```
Admin → AdminPanelScreen → Select Branch + Semester + Division
  → TimetableNotifier.generateTimetable()
  → TimetableState.isGenerating = true → UI shows loading overlay
  → POST /timetable/generate { branchId, sem, division, academicYear }
  → Backend: runs constraint satisfaction algorithm
  → Response: { success: true, message: "Generated" }
  → TimetableNotifier.loadWeeklyTimetable() (refresh)
  → TimetableState.generateMessage shown to user
```

### Constraint Save Flow
```
Faculty → FacultyConstraintsScreen → Set max, unavailable, preferred slots
  → constraintProvider.notifier.saveConstraints()
  → POST/PUT /constraints { faculty_id, max_lectures_per_day, ... }
  → ConstraintState.saved
  → Backend stores constraints → used in next generation run
```

---

## 10. Database Schema (Inferred)

Based on model field names and API structure:

### `users`
| Column | Type | Notes |
|---|---|---|
| uid | INT PK | User ID |
| email | VARCHAR | Unique |
| password | VARCHAR | Hashed (bcrypt) |
| user_type | INT | 1=Admin, 2=Faculty, 3=Student |

### `faculty`
| Column | Type | Notes |
|---|---|---|
| faculty_id | INT PK | |
| uid | INT FK | → users.uid |
| faculty_clg_id | VARCHAR | College-assigned ID |
| name | VARCHAR | |
| email | VARCHAR | |
| depart_id | INT | Department |
| branch_id | INT | Branch |
| ftype_id | INT | Faculty type |
| status | INT | 1=Active |
| + many profile fields | | DOB, qualification, etc. |

### `subjects`
| Column | Type | Notes |
|---|---|---|
| id | INT PK | |
| subject_code | VARCHAR | e.g. "CS301" |
| subject_name | VARCHAR | |
| semester | INT | 1-8 |
| branch_id | INT | FK |
| totalcredits | INT | = lectures per week |
| ispractical | INT | 1 = lab subject |
| isoral | INT | |
| professorAssign | VARCHAR | faculty ids |

### `timetable` (master)
| Column | Type | Notes |
|---|---|---|
| id | INT PK | |
| dateOfWeek | VARCHAR | "Monday"…"Saturday" |
| branch_id | INT | FK |
| sem | INT | |
| division | VARCHAR | A/B/C/D |
| academic_id | INT | Academic year FK |
| fromDate | DATE | |
| toDate | DATE | |
| createdBy | INT | FK → users.uid |

### `timetable_detailed` (time slots)
| Column | Type | Notes |
|---|---|---|
| id | INT PK | |
| timetable_id | INT FK | → timetable.id |
| startTimeHr | INT | |
| startTimeMinutes | INT | |
| endTimeHr | INT | |
| endTimeMinutes | INT | |

### `timetable_lectures` (actual assignments)
| Column | Type | Notes |
|---|---|---|
| id | INT PK | |
| time_table_detailed_id | INT FK | → timetable_detailed.id |
| subjectCode | VARCHAR | |
| facultyid | INT FK | → faculty.faculty_id |
| typeOfLecture | VARCHAR | Theory/Lab/Extra |
| batch | VARCHAR | For lab batches |
| room_number | VARCHAR | |
| is_extra | INT | 1=Extra lecture |
| lect_on_dehalf | INT | 1=Substitution |
| reason | VARCHAR | Reason for substitution |

### `constraints`
| Column | Type | Notes |
|---|---|---|
| id | INT PK | |
| faculty_id | INT FK | |
| max_lectures_per_day | INT | |
| total_lectures_per_week | INT | |
| unavailable_slots | JSON | Array of slot objects |
| preferred_slots | JSON | Array of slot objects |

### `rooms`
| Column | Type | Notes |
|---|---|---|
| id | INT PK | |
| room_number | VARCHAR | |
| name | VARCHAR | |
| capacity | INT | |
| room_type | VARCHAR | classroom/lab |
| branch_id | INT | |
| floor | VARCHAR | |
| is_active | INT | |

### `holidays`
| Column | Type | Notes |
|---|---|---|
| id | INT PK | |
| date | DATE | |
| name | VARCHAR | |
| type | VARCHAR | National/Institute/Festival |
| description | VARCHAR | |

### `timeslots` (templates)
| Column | Type | Notes |
|---|---|---|
| id | INT PK | |
| label | VARCHAR | e.g. "Period 1" |
| startTimeHr | INT | |
| startTimeMinutes | INT | |
| endTimeHr | INT | |
| endTimeMinutes | INT | |
| is_break | INT | 1=Break |
| sort_order | INT | Display order |
| is_active | INT | |

### `usercourses` (COPO)
| Column | Type | Notes |
|---|---|---|
| usercourse_id | INT PK | |
| course_id | INT | → subjects.id |
| semester | INT | |
| academic_year | VARCHAR | e.g. "2025-26" |
| branch | INT | |
| co_count | INT | Number of COs defined |

### `usercourse_users` (COPO enrollments)
| Column | Type | Notes |
|---|---|---|
| id_usercourse_users | INT PK | |
| usercourse_id | INT FK | |
| user_id | INT FK | → users.uid |

---

## 11. Security Implementation

| Area | Implementation |
|---|---|
| **Authentication** | JWT Bearer tokens (stateless) |
| **Token Storage** | `flutter_secure_storage` — uses Android Keystore API / iOS Secure Enclave |
| **Token Injection** | Auto-injected by `_AuthInterceptor` on every request |
| **Session Invalidation** | 401 response → automatic logout + storage wipe |
| **Input Validation** | All user inputs go through model constructors before sending |
| **No Hardcoded Secrets** | Server URL is configurable; `google-services.json` is in `.gitignore`-worthy |
| **HTTPS Ready** | Base URL constant has placeholder for production HTTPS URL |
| **Offensive Data** | Passwords never logged (only logged in DIO: request body is enabled for dev; should be disabled in production) |
| **Role Enforcement** | Both frontend guards and backend middleware check `user_type` |
| **Secure Logout** | `StorageService.clearAll()` wipes both SecureStorage and all Hive boxes |

---

## 12. Feature Completeness Matrix

| Feature | Status | Notes |
|---|---|---|
| User Login / Logout | ✅ | JWT-based |
| Session Persistence | ✅ | Restores on app reopen |
| Role-Based UI | ✅ | Admin / Faculty / Student |
| Weekly Timetable View | ✅ | Tab per day, filter by branch/sem/div |
| Today's Schedule | ✅ | Time-aware (past/ongoing/upcoming) |
| Timetable Generation | ✅ | POST /timetable/generate |
| PDF Export | ✅ | A4 landscape grid |
| Faculty Management | ✅ | Full CRUD |
| Subject Management | ✅ | Full CRUD |
| Room Management | ✅ | Full CRUD |
| Time Slot Templates | ✅ | Full CRUD |
| Faculty Constraints | ✅ | Per-faculty max load + unavailability |
| Holiday Management | ✅ | Full CRUD + upcoming list |
| Holiday-aware Dashboard | ✅ | Banner on holidays |
| Push Notifications | ✅ | FCM + local notifications |
| Offline Caching | ✅ | Hive-based with cache-then-network |
| COPO Management | ✅ | CO mapping + enrollment |
| Configurable Server URL | ✅ | Runtime changeable from Profile |
| Substitution tracking | ✅ | `lectOnBehalf` flag in lecture model |
| Lab/Practical scheduling | ✅ | `isPractical` flag on subjects |

---

## 13. Possible Viva Questions & Answers

### General / Overview

**Q: What is TT Manager and what problem does it solve?**
> TT Manager is a cross-platform mobile application for automated college timetable management. Traditional timetable scheduling is done manually, which is error-prone and time-consuming — especially when faculty have different availability constraints, subjects have different credit hours, and rooms need to be allocated without conflicts. TT Manager digitizes this process: faculty input their constraints, the admin triggers one-click generation, and the system produces a conflict-free weekly timetable instantly.

**Q: What is the tech stack used?**
> Frontend: Flutter (Dart) with Riverpod for state management, GoRouter for navigation, Dio for HTTP, Hive for local storage, and FlutterSecureStorage for tokens. Backend: Node.js REST API with JWT authentication and SQL database. Firebase for push notifications. PDF package for timetable export.

**Q: Why Flutter over native Android/iOS?**
> Flutter allows us to write one codebase that compiles to Android and iOS natively. It has a rich widget ecosystem, high performance via the Skia/Impeller rendering engine, and Dart is a strong typed language. The same app works on web and desktop too, though our primary targets are mobile.

---

### State Management

**Q: Why did you choose Riverpod over Provider or Bloc?**
> Riverpod is compile-safe (errors at compile time, not runtime), doesn't require `BuildContext` to read state (which makes it testable and usable in service layers), supports auto-disposal of providers, and handles async state cleanly with `AsyncValue`. Provider is Riverpod's predecessor and has known issues. Bloc adds too much boilerplate for what we need.

**Q: Explain the AuthState machine.**
> `AuthStatus` has 5 states: `initial` (app just started), `loading` (checking stored session or logging in), `authenticated` (valid session), `unauthenticated` (no session), `error` (login failed). The `AuthNotifier` starts in `initial`, fires `_checkStoredSession()`, and transitions from there based on stored token presence.

**Q: What is StateNotifier?**
> `StateNotifier<T>` is a Riverpod class for managing immutable state of type T. It exposes a `state` property and you modify state by replacing it with `state = newValue`. Unlike `ChangeNotifier`, it forces immutability through the use of `copyWith` patterns, making state changes explicit and traceable.

---

### Navigation

**Q: What is GoRouter and why use it?**
> GoRouter is a declarative routing package for Flutter built on top of Navigator 2.0. Key advantages: URL-based routing (deep linking support), `redirect` callbacks for auth guards, `ShellRoute` for persistent navigation shells, and type-safe route handling. Traditional `Navigator.push/pop` was too imperative and didn't handle deep links or web URLs well.

**Q: How does the auth guard work?**
> GoRouter's `redirect` callback is called before every navigation. It checks `AuthState.isAuthenticated`: if not authenticated and not on login page → redirect to `/login`. If authenticated and on login/splash → redirect to `/home`. The `refreshListenable` parameter points to `_AuthChangeNotifier` which extends `ChangeNotifier` and is notified when `authProvider` changes — so the redirect re-evaluates automatically on login/logout.

---

### Data & Storage

**Q: Why two different storage mechanisms (Hive and FlutterSecureStorage)?**
> They serve different purposes. `FlutterSecureStorage` uses the OS-level secure keychain (Android Keystore / iOS Keychain) for sensitive data like JWT tokens — it's hardware-backed and encrypted. Hive is a fast NoSQL database for larger, non-sensitive data like cached timetables and settings. You wouldn't put a full timetable cache in SecureStorage (performance), and you wouldn't put a JWT in Hive (security).

**Q: What is Hive?**
> Hive is a lightweight, fast key-value NoSQL database for Flutter. Data is stored in typed "boxes". It doesn't require a native OS component, making it cross-platform. It's much faster than SQLite for simple key-value reads and doesn't require a schema. We use it for caching API responses so the app works offline or shows content immediately while fresh data loads.

**Q: Describe your cache strategy.**
> We use a "cache-then-network" pattern for the timetable. On load: first check Hive for cached data and display it immediately (instant UX), then simultaneously fetch from the API. When API responds, overwrite cache and update UI. If API fails and we have cached data, stay in loaded state. If API fails and no cache, show error. For division-specific queries (filtered), we skip cache and always hit the API to avoid stale data.

---

### Networking

**Q: What is Dio and why not `http` package?**
> Dio is a powerful HTTP client with built-in interceptor support, timeout configuration, request/response transformation, and FormData support. The standard `http` package is too basic — we'd have to manually implement interceptors for auth token injection and error handling. Dio's interceptor chain makes this clean and centralized.

**Q: How does token injection work?**
> `_AuthInterceptor` extends Dio's `Interceptor` and overrides `onRequest()`. Before every HTTP call, it reads the JWT from `FlutterSecureStorage` and appends `Authorization: Bearer <token>` to the request headers. On 401 response, `onError()` fires, clears all storage, and lets the app redirect to login.

**Q: How does error handling work?**
> `_ErrorInterceptor` catches `DioException` types and converts them: `connectTimeout` → "Connection timeout", `receiveTimeout` → "Receive timeout", `badResponse` with status 404 → "Not found", 500 → "Server error". These string messages bubble up to the state notifiers which store them in `errorMessage` for the UI to display.

---

### Timetable Generation

**Q: How is the timetable generated?**
> The admin selects branch, semester, and division, then triggers `POST /timetable/generate`. The backend runs a constraint satisfaction algorithm that iterates through all subjects needing scheduled slots. For each lecture assignment, it checks every (day, time slot) candidate and validates: faculty isn't double-booked, room isn't occupied, faculty hasn't exceeded their daily/weekly limit, and the slot isn't in their unavailable windows. When a valid slot is found, it's assigned. Results are persisted to the DB and the app fetches the new timetable.

**Q: What are faculty constraints and how are they modeled?**
> Each faculty can define: `maxLecturesPerDay` (max lectures in a single day), `totalLecturesPerWeek` (total weekly load), `unavailableSlots` (specific day+time ranges when they can't teach), and `preferredSlots` (times they prefer). These are stored as JSON arrays in the constraints table. The scheduler reads these before making any assignment.

**Q: What is an UnavailableSlot?**
> It has fields: `day` (e.g. "Monday"), `startHour`, `startMinutes`, `endHour`, `endMinutes`. If a faculty has Monday 10:00–11:00 as unavailable, the scheduler will never assign a lecture to that faculty during Monday 10:00 slot.

**Q: How are lab subjects handled differently?**
> In `SubjectModel`, `isPractical == 1` marks a subject as a lab. Labs typically need: a lab room (not a regular classroom), consecutive double-period slots (2 hours at once), and potentially split batch scheduling (Batch A one week, Batch B another). The `LectureAssignmentModel` has a `batch` field for this. The `typeOfLecture` field will be `'Lab'` for these entries.

**Q: What does `lectOnBehalf` mean in LectureAssignmentModel?**
> It represents a substitution lecture — when `lectOnBehalf = 1`, it means this lecture slot is being covered by a stand-in faculty member on behalf of the originally assigned faculty (who may be absent). The `reason` field stores why the substitution happened. This allows tracking of substitutions for administrative records.

---

### Push Notifications

**Q: How does FCM work in this app?**
> Firebase Cloud Messaging (FCM) provides a unique device token for each installation. Our app requests permission, gets this token, and saves it to the backend via `POST /notifications/token`. When the server needs to send a notification (e.g. timetable change), it sends the message to FCM with the target device token. FCM routes it to the device. If the app is in foreground, `FirebaseMessaging.onMessage` fires and we show a local notification. If it's in background, the top-level `_firebaseMessagingBackgroundHandler` handles it (marked `@pragma('vm:entry-point')` so Dart doesn't tree-shake it).

**Q: What is @pragma('vm:entry-point')?**
> It's a Dart annotation telling the compiler that this function is an entry point called from outside Dart code (in this case, from native Firebase SDK callbacks). Without this, the Dart tree-shaker might remove the function in release builds, breaking background notifications.

**Q: What notification channels are used?**
> Android requires notification channels (since Android 8/API 26). We create one channel: `ttapp_high_importance` with `Importance.high` priority, named "TT Manager Notifications", for lecture reminders and substitution alerts.

---

### Architecture & Design Patterns

**Q: What design patterns are used?**
> - **Repository Pattern:** Services act as repositories abstracting the data source from the state layer
> - **Observer Pattern:** Riverpod providers are reactive; any change triggers dependent widgets to rebuild
> - **Singleton:** Services are singleton `Provider`s in Riverpod
> - **Factory:** All models use `factory` constructors (`fromJson`)
> - **Interceptor Pattern:** Dio interceptors for cross-cutting concerns (auth, logging, error)
> - **State Machine:** `AuthStatus` and `TimetableStatus` enums model explicit state transitions
> - **Immutable State:** `copyWith` pattern ensures state objects are never mutated in place

**Q: Why are models plain Dart classes and not generated code?**
> We chose hand-written models for flexibility. The backend API has inconsistencies (e.g. `lect_on_dehalf` spelling, mixed `camelCase`/`snake_case` field names). Hand-written `fromJson` factories handle all these edge cases with explicit null safety checks (`json['field']?.toString() ?? ''`). Code generation (like `json_serializable`) would require consistent field names.

**Q: What is the Provider pattern in Riverpod?**
> A `Provider<T>` is the simplest provider — it creates and caches an object (no state changes). A `StateNotifierProvider<N, S>` creates a `StateNotifier<S>` and exposes both the notifier (for calling methods) and the state (for reading). You read state with `ref.watch(provider)` and trigger actions with `ref.read(provider.notifier).method()`.

---

### COPO

**Q: What is COPO and why is it in a timetable app?**
> COPO (Course Outcome – Programme Outcome) management is required for NBA/NAAC accreditation. Since TT Manager already has the faculty, subject, and semester data, it's natural to extend it with CO-PO mapping. An admin can create course-outcome entries for each subject and enroll users into them. This feeds into attainment calculations for accreditation reports.

**Q: What does `co_count` mean in CopoUserCourseModel?**
> It represents how many Course Outcomes (COs) are defined for that particular course in that academic year. For example, Data Structures might have 5 COs: CO1 through CO5, each defining a measurable learning outcome.

---

### Security

**Q: Why is the JWT stored in FlutterSecureStorage and not SharedPreferences?**
> SharedPreferences stores data as plaintext XML on Android (accessible to anyone with physical access or root). FlutterSecureStorage encrypts data using the Android Keystore (hardware-backed) or iOS Keychain (Secure Enclave) — data is tied to the app's unique credentials and cannot be read by other apps or without biometric/PIN authentication.

**Q: What happens if the token expires?**
> The `_AuthInterceptor.onError()` catches 401 responses, calls `_storageService.clearAll()` to wipe the token and user data, and passes the error up. The `GoRouter` redirect detects `isAuthenticated = false` and sends the user to `/login`. The backend also has a `/auth/refresh` endpoint (for future implementation of token refresh without full re-login).

**Q: Is the server URL being user-configurable a security risk?**
> For an enterprise app, yes — it could be pointed at a malicious server. However, for our use case (college LAN deployment), it's a necessary feature because different deployment environments have different IP addresses. In a production setup, we would restrict this to a whitelist of allowed server domains or remove it entirely, hardcoding the HTTPS production URL.

---

### Flutter-Specific

**Q: What is ConsumerWidget vs StatefulWidget?**
> `ConsumerWidget` is Riverpod's equivalent of `StatelessWidget` — it has access to a `WidgetRef` in `build()` for reading providers. `ConsumerStatefulWidget` + `ConsumerState` gives both full lifecycle methods (`initState`, `dispose`) AND `WidgetRef` access. We use `ConsumerStatefulWidget` for screens that need to trigger data loading in `initState`.

**Q: What is `ref.watch` vs `ref.read`?**
> `ref.watch(provider)` subscribes the widget to the provider — the widget rebuilds whenever the state changes. `ref.read(provider)` reads the current value once without subscribing — used inside event handlers (`onPressed`, `initState`) where you don't want a rebuild to be triggered. Using `ref.watch` inside `initState` would cause infinite loops.

**Q: What is a ShellRoute in GoRouter?**
> A `ShellRoute` wraps multiple child routes in a shared parent widget (`AppShell`) that persists across navigation within those routes. We use it for the bottom navigation bar — navigating between Home, Timetable, Today, Holidays, Profile doesn't re-create the `AppShell` widget, preserving scroll positions and animations.

**Q: What is `NoTransitionPage` in GoRouter?**
> It's a `GoRouter` page type that disables the default slide/fade transition animation between routes. We use it for bottom navigation tab switches — tabs shouldn't animate like pages; they should switch instantly for a native feel.

**Q: What is `WidgetsBinding.instance.addPostFrameCallback`?**
> It schedules a callback to run after the current frame has been rendered. We use it in `initState` to trigger data-loading API calls. You can't call `ref.read(provider.notifier).loadData()` directly in `initState` because the widget tree isn't fully built yet — `addPostFrameCallback` ensures we wait until after the first frame.

**Q: How does the PDF generation work?**
> We use the `pdf` package which has its own layout engine (`pw.Widget` tree, similar to Flutter). We build a landscape A4 document with a grid table: rows are time periods, columns are weekdays. Each cell is populated from a pre-built `Map<day → Map<timeKey → slot>>` lookup. The `printing` package handles the OS-level print/share dialog.

**Q: What is Shimmer used for?**
> Shimmer creates a "skeleton loading" effect — grey animated placeholder shapes that match the approximate layout of the content being loaded. It gives users a visual cue that content is coming, which feels smoother than a blank screen or a spinner.

---

### Testing & Quality

**Q: What testing has been done?**
> The project includes `flutter_lints` for static analysis (enforcing Dart best practices). A `widget_test.dart` file exists as the testing entry point. The architecture (Riverpod + service layer) is designed to be testable: services can be mocked by overriding providers in `ProviderScope`, and state notifiers can be unit-tested without a UI.

**Q: What are flutter_lints?**
> `flutter_lints` is a set of lint rules recommended by the Flutter team. It enforces code style, catches common bugs (unused variables, unreachable code, unnecessary null checks), and ensures consistency. Rules are defined in `analysis_options.yaml`.

---

### Deployment & Configuration

**Q: How do you deploy this app to a new college?**
> 1. Set up the Node.js backend server on the college's server/cloud
> 2. Configure the Firebase project and add `google-services.json`
> 3. Build the Flutter APK/IPA
> 4. Install on devices
> 5. On first run, set the server URL in Profile settings to point to the college's server
> 6. Admin logs in, enters faculty/subjects/rooms data via management screens
> 7. Admin triggers timetable generation

**Q: What is `google-services.json`?**
> It's Firebase's configuration file for Android. It contains the Project ID, App ID, API keys, and other Firebase service credentials. It goes in `android/app/`. The iOS equivalent is `GoogleService-Info.plist`. These are never committed to version control (should be in `.gitignore`).

**Q: Why is the base URL pointing to a LAN IP?**
> `172.16.13.253` is a private LAN IP address. The app runs on physical Android devices connected to the same college WiFi network as the server. `localhost` doesn't work on a physical device (it would point to the phone itself), and the Android emulator default `10.0.2.2` doesn't work on physical devices either. The configurable server URL feature (in Profile screen) was added specifically to handle this flexibility.

---

*End of Report*

---

> **Prepared from full source code analysis of the ttapp Flutter project**  
> **Date:** 12 March 2026  
> **Project:** AI-Automated College Timetable Management System (TT Manager)
