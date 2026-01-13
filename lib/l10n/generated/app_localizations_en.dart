// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Msarat Wasel Services';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get themeTitle => 'Theme';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get darkModeOn => 'On';

  @override
  String get darkModeOff => 'Off';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageName => 'English';

  @override
  String get accountTitle => 'Account';

  @override
  String get logout => 'Logout';

  @override
  String get logoutSubtitle => 'Logout from current account';

  @override
  String get aboutTitle => 'About';

  @override
  String get welcome => 'Welcome,';

  @override
  String get greetingMorning => 'Good morning! Have a great day';

  @override
  String get greetingAfternoon => 'Good afternoon! Keep it up';

  @override
  String get greetingEvening => 'Good evening! Have a nice day';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get myStudents => 'My Students';

  @override
  String get scanAttendance => 'Scan Attendance';

  @override
  String get attendanceHistory => 'Attendance History';

  @override
  String get reports => 'Reports';

  @override
  String get comingSoon => 'Coming soon...';

  @override
  String get studentCount => 'Student Count';

  @override
  String get presentToday => 'Present Today';

  @override
  String get absentToday => 'Absent Today';

  @override
  String get user => 'User';

  @override
  String get home => 'Home';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get totalStudents => 'Total Students';

  @override
  String get averageAttendance => 'Average Attendance';

  @override
  String get studentsList => 'Students List';

  @override
  String get noStudentsFound => 'No students match the search';

  @override
  String get searchPlaceholder => 'Search by name or ID...';

  @override
  String get all => 'All';

  @override
  String get atHome => 'At Home';

  @override
  String get onBus => 'On Bus';

  @override
  String get atSchool => 'At School';

  @override
  String get absent => 'Absent';

  @override
  String get tripProgress => 'Trip Progress';

  @override
  String deliveredStudentsCount(int atSchool, int total) {
    return 'Delivered $atSchool of $total students';
  }

  @override
  String get remaining => 'Remaining';

  @override
  String get percentage => 'Percentage';

  @override
  String get boardedBus => 'Boarded Bus';

  @override
  String get reachedSchool => 'Reached School';

  @override
  String get arrivedSafely => 'Arrived Safely';

  @override
  String guardianLabel(String name) {
    return 'Guardian: $name';
  }

  @override
  String get dailyChecklistTitle => 'Daily Tasks List';

  @override
  String get tasksSavedSuccessfully => 'Tasks saved successfully';

  @override
  String get confirmAndSendReport => 'Confirm and Send Report';

  @override
  String get checklistTask1 => 'Ensure all students have seatbelts fastened';

  @override
  String get checklistTask2 =>
      'Review bus cleanliness before and after the trip';

  @override
  String get checklistTask3 => 'Ensure the bus is completely empty of students';

  @override
  String get checklistTask4 => 'Check for forgotten student bags';

  @override
  String get checklistTask5 =>
      'Ensure the air conditioning/ventilation system is working';

  @override
  String get incidentReportTitle => 'Incident Report';

  @override
  String get incidentType => 'Incident Type';

  @override
  String get problemDescription => 'Problem Description';

  @override
  String get reportDetailsPlaceholder => 'Write report details here...';

  @override
  String get attachPhotoOptional => 'Attach photo (optional)';

  @override
  String get reportSentSuccessfully => 'Report sent to management immediately';

  @override
  String get sendUrgentReport => 'Send Urgent Report';

  @override
  String get incidentTypeBehavioral => 'Behavioral';

  @override
  String get incidentTypeHealth => 'Health';

  @override
  String get incidentTypeTechnical => 'Technical Failure';

  @override
  String get incidentTypeTraffic => 'Traffic Accident';

  @override
  String get incidentTypeOther => 'Other';

  @override
  String get reportsTitle => 'Reports & Statistics';

  @override
  String get dailyAverageAttendance => 'Daily Avg Attendance';

  @override
  String get absenceRate => 'Absence Rate';

  @override
  String get lateRate => 'Late Rate';

  @override
  String get attendanceTrend => 'Attendance Trend';

  @override
  String get insights => 'Insights & Analytics';

  @override
  String insightPerfectAttendance(String className) {
    return 'Class $className has perfect attendance today!';
  }

  @override
  String insightLowAttendance(int percentage) {
    return 'Attendance dropped by $percentage% compared to yesterday';
  }

  @override
  String get attendanceToday => 'Attendance Today';

  @override
  String get absenceToday => 'Absence Today';

  @override
  String get weeklyAttendanceTrend => 'Weekly Attendance Trend';

  @override
  String get smartInsight => 'Smart Insight';

  @override
  String get excellentAttendanceInsight =>
      'Attendance performance is excellent this week! Keep it up.';

  @override
  String get lowAttendanceInsight =>
      'There is a slight drop in attendance. You might want to check the reasons.';
}
