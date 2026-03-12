class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';

  // Profile
  static const String profile = '/auth/profile';
  static const String updateProfile = '/auth/profile/update';

  // Timetable
  static const String timetable = '/timetable';
  static const String timetableWeekly = '/timetable/weekly';
  static const String timetableToday = '/timetable/today';
  static const String timetableGenerate = '/timetable/generate';
  static const String timetableUpdateSlot = '/timetable/slots';
  static const String timetableById = '/timetable'; // append /:id

  // Time Slots
  static const String timeSlots = '/timetable/slots';

  // Faculty
  static const String faculty = '/faculty';
  static const String facultyById = '/faculty'; // append /:id
  static const String facultyTimetable = '/faculty/timetable';

  // Subjects
  static const String subjects = '/subjects';
  static const String subjectById = '/subjects'; // append /:id

  // Constraints
  static const String constraints = '/constraints';
  static const String constraintsByFaculty = '/constraints/faculty'; // append /:id

  // Holidays
  static const String holidays = '/holidays';
  static const String upcomingHolidays = '/holidays/upcoming';

  // Rooms
  static const String rooms = '/rooms';
  static const String roomById = '/rooms'; // append /:id

  // Time Slot Templates
  static const String timeslotTemplates = '/timeslots';
  static const String timeslotTemplateById = '/timeslots'; // append /:id

  // Admin
  static const String adminStats = '/admin/stats';
  static const String adminBranches = '/admin/branches';
  static const String adminDivisions = '/admin/divisions';

  // Notification
  static const String saveFcmToken = '/notifications/token';

  // COPO
  static const String copo = '/copo';
}
