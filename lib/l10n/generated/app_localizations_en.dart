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
  String get dailyChecklist => 'Daily Checklist';

  @override
  String get busTracking => 'Bus Tracking';

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

  @override
  String get editProfile => 'Edit personal info';

  @override
  String get changePassword => 'Change password';

  @override
  String get changeChildrenLocation => 'Change Children Location';

  @override
  String get manageKids => 'Manage registered students';

  @override
  String get locationChangeWarningTitle => 'Important Notice';

  @override
  String get locationChangeWarningBody =>
      'Please note that if the location is changed, the school must be notified 48 hours prior to the change to ensure transport arrangements.';

  @override
  String get cancel => 'Cancel';

  @override
  String get proceed => 'Proceed';

  @override
  String get appearance => 'Appearance';

  @override
  String get activitiesSubtitle => 'Latest school updates and announcements.';

  @override
  String get helpCenter => 'Help center';

  @override
  String get contactUs => 'Contact us';

  @override
  String get aboutApp => 'About app';

  @override
  String get canteen => 'Canteen';

  @override
  String get support => 'Support';

  @override
  String get appName => 'Msarat Wasel';

  @override
  String get version => 'Version';

  @override
  String get aboutAppDescription =>
      'Msarat Wasel is the ideal solution for managing school transport effectively and safely. It allows parents to track their children and receive real-time notifications, ensuring peace of mind and student safety.';

  @override
  String get aboutCompanyTitle => 'About Wasel Company';

  @override
  String get aboutCompany =>
      'Wasel School Transport is a leading company in transport services, striving to provide a safe and comfortable transport experience for students while employing the latest technologies to ensure quality and reliability.';

  @override
  String get developedBy => 'Developed by';

  @override
  String get contactMethods => 'Contact Methods';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get email => 'Email';

  @override
  String get website => 'Website';

  @override
  String get socialMedia => 'Social Media';

  @override
  String get complaintsBox => 'Complaints & Suggestions Box';

  @override
  String get complaintMessageHint =>
      'Write your suggestion or complaint here...';

  @override
  String get submit => 'Submit';

  @override
  String get complaintSent => 'Your message has been sent successfully';

  @override
  String get currentPassword => 'Current password';

  @override
  String get fieldRequired => 'Required';

  @override
  String get newPassword => 'New password';

  @override
  String get passwordLengthError => 'Must be at least 6 characters';

  @override
  String get confirmPassword => 'Confirm new password';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get passwordUpdatedSuccess => 'Password updated successfully';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get privacyIntroTitle => 'First: Introduction';

  @override
  String get privacyIntroBody1 =>
      'This document represents a legal agreement between the application users (Guardian, Student, Driver, Supervisor, Teacher, Field Supervisor, School) and the application administration.';

  @override
  String get privacyIntroBody2 =>
      'By using the application, all users acknowledge their agreement to this policy and commitment to it.';

  @override
  String get privacyDataCollectionTitle => 'Second: Data Collection';

  @override
  String get privacyStudentDataTitle => 'Student Data:';

  @override
  String get privacyStudentData1 => 'Full Name';

  @override
  String get privacyStudentData2 => 'School ID';

  @override
  String get privacyStudentData3 => 'Civil ID';

  @override
  String get privacyStudentData4 => 'Student Photo';

  @override
  String get privacyStudentData5 => 'Home Photo';

  @override
  String get privacyStudentData6 => 'Bus Geographic Location';

  @override
  String get privacyStudentData7 => 'Attendance Log via Barcode';

  @override
  String get privacyOtherDataTitle => 'Other Data:';

  @override
  String get privacyOtherData1 =>
      'Guardian Data: Name, Phone Number, Email, Civil ID.';

  @override
  String get privacyOtherData2 =>
      'Driver, Supervisor, and Teacher Data: Name, ID/Job Number, Contact Info.';

  @override
  String get privacyOtherData3 =>
      'Technical Data: Login Log, Barcode Usage, Bus Geographic Location.';

  @override
  String get privacyDataUsageTitle => 'Third: Data Usage';

  @override
  String get privacyDataUsage1 =>
      'Ensuring student safety during school transport.';

  @override
  String get privacyDataUsage2 => 'Enabling guardians to track student status.';

  @override
  String get privacyDataUsage3 =>
      'Managing school transport operations efficiently.';

  @override
  String get privacyDataUsage4 =>
      'Issuing reports for the school and supervisors.';

  @override
  String get privacyDataUsage5 =>
      'Data is not used for any commercial or promotional purposes.';

  @override
  String get privacyDataProtectionTitle => 'Fourth: Data Protection';

  @override
  String get privacyDataProtection1 =>
      'Storing data in secure servers using encryption technologies.';

  @override
  String get privacyDataProtection2 =>
      'Restricting access to data according to user permissions.';

  @override
  String get privacyDataProtection3 =>
      'Periodic review of security procedures.';

  @override
  String get privacyDataProtection4 =>
      'Not sharing data with third parties unless approved by the school or required by law.';

  @override
  String get privacyUserRightsTitle => 'Fifth: User Rights';

  @override
  String get privacyUserRights1 => 'The right to access their data.';

  @override
  String get privacyUserRights2 =>
      'The right to request correction or deletion of inaccurate data.';

  @override
  String get privacyUserRights3 =>
      'The right to object to the use of their data for non-educational purposes.';

  @override
  String get privacyUserObligationsTitle => 'Sixth: User Obligations';

  @override
  String get privacyUserObligations1 =>
      'Using the application only for educational and school transport purposes.';

  @override
  String get privacyUserObligations2 =>
      'Not sharing login credentials with other parties.';

  @override
  String get privacyUserObligations3 =>
      'Adhering to local laws regarding data protection.';

  @override
  String get privacyLegalLiabilityTitle => 'Seventh: Legal Liability';

  @override
  String get privacyLegalLiability1 =>
      'The application is not responsible for any unauthorized use by users.';

  @override
  String get privacyLegalLiability2 =>
      'The school bears the responsibility of managing user permissions.';

  @override
  String get privacyLegalLiability3 =>
      'Any security breach will be dealt with according to local laws (including Royal Decree No. 6/2022 on Personal Data Protection in Oman).';

  @override
  String get privacyAmendmentsTitle => 'Eighth: Amendments';

  @override
  String get privacyAmendments1 =>
      'The application administration reserves the right to amend this policy in accordance with laws and technical developments.';

  @override
  String get privacyAmendments2 =>
      'Users will be notified of any substantial changes.';

  @override
  String get privacyConsentTitle => 'Ninth: Consent';

  @override
  String get privacyConsentBody =>
      'By using the application, all users agree to this policy and adhere to it.';

  @override
  String get privacySimplifiedTitle => '📱 Simplified Version for Users';

  @override
  String get privacyQ1 => 'Why do we collect data?';

  @override
  String get privacyA1 =>
      '- To ensure student safety during the trip.\n- To help the guardian track the student\'s arrival and departure.\n- To facilitate the work of the driver, supervisor, teacher, and field supervisor.';

  @override
  String get privacyQ2 => 'What data do we use?';

  @override
  String get privacyA2 =>
      '- Student name and school number.\n- Civil ID and student photo for identity verification.\n- Home photo and bus geographic location.\n- Student attendance log via barcode.\n- Guardian data for communication.\n- Driver, supervisor, and teacher data.';

  @override
  String get privacyQ3 => 'How do we protect your data?';

  @override
  String get privacyA3 =>
      '- We store information in secure and encrypted systems.\n- We do not share your data with any external party unless approved by the school or required by law.\n- We define access permissions so each user only sees what they need for their work.';

  @override
  String get privacyQ4 => 'Your Rights';

  @override
  String get privacyA4 =>
      '- You can access your data.\n- You can request correction or deletion of incorrect data.\n- Your data will not be used for any commercial or promotional purposes.';

  @override
  String get privacyQ5 => 'Your Obligations';

  @override
  String get privacyA5 =>
      '- Use the application only for school transport.\n- Do not share your account or login details with others.\n- Adhere to local laws regarding data protection.';

  @override
  String get application => 'Application';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get notifications => 'Notifications';

  @override
  String get chats => 'Chats';

  @override
  String get location => 'Location';

  @override
  String get speed => 'Speed';

  @override
  String get distance => 'Distance';

  @override
  String get remainingTime => 'Remaining';

  @override
  String get busStateAtStation => 'At Station';

  @override
  String get busStateEnRoute => 'En Route';

  @override
  String get busStateArrived => 'Arrived';

  @override
  String get kmPerHour => 'km/h';

  @override
  String get km => 'km';

  @override
  String get minutes => 'min';

  @override
  String get refresh => 'Refresh';

  @override
  String get updated => 'Updated';
}
