/// Route paths and names for the application.
///
/// This file centralizes all route definitions to ensure type-safety
/// and easy maintenance.
abstract class AppRoutes {
  // Auth routes
  static const login = '/login';
  static const resetPassword = '/reset-password';

  // Teacher routes
  static const teacherHome = '/';
  static const classDetails = '/class/:classId';
  static const myClasses = '/my-classes';
  static const attendanceHistory = '/attendance-history';
  static const settings = '/settings';
  static const qrScan = '/qr-scan';
  static const reports = '/reports';
  static const profile = '/profile';
  static const assistantHome = '/assistant';
  static const busStudents = '/bus-students';
  static const dailyChecklist = '/daily-checklist';
  static const incidentReport = '/incident-report';
  static const busMap = '/bus-map';

  /// Helper to generate class details path with classId
  static String classDetailsPath(String classId) => '/class/$classId';
}
