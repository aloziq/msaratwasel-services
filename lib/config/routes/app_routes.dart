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
  static const helpCenter = '/help-center';
  static const reports = '/reports';
  static const profile = '/profile';
  static const assistantHome = '/assistant';
  static const busStudents = '/bus-students';
  static const dailyChecklist = '/daily-checklist';
  static const incidentReport = '/incident-report';
  static const busMap = '/bus-map';
  static const messages = '/messages';
  static const chats = '/chats';

  // Field Supervisor routes
  static const supervisorHome = '/supervisor';
  static const supervisorBuses = '/supervisor/buses';
  static const supervisorDrivers = '/supervisor/drivers';
  static const supervisorAlerts = '/supervisor/alerts';
  static const supervisorInspection = '/supervisor/inspection';
  static const supervisorDelays = '/supervisor/delays';
  static const supervisorTrips = '/supervisor/trips';
  static const supervisorReports = '/supervisor/reports';
  static const supervisorTracking = '/supervisor/tracking/:busId';

  // Driver routes
  static const driverHome = '/driver/home';
  static const driverRoute = '/driver/route';
  static const driverMaintenance = '/driver/maintenance';
  static const driverFuel = '/driver/maintenance/fuel';
  static const driverMaintenanceRequest = '/driver/maintenance/request';
  static const driverMaintenanceLogs = '/driver/maintenance/logs';
  static const driverEndTrip = '/driver/end-trip';
  static const driverEndTripBarcode = '/driver/end-trip/barcode';
  static const driverEndTripManual = '/driver/end-trip/manual';
  static const driverStudents = '/driver/students';
  static const driverTrips = '/driver/trips';

  /// Helper to generate class details path with classId
  static String classDetailsPath(String classId) => '/class/$classId';
  static String supervisorTrackingPath(String busId) => '/supervisor/tracking/$busId';
}
