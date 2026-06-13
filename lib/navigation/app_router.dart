import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/timetable/screens/timetable_screen.dart';
import '../features/today/screens/today_screen.dart';
import '../features/holidays/screens/holidays_screen.dart';
import '../features/admin/screens/admin_panel_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/faculty/screens/faculty_constraints_screen.dart';
import '../features/admin/screens/manage_teachers_screen.dart';
import '../features/admin/screens/manage_subjects_screen.dart';
import '../features/copo/screens/copo_screen.dart';
import '../features/admin/screens/manage_rooms_screen.dart';
import '../features/admin/screens/manage_timeslots_screen.dart';
import '../features/admin/screens/room_reports_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/substitutions/screens/substitutions_screen.dart';
import '../features/admin/screens/manage_temporary_timetable_screen.dart';
import '../features/admin/screens/room_timetable_screen.dart';
import '../features/admin/screens/lab_timetable_screen.dart';
import '../features/admin/screens/teacher_timetable_screen.dart';
import '../widgets/app_shell.dart';

// Route names
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String timetable = '/timetable';
  static const String today = '/today';
  static const String holidays = '/holidays';
  static const String profile = '/profile';
  static const String adminPanel = '/admin';
  static const String manageTeachers = '/admin/teachers';
  static const String manageSubjects = '/admin/subjects';
  static const String facultyConstraints = '/faculty/constraints';
  static const String copo = '/admin/copo';
  static const String manageRooms = '/admin/rooms';
  static const String manageTimeslots = '/admin/timeslots';
  static const String roomReports = '/admin/rooms/reports';
  static const String substitutions = '/substitutions';
  static const String notifications = '/notifications';
  static const String manageTemporaryTimetable = '/admin/temporary-timetable';
  static const String roomTimetable = '/admin/room-timetable';
  static const String labTimetable = '/admin/lab-timetable';
  static const String teacherTimetable = '/admin/teacher-timetable';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _AuthChangeNotifier(ref),
    redirect: (context, state) {
      final currentState = ref.read(authProvider);
      final isLoggedIn = currentState.isAuthenticated;
      final isLoginPage = state.matchedLocation == AppRoutes.login;
      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isBootstrapping = currentState.status == AuthStatus.initial;
      final isRestoringOnSplash =
          isSplash && currentState.status == AuthStatus.loading;

      // Keep splash only while app is deciding whether a stored session exists.
      if (isBootstrapping || isRestoringOnSplash) {
        return isSplash ? null : AppRoutes.splash;
      }
      if (!isLoggedIn && !isLoginPage) return AppRoutes.login;
      if (isLoggedIn && (isLoginPage || isSplash)) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const _SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: AppRoutes.timetable,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TimetableScreen()),
          ),
          GoRoute(
            path: AppRoutes.today,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TodayScreen()),
          ),
          GoRoute(
            path: AppRoutes.holidays,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HolidaysScreen()),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
          GoRoute(
            path: AppRoutes.adminPanel,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AdminPanelScreen()),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: NotificationsScreen()),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.manageTeachers,
        builder: (context, state) => const ManageTeachersScreen(),
      ),
      GoRoute(
        path: AppRoutes.manageSubjects,
        builder: (context, state) => const ManageSubjectsScreen(),
      ),
      GoRoute(
        path: AppRoutes.facultyConstraints,
        builder: (context, state) {
          final isAdmin = ref.read(isAdminProvider);
          if (!isAdmin) {
            return const Scaffold(
              body: Center(child: Text('Access denied')),
            );
          }
          return const FacultyConstraintsScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.copo,
        builder: (context, state) => const CopoScreen(),
      ),
      GoRoute(
        path: AppRoutes.manageRooms,
        builder: (context, state) => const ManageRoomsScreen(),
      ),
      GoRoute(
        path: AppRoutes.roomReports,
        builder: (context, state) => const RoomReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.manageTimeslots,
        builder: (context, state) => const ManageTimeslotsScreen(),
      ),
      GoRoute(
        path: AppRoutes.substitutions,
        builder: (context, state) => const SubstitutionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.manageTemporaryTimetable,
        builder: (context, state) => const ManageTemporaryTimetableScreen(),
      ),
      GoRoute(
        path: AppRoutes.roomTimetable,
        builder: (context, state) => const RoomTimetableScreen(),
      ),
      GoRoute(
        path: AppRoutes.labTimetable,
        builder: (context, state) => const LabTimetableScreen(),
      ),
      GoRoute(
        path: AppRoutes.teacherTimetable,
        builder: (context, state) => const TeacherTimetableScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
  );
});

class _AuthChangeNotifier extends ChangeNotifier {
  final Ref _ref;
  late final ProviderSubscription<AuthState> _subscription;

  _AuthChangeNotifier(this._ref) {
    _subscription = _ref.listen<AuthState>(authProvider, (previous, next) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              color: Colors.white,
              size: 72,
            ),
            const SizedBox(height: 24),
            Text(
              'TT Manager',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI-Powered Timetable System',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
