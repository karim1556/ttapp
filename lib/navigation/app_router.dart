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
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _AuthChangeNotifier(ref),
    redirect: (context, state) {
      final currentState = ref.read(authProvider);
      final isLoggedIn = currentState.isAuthenticated;
      final isLoading = currentState.status == AuthStatus.initial ||
          currentState.status == AuthStatus.loading;
      final isLoginPage = state.matchedLocation == AppRoutes.login;
      final isSplash = state.matchedLocation == AppRoutes.splash;

      if (isLoading) return AppRoutes.splash;
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
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.timetable,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TimetableScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.today,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TodayScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.holidays,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HolidaysScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.adminPanel,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AdminPanelScreen(),
            ),
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
        builder: (context, state) => const FacultyConstraintsScreen(),
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
        path: AppRoutes.manageTimeslots,
        builder: (context, state) => const ManageTimeslotsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});

class _AuthChangeNotifier extends ChangeNotifier {
  final Ref _ref;
  late final ProviderSubscription<AuthState> _subscription;

  _AuthChangeNotifier(this._ref) {
    _subscription = _ref.listen<AuthState>(authProvider, (_, __) {
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
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                  ),
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
