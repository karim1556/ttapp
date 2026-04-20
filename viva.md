# TT Manager Viva Notes (Technical)

Prepared for quick revision before viva.
Project: TT Manager (AI Automated College Timetable Management System)

## 1) 60-Second Introduction Script
Our project, TT Manager, is a Flutter-based timetable management system for colleges with Admin, Faculty, and Student roles.
The app handles full timetable lifecycle: entity management (teachers, subjects, rooms, slots), automatic timetable generation, faculty constraints, substitutions, notifications, and export.
Architecture is layered: Flutter UI + Riverpod state + service layer + Dio API client + Node.js REST backend + SQL database.
The "AI" in our project is an explainable scheduling intelligence layer based on constraints and heuristics, not a black-box LLM. It performs automated conflict-free timetable generation and smart substitute-faculty recommendation.

## 1B) Ultra-Fast Revision (Read This If Only 1 Minute Left)
- Architecture: Flutter + Riverpod + GoRouter + Dio + Hive/SecureStorage + Node.js REST + SQL + Firebase notifications.
- Core value: automatic conflict-free timetable generation and day-level substitution management.
- AI claim: constraint optimization + heuristic ranking (explainable AI), not generative AI.
- Hard constraints: no faculty overlap, no room overlap, slot compatibility, lab continuity rules.
- Key admin APIs: /timetable/generate-all, /timetable/slots/:lectureId/move, /timetable/reports/classroom-usage.
- Reliability: local cache for timetable/holidays/substitutions, graceful fallback if Firebase or preview API fails.
- Security: JWT bearer, interceptor-based auth, local clear on 401.
- Differentiator: substitution overlay is date-scoped, so weekly master timetable remains stable.
- Export: premium PDF + Excel-compatible CSV.
- One-line summary: explainable AI scheduling system with production-oriented mobile architecture.

## 2) Problem Statement
Manual timetable creation causes:
- faculty conflicts (same teacher in multiple classes at same time)
- room conflicts
- unfair workload distribution
- slow re-scheduling when changes happen

Goal:
- reduce schedule preparation time
- enforce constraints automatically
- support day-level substitutions without regenerating full week
- keep system usable even with temporary network/backend instability

## 3) End-to-End Architecture

Frontend (Flutter)
- Presentation: feature screens under lib/features
- State: Riverpod StateNotifier providers under lib/providers
- Services: API and business logic under lib/services
- Data models: DTOs under lib/models
- Routing: GoRouter under lib/navigation
- Local persistence: Hive + Flutter Secure Storage

Backend (companion repo)
- Node.js REST APIs under /api
- JWT auth
- scheduling/generation engine
- room/faculty conflict validations for move/swap operations

Infra
- Firebase Cloud Messaging (push)
- flutter_local_notifications (foreground/local display)
- PDF and CSV export

High-level flow:
1. User authenticates and receives JWT
2. App stores token securely and fetches role-specific data
3. Admin triggers generation or manual edits
4. Backend validates constraints and returns schedule
5. App renders weekly/day views, supports export and notifications

## 4) Startup and Runtime Flow (Actual Implementation)

### 4.1 App boot sequence
- WidgetsFlutterBinding.ensureInitialized()
- try Firebase.initializeApp() (non-blocking if not configured)
- register Firebase background handler
- Hive.initFlutter()
- open boxes in parallel: user_box, timetable_box, settings_box
- run ProviderScope child app

### 4.2 Auth flow
- AuthStatus states: initial, loading, authenticated, unauthenticated, error
- On boot, app checks stored session with timeout
- Login API call: POST /auth/login
- Token + user persisted (secure storage + fallback)
- On logout: POST /auth/logout (best effort) then local clear

### 4.3 API client and security behavior
- Dio with base URL from serverUrlProvider (runtime editable from Profile)
- Auth interceptor injects Bearer token except login/refresh
- On HTTP 401: local session is cleared
- Error interceptor normalizes user-friendly error messages
- Debug logging enabled only in debug mode

### 4.4 Route protection
- GoRouter redirect logic:
  - while auth deciding, keep splash
  - unauthenticated users forced to /login
  - authenticated users redirected to /home
- AppShell provides role-aware bottom navigation:
  - Admin tabs include Admin panel
  - Others include Holidays

## 5) Feature Modules (Technical)

### 5.1 Timetable module
- Fetch weekly: GET /timetable/weekly
- Fetch today: GET /timetable/today
- Fetch faculty weekly: GET /timetable/faculty/:id
- Cache policy detail:
  - unfiltered weekly load may use cache first
  - filtered load always hits API to avoid stale division flashes
- UI supports day tabs, filters, detail sheet, drag-drop editing mode

### 5.2 Admin module
- One-click generation card
- Current call uses:
  - POST /timetable/generate-all
  - payload includes academicYear, branchIds, termType, divisions A/B
