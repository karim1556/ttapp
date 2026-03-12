class AppConstants {
  AppConstants._();

  // Base URL — update to match your backend
  // static const String baseUrl = 'http://10.0.2.2:3000/api'; // Android emulator
  // static const String baseUrl = 'http://localhost:3000/api'; // iOS simulator / Chrome / macOS
  static const String baseUrl = 'http://172.16.13.253:3000/api'; // Physical Android device (LAN)
  // ↑ This is now just the default fallback. Change server URL in app Profile → Server URL.
  // static const String baseUrl = 'https://your-production-url.com/api';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // User Types
  static const int userTypeAdmin = 1;
  static const int userTypeTeacher = 2;
  static const int userTypeStudent = 3;

  // Lecture Types
  static const String lectureTypeTheory = 'Theory';
  static const String lectureTypeLab = 'Lab';
  static const String lectureTypeExtra = 'Extra';

  // Days of Week
  static const List<String> daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  static const List<String> daysShort = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  // Holiday types
  static const String holidayTypeNational = 'National';
  static const String holidayTypeInstitute = 'Institute';
  static const String holidayTypeFestival = 'Festival';
  static const String holidayTypeWeekend = 'Weekend';

  // App name
  static const String appName = 'TT Manager';
}
