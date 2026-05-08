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
  String get attachPhotoOptional => 'Attach Photo (Optional)';

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
  String get systemDefault => 'System';

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

  @override
  String get driversAndSupervisors => 'Drivers & Supervisors';

  @override
  String get drivers => 'Drivers';

  @override
  String get supervisors => 'Supervisors';

  @override
  String get bus => 'Bus';

  @override
  String get fieldSupervisor => 'Field Supervisor';

  @override
  String get supervisorRole => 'Field Supervisor';

  @override
  String get incidentsAndEmergencies => 'Incidents & Emergencies';

  @override
  String get fieldInspection => 'Field Inspection';

  @override
  String get registerDelays => 'Register Delays';

  @override
  String get dailyTrips => 'Daily Trips';

  @override
  String get selectBus => 'Select Bus';

  @override
  String get inspectionChecklist => 'Inspection Checklist';

  @override
  String get takePhotos => 'Take Photos';

  @override
  String get inspectionSaved => 'Inspection Saved Successfully';

  @override
  String get saveInspection => 'Save Inspection';

  @override
  String get completedTrips => 'Completed Trips';

  @override
  String get issues => 'Issues';

  @override
  String get delays => 'Delays';

  @override
  String get violations => 'Violations';

  @override
  String get reportCategories => 'Report Categories';

  @override
  String get viewAllTrips => 'View All Trips';

  @override
  String get viewAllIssues => 'View All Issues';

  @override
  String get viewAllDelays => 'View All Delays';

  @override
  String get viewAllViolations => 'View All Violations';

  @override
  String get fieldTrips => 'Field Trips';

  @override
  String get viewFieldTrips => 'View Field Trips';

  @override
  String get todayTrips => 'Today\'s Trips';

  @override
  String get trips => 'Trips';

  @override
  String get addNote => 'Add Note';

  @override
  String get viewOnMap => 'View on Map';

  @override
  String get trafficJam => 'Traffic Jam';

  @override
  String get technicalIssue => 'Technical Issue';

  @override
  String get studentLate => 'Student Late';

  @override
  String get other => 'Other';

  @override
  String get delaySavedAndReported => 'Delay Saved and Reported';

  @override
  String get saveAndSend => 'Save and Send';

  @override
  String get upcomingTrips => 'Upcoming Trips';

  @override
  String get driver => 'Driver';

  @override
  String get communication => 'Communication';

  @override
  String get activeBuses => 'Active Buses';

  @override
  String get activeDrivers => 'Active Drivers';

  @override
  String get activeTrips => 'Active Trips';

  @override
  String get activeEmergency => 'Active Emergency';

  @override
  String get respond => 'Respond';

  @override
  String get allIncidents => 'All Incidents';

  @override
  String get newIncident => 'New Incident';

  @override
  String get incidentDescription => 'Incident Description';

  @override
  String get attachPhoto => 'Attach Photo';

  @override
  String get incidentReported => 'Incident Reported Successfully';

  @override
  String get pendingInspections => 'Pending Inspections';

  @override
  String get busesNeedInspection => 'Buses Need Inspection';

  @override
  String get recentInspections => 'Recent Inspections';

  @override
  String get newInspection => 'New Inspection';

  @override
  String get totalBuses => 'Total Buses';

  @override
  String get stoppedBuses => 'Stopped Buses';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get broadcastMessage => 'Broadcast Message';

  @override
  String get sendToAll => 'Send to All';

  @override
  String get recentChats => 'Recent Chats';

  @override
  String get studentDelays => 'Student Delays';

  @override
  String get busDelays => 'Bus Delays';

  @override
  String get reportSent => 'Report Sent Successfully';

  @override
  String get registerNewDelay => 'Register New Delay';

  @override
  String get student => 'Student';

  @override
  String get selectStudent => 'Select Student';

  @override
  String get delayDuration => 'Delay Duration (min)';

  @override
  String get delayReason => 'Delay Reason';

  @override
  String get present => 'Present';

  @override
  String get finishAttendance => 'Finish Attendance';

  @override
  String get attendanceSummary => 'Attendance Summary';

  @override
  String get confirmSendReport =>
      'Do you want to finish attendance and send the report?';

  @override
  String get total => 'Total';

  @override
  String get unmarked => 'Unmarked';

  @override
  String unmarkedStudentsWarning(int count) {
    return 'There are $count students whose status is unmarked';
  }

  @override
  String get confirmSend => 'Confirm Send';

  @override
  String get dailyReportSentSuccess => 'Daily report sent successfully';

  @override
  String get classPlaceholder => '4th Grade - A';

  @override
  String get parentGuardian => 'Parent/Guardian';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get sosAlertsTitle => 'Incident Report';

  @override
  String get sosAlertsStatusPending => 'Pending';

  @override
  String get sosAlertsStatusResolved => 'Resolved';

  @override
  String get sosAlertsStatusActive => 'Active';

  @override
  String sosAlertsTimeAgo(String time) {
    return '$time ago';
  }

  @override
  String get login => 'Login';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get civilId => 'Civil ID';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get enterCivilId => 'Please enter Civil ID';

  @override
  String get enterPassword => 'Please enter password';

  @override
  String get unexpectedError => 'An unexpected error occurred';

  @override
  String get selectCorrectRole => 'Please select the correct role to login';

  @override
  String get resetPasswordSuccess => 'Password reset link sent successfully!';

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String get resetPasswordSubtitle => 'Enter your ID to recover your account';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get maintenance => 'Maintenance';

  @override
  String get fuelRefill => 'Fuel Refill';

  @override
  String get maintenanceRequest => 'Maintenance Request';

  @override
  String get statusActive => 'Active';

  @override
  String get statusStopped => 'Stopped';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get statusScheduled => 'Scheduled';

  @override
  String get statusMaintenance => 'Maintenance';

  @override
  String get statusExcellent => 'Excellent';

  @override
  String get statusGood => 'Good';

  @override
  String get statusPending => 'Pending';

  @override
  String get typeTechnical => 'Technical';

  @override
  String get typeBehavioral => 'Behavioral';

  @override
  String get typeHealth => 'Health';

  @override
  String get typeTraffic => 'Traffic';

  @override
  String get typeSOS => 'SOS';

  @override
  String get roleAdmin => 'Administration';

  @override
  String get roleDriver => 'Driver';

  @override
  String get late => 'Late';

  @override
  String get myClasses => 'My Classes';

  @override
  String busNumber(int number) {
    return 'Bus $number';
  }

  @override
  String get call => 'Call';

  @override
  String get sendMessage => 'Send Message';

  @override
  String get details => 'Details';

  @override
  String get notes => 'Notes';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get status => 'Status';

  @override
  String get type => 'Type';

  @override
  String get description => 'Description';

  @override
  String get actions => 'Actions';

  @override
  String get todayAttendance => 'Today\'s Attendance';

  @override
  String get classAttendance => 'Class Attendance';

  @override
  String get takeAttendance => 'Take Attendance';

  @override
  String get markPresent => 'Mark Present';

  @override
  String get markAbsent => 'Mark Absent';

  @override
  String get noDataFound => 'No data found';

  @override
  String get loadingData => 'Loading data...';

  @override
  String get retry => 'Retry';

  @override
  String get confirm => 'Confirm';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get done => 'Done';

  @override
  String get close => 'Close';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get save => 'Save';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get sort => 'Sort';

  @override
  String get morning => 'Morning';

  @override
  String get afternoon => 'Afternoon';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get thisWeek => 'This Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get connectionError => 'Connection error';

  @override
  String get tryAgain => 'Try again';

  @override
  String get noInternet => 'No internet connection';

  @override
  String get successMessage => 'Operation successful';

  @override
  String get savedSuccessfully => 'Saved successfully';

  @override
  String get deletedSuccessfully => 'Deleted successfully';

  @override
  String get sentSuccessfully => 'Sent successfully';

  @override
  String get attendanceMarked => 'Attendance marked successfully';

  @override
  String get navigation => 'Navigation';

  @override
  String get endTrip => 'End Trip';

  @override
  String get roleBusAssistant => 'Bus Assistant';

  @override
  String get roleFieldSupervisor => 'Field Supervisor';

  @override
  String get roleTeacher => 'Teacher';

  @override
  String get driverLogin => 'Driver Login';

  @override
  String get assistantLogin => 'Assistant Login';

  @override
  String get supervisorLogin => 'Supervisor Login';

  @override
  String get teacherLogin => 'Teacher Login';

  @override
  String get maintenanceLog => 'Maintenance Log';

  @override
  String get theDriver => 'Driver';

  @override
  String get driversGroup => 'Drivers Group';

  @override
  String get dailyRecord => 'Daily Record';

  @override
  String get presentStudents => 'Present Students';

  @override
  String get parentPhone => 'Phone Number';

  @override
  String get parentGuardianLabel => 'Parent/Guardian';

  @override
  String get students => 'Students';

  @override
  String get sos => 'SOS';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get amount => 'Amount';

  @override
  String get boarded => 'Boarded';

  @override
  String get pleaseEnterCivilId => 'Please enter civil ID';

  @override
  String get pleaseEnterPassword => 'Please enter password';

  @override
  String get readyToStart => 'Ready to Start';

  @override
  String get departureTime => 'Departure';

  @override
  String get startTrip => 'Start Trip';

  @override
  String get endTripTitle => 'End Trip';

  @override
  String get confirmEndTrip => 'Are you sure you want to end the trip?';

  @override
  String get tripEndedSuccess => 'Trip ended successfully!';

  @override
  String get scanFrontCode => 'Scan Front Code';

  @override
  String get scanBackCode => 'Scan Back Code';

  @override
  String get scanFrontDesc =>
      'Scan the QR code located at the front of the bus.';

  @override
  String get scanBackDesc => 'Scan the QR code located at the back of the bus.';

  @override
  String get recordVideo => 'Record Video';

  @override
  String get recordVideoDesc =>
      'Record a video walking from front to back to ensure bus is empty.';

  @override
  String get nextStop => 'Next Stop';

  @override
  String get arriveAtStudent => 'Arrive at Student';

  @override
  String get nextDestination => 'Next Destination';

  @override
  String get probableAbsence => 'Probable Absence';

  @override
  String get fuelRefillTitle => 'Fuel Refill';

  @override
  String get attachReceipt => 'Attach Receipt Photo';

  @override
  String get odometerReading => 'Odometer Reading (km)';

  @override
  String get recentLogs => 'Recent Logs';

  @override
  String get fuelEntry => 'Fuel Entry';

  @override
  String get requestMaintenance => 'Request Maintenance';

  @override
  String get maintenanceRequestSubmitted =>
      'Maintenance request submitted successfully';

  @override
  String get reRecord => 'Re-record';

  @override
  String get videoRecorded => 'Video Recorded';

  @override
  String get busEmptyCheck => 'Bus Empty Check';

  @override
  String get maintenanceRequestTitle => 'Maintenance Request';

  @override
  String get estimatedCost => 'Estimated Cost';

  @override
  String get requestSentSuccess => 'Request sent successfully';

  @override
  String get dataSavedSuccess => 'Data saved successfully';

  @override
  String get pleaseAttachPhoto => 'Please attach a photo';

  @override
  String get enterValidNumber => 'Please enter valid number';

  @override
  String get enterAmount => 'Please enter amount';

  @override
  String get enterOdometer => 'Please enter odometer reading';

  @override
  String get describeProblem => 'Please describe the problem';

  @override
  String get submitRequest => 'Submit Request';

  @override
  String get studentStatistics => 'Student Statistics';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get searchStudentPlaceholder => 'Search for a student...';

  @override
  String get fontSize => 'Font Size';

  @override
  String get fontSizeSmall => 'Small';

  @override
  String get fontSizeMedium => 'Medium';

  @override
  String get fontSizeLarge => 'Large';

  @override
  String get incorrectPassword => 'Incorrect password';

  @override
  String get civilIdNotRegistered => 'This civil ID is not registered';

  @override
  String civilIdRegisteredAs(String role) {
    return 'This civil ID is registered as $role';
  }

  @override
  String get loginFailed => 'Login failed: Invalid credentials';

  @override
  String get guest => 'Guest';

  @override
  String get clearFilter => 'Clear Filter';

  @override
  String get searchByDate => 'Search by Date';

  @override
  String get noRecordsForDate => 'No records for this date';

  @override
  String get noStudentsInList => 'No students in this list';

  @override
  String get showAllRecords => 'Show All';

  @override
  String get theTeacher => 'Teacher';

  @override
  String dailyRecordCount(int count) {
    return '$count Daily Records';
  }

  @override
  String parentNameLabel(String name) {
    return 'Parent: $name';
  }

  @override
  String get unmarkedToday => 'Unmarked Today';

  @override
  String get civilIdPrefix => 'Civil ID';

  @override
  String get pending => 'Pending';

  @override
  String get resolved => 'Resolved';

  @override
  String get photoAttached => 'Photo attached';

  @override
  String get pleaseDescribeIncident => 'Please describe the incident';

  @override
  String get incidentReportedSuccessfully => 'Incident reported successfully';

  @override
  String get overview => 'Overview';

  @override
  String get totalDriversLabel => 'Total Drivers';

  @override
  String get activeStatus => 'Active';

  @override
  String get todayIncidents => 'Today\'s Incidents';

  @override
  String get todayInspections => 'Today\'s Inspections';
}