- Manual slot edit:
  - PUT /timetable/slots/:slotId
- Drag-drop move/swap:
  - PUT /timetable/slots/:lectureId/move
  - payload: targetSlotId, swap=true
- Room analytics:
  - GET /timetable/room/:room/weekly
  - GET /timetable/reports/classroom-usage

### 5.3 Faculty constraints module
- Faculty sets:
  - weekly work hours
  - max lectures/day
  - total lectures/week
  - unavailable slots
  - preferred slots
- Constraints saved via /constraints APIs
- Weekly cap is bounded by work-hours value in UI save logic

### 5.4 Substitution module (day-only override)
- Load substitutions by date/faculty
- Preview candidates API:
  - POST /substitutions/preview
- If preview API fails, local heuristic fallback computes candidates
- Create+approve substitution with temporaryOnly=true
- Overlay logic applies approved substitution to rendered slot copy only
  (weekly master timetable remains unchanged)

### 5.5 Notifications module
- Registers FCM token with backend: POST /notifications/token
- Subscribes to topics:
  - ttapp_all
  - user_{uid}
  - role_admin / role_faculty / role_student
- Maintains local inbox (read/unread/clear)
- Supports in-app local notifications (example: substitution approved)

### 5.6 Holidays module
- Fetches full and upcoming holidays
- Caches holiday list locally
- Today and Upcoming views computed from cached/API data

### 5.7 COPO module
- Course-outcome mappings CRUD
- Enrollment management (add/remove users mapped to course)
- Filter support by branch/semester/academic year

### 5.8 Export module
- PDF generation: branded landscape timetable with metrics
- CSV generation: Excel-compatible escaped CSV
- Includes branch/semester/division context in export naming and content

## 6) Core Entities (Data Model)
- UserModel: uid, email, user_type, token
- TimetableModel: day row for class scope
- TimeSlotModel: time range + lecture assignments
- LectureAssignmentModel: subject, faculty, type, room, substitution flag
- ConstraintModel: max/day, total/week, unavailable/preferred slots
- SubstitutionRecordModel: lecture/date substitute + status lifecycle
- SubjectModel, FacultyModel, RoomModel, TimeSlotTemplateModel

## 7) Where AI Is Used (Important Viva Section)

### 7.1 AI meaning in this project
This project uses AI in the form of automated decision-making and optimization over constraints (symbolic/heuristic AI), not generative text AI.

### 7.2 AI component 1: Timetable generation intelligence
- Admin triggers /timetable/generate or /timetable/generate-all
- Backend scheduler solves a constraint satisfaction/optimization problem
- Typical hard constraints:
  - no faculty time overlap
  - no room overlap
  - class and slot compatibility
  - lab continuity rules (lab blocks)
- Soft preferences can include workload balancing and faculty slot preferences

### 7.3 AI component 2: Substitution recommendation intelligence
When external preview API is unavailable, app uses local heuristic ranking:

score = 100 - conflictPenalty - loadPenalty

Implemented logic:
- conflictPenalty = 80 if overlapping assignment exists
- loadPenalty = 1.5 * weeklyLoad
- sort by non-conflict first, then higher score

So the system gives explainable recommendations, not random substitution.

### 7.4 Why this is still AI (and defend in viva)
If asked "This is just rules, where is AI?":
- In real-world scheduling, AI often means optimization under constraints.
- This is an operations-research style AI approach (CSP + heuristics).
- It is explainable, deterministic, and production-friendly for institutions.

### 7.5 What we did NOT claim
- No claim of LLM-based generation
- No claim of deep learning model training in current version
- We intentionally chose explainable scheduling AI due auditability needs in education

## 8) Security, Reliability, and Offline Strategy
- JWT-based protected APIs
- Secure storage for token; Hive fallback to avoid login lockouts
- Local caches for timetable/holidays/substitutions/notification inbox
- Graceful degradation if Firebase not configured
- On network/API failure, app preserves cached context where possible

Backend hardening (integration context):
- helmet middleware
- rate limiting
- CORS allowlist

## 9) Testing and Verification Talking Points
Current repo evidence:
- Unit test validates CSV export content
- Unit test validates PDF bytes are generated
- Widget smoke test placeholder exists

Also mention practical validation approach:
- generate timetable
- inspect conflicts via move/swap checks
- verify room usage report
- verify substitutions are date-scoped (do not mutate full week)

## 10) High-Probability Technical Viva Questions with Answers

### Architecture and flow
Q1. Why Flutter + Riverpod?
A1. Flutter gives cross-platform UI with one codebase; Riverpod provides compile-safe reactive state and better testability than context-dependent state.

Q2. Why GoRouter instead of manual Navigator push chains?
A2. GoRouter gives centralized route table, URL-style routing, and clean auth redirects.

Q3. How do you prevent unauthorized access to screens?
A3. Router redirect checks auth state and role-aware navigation limits access paths.

Q4. How is session restored on app restart?
A4. Auth provider checks persisted user + token from storage and transitions auth state accordingly.

Q5. What happens on HTTP 401?
A5. Auth interceptor clears local session to force a safe re-login.

Q6. Why keep server URL editable in profile?
A6. It supports LAN/dev/prod switching without rebuilding APK.

### Scheduling and AI
Q7. Is your AI generative AI?
A7. No. It is constraint-based optimization AI for timetable generation and recommendation.

Q8. What is the optimization objective?
A8. Produce a feasible timetable with zero hard conflicts and balanced/fair distribution under soft preferences.

Q9. Hard constraints vs soft constraints?
A9. Hard constraints must never be violated (room/faculty collision). Soft constraints are preferences (preferred slots, balance).

Q10. How do you handle faculty constraints?
A10. Faculty submit max/day, total/week, unavailable and preferred slots; scheduler consumes these inputs.

Q11. How is substitution candidate ranking done?
A11. API first; fallback heuristic penalizes time conflict heavily and high weekly load moderately.

Q12. Why day-only substitutions instead of editing weekly timetable?
A12. Operational safety: temporary changes should not rewrite baseline schedule.

Q13. Explain the fallback recommendation formula.
A13. score = 100 - 80*(conflict) - 1.5*(weeklyLoad), then rank non-conflict and high-score first.

Q14. How do you avoid lab-slot duplication in UI?
A14. Consecutive same-signature lab slots are collapsed into one visual block.

### APIs and data
Q15. Main generation endpoints?
A15. POST /timetable/generate and POST /timetable/generate-all.

Q16. How do you support room analytics?
A16. Weekly room schedule and classroom usage report endpoints are consumed and visualized.

Q17. How does drag-drop editing stay safe?
A17. Move/swap request is validated by backend conflict checks before commit.

Q18. How do you parse inconsistent backend JSON keys?
A18. Models include tolerant parsing for snake_case and camelCase variations.

Q19. Why keep local cache if server is source of truth?
A19. For fast startup and resilience during temporary network/backend issues.

Q20. How do you prevent stale cache showing wrong class when filters change?
A20. Filtered loads bypass cache and fetch directly from API.

### Security and notifications
Q21. How is token stored securely?
A21. FlutterSecureStorage with encrypted options; fallback storage exists only to preserve functionality under keystore failures.

Q22. Why subscribe to multiple FCM topics?
A22. Enables broadcast, role-targeted, and user-specific push channels.

Q23. Do you support notification audit inside app?
A23. Yes, inbox persists notification records with read/unread status.

### Performance and reliability
Q24. How do you keep UI responsive during generation?
A24. Non-blocking async calls with loading overlays and post-generation refresh.

Q25. What if Firebase is not configured?
A25. App still runs; notification features degrade gracefully.

Q26. What if substitution preview API fails?
A26. Local heuristic preview is used, ensuring continuity.

Q27. What if logout API fails?
A27. Local secure/session data is still cleared in finally block.

### Testing and maintainability
Q28. What automated tests exist?
A28. Export service tests for CSV/PDF and a widget smoke placeholder.

Q29. How is code organized for maintainability?
A29. Clear layered folders: features, providers, services, models, core, navigation.

Q30. What is one current limitation?
A30. AI scheduler internals are backend-side; frontend only consumes results and control APIs.

Q31. What is your immediate next technical improvement?
A31. Add integration tests for auth + timetable + substitution lifecycle with mocked backend.

Q32. Another advanced improvement?
A32. Add explainability payload from backend (why slot chosen, rejected constraints) for admin diagnostics.

Q33. How will you scale to more departments/divisions?
A33. Use generate-all batch mode, indexing/optimized queries backend-side, and paginated reporting APIs.

Q34. How do you ensure fairness among faculty?
A34. Constraints and load-based scoring/validation reduce over-assignment concentration.

Q35. Why call it AI in final report?
A35. Because the system automates complex scheduling decisions using constraint reasoning and heuristic optimization, which is a valid applied AI paradigm.

## 11) If External Asks "Show Me AI in Code"
Point to these concrete mechanics:
- Timetable generation trigger and optimization API contracts:
  - timetableProvider.generateAllTimetables
  - timetableService.generateAllTimetables
- Substitution candidate intelligence and scoring fallback:
  - substitutionService.previewCandidates
  - substitutionService._buildHeuristicCandidates
- Conflict detection primitives:
  - _facultyHasConflictOnSlot
  - _isTimeOverlap

## 12) 30-Second Closing Script
TT Manager solves a real institutional pain point by combining role-based operations, resilient mobile architecture, and explainable AI-style scheduling logic.
We focused on correctness first: no conflicts, auditable decisions, secure auth, and reliable fallback behavior.
The result is production-oriented and extensible for deeper optimization and analytics.
