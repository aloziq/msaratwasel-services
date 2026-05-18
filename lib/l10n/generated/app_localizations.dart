import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Msarat Wasel Services'**
  String get appTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @themeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeTitle;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @darkModeOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get darkModeOn;

  /// No description provided for @darkModeOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get darkModeOff;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageName.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageName;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Logout from current account'**
  String get logoutSubtitle;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome,'**
  String get welcome;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning! Have a great day'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon! Keep it up'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening! Have a nice day'**
  String get greetingEvening;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @myStudents.
  ///
  /// In en, this message translates to:
  /// **'My Students'**
  String get myStudents;

  /// No description provided for @scanAttendance.
  ///
  /// In en, this message translates to:
  /// **'Scan Attendance'**
  String get scanAttendance;

  /// No description provided for @attendanceHistory.
  ///
  /// In en, this message translates to:
  /// **'Attendance History'**
  String get attendanceHistory;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon...'**
  String get comingSoon;

  /// No description provided for @studentCount.
  ///
  /// In en, this message translates to:
  /// **'Student Count'**
  String get studentCount;

  /// No description provided for @presentToday.
  ///
  /// In en, this message translates to:
  /// **'Present Today'**
  String get presentToday;

  /// No description provided for @absentToday.
  ///
  /// In en, this message translates to:
  /// **'Absent Today'**
  String get absentToday;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @totalStudents.
  ///
  /// In en, this message translates to:
  /// **'Total Students'**
  String get totalStudents;

  /// No description provided for @averageAttendance.
  ///
  /// In en, this message translates to:
  /// **'Average Attendance'**
  String get averageAttendance;

  /// No description provided for @studentsList.
  ///
  /// In en, this message translates to:
  /// **'Students List'**
  String get studentsList;

  /// No description provided for @noStudentsFound.
  ///
  /// In en, this message translates to:
  /// **'No students match the search'**
  String get noStudentsFound;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search by name or ID...'**
  String get searchPlaceholder;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @atHome.
  ///
  /// In en, this message translates to:
  /// **'At Home'**
  String get atHome;

  /// No description provided for @onBus.
  ///
  /// In en, this message translates to:
  /// **'On Bus'**
  String get onBus;

  /// No description provided for @atSchool.
  ///
  /// In en, this message translates to:
  /// **'At School'**
  String get atSchool;

  /// No description provided for @absent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get absent;

  /// No description provided for @tripProgress.
  ///
  /// In en, this message translates to:
  /// **'Trip Progress'**
  String get tripProgress;

  /// No description provided for @deliveredStudentsCount.
  ///
  /// In en, this message translates to:
  /// **'Delivered {atSchool} of {total} students'**
  String deliveredStudentsCount(int atSchool, int total);

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @percentage.
  ///
  /// In en, this message translates to:
  /// **'Percentage'**
  String get percentage;

  /// No description provided for @boardedBus.
  ///
  /// In en, this message translates to:
  /// **'Boarded Bus'**
  String get boardedBus;

  /// No description provided for @reachedSchool.
  ///
  /// In en, this message translates to:
  /// **'Reached School'**
  String get reachedSchool;

  /// No description provided for @arrivedSafely.
  ///
  /// In en, this message translates to:
  /// **'Arrived Safely'**
  String get arrivedSafely;

  /// No description provided for @guardianLabel.
  ///
  /// In en, this message translates to:
  /// **'Guardian: {name}'**
  String guardianLabel(String name);

  /// No description provided for @dailyChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Tasks List'**
  String get dailyChecklistTitle;

  /// No description provided for @dailyChecklist.
  ///
  /// In en, this message translates to:
  /// **'Daily Checklist'**
  String get dailyChecklist;

  /// No description provided for @busTracking.
  ///
  /// In en, this message translates to:
  /// **'Bus Tracking'**
  String get busTracking;

  /// No description provided for @tasksSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Tasks saved successfully'**
  String get tasksSavedSuccessfully;

  /// No description provided for @confirmAndSendReport.
  ///
  /// In en, this message translates to:
  /// **'Confirm and Send Report'**
  String get confirmAndSendReport;

  /// No description provided for @checklistTask1.
  ///
  /// In en, this message translates to:
  /// **'Ensure all students have seatbelts fastened'**
  String get checklistTask1;

  /// No description provided for @checklistTask2.
  ///
  /// In en, this message translates to:
  /// **'Review bus cleanliness before and after the trip'**
  String get checklistTask2;

  /// No description provided for @checklistTask3.
  ///
  /// In en, this message translates to:
  /// **'Ensure the bus is completely empty of students'**
  String get checklistTask3;

  /// No description provided for @checklistTask4.
  ///
  /// In en, this message translates to:
  /// **'Check for forgotten student bags'**
  String get checklistTask4;

  /// No description provided for @checklistTask5.
  ///
  /// In en, this message translates to:
  /// **'Ensure the air conditioning/ventilation system is working'**
  String get checklistTask5;

  /// No description provided for @incidentReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Incident Report'**
  String get incidentReportTitle;

  /// No description provided for @incidentType.
  ///
  /// In en, this message translates to:
  /// **'Incident Type'**
  String get incidentType;

  /// No description provided for @problemDescription.
  ///
  /// In en, this message translates to:
  /// **'Problem Description'**
  String get problemDescription;

  /// No description provided for @reportDetailsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Write report details here...'**
  String get reportDetailsPlaceholder;

  /// No description provided for @attachPhotoOptional.
  ///
  /// In en, this message translates to:
  /// **'Attach Photo (Optional)'**
  String get attachPhotoOptional;

  /// No description provided for @reportSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Report sent to management immediately'**
  String get reportSentSuccessfully;

  /// No description provided for @sendUrgentReport.
  ///
  /// In en, this message translates to:
  /// **'Send Urgent Report'**
  String get sendUrgentReport;

  /// No description provided for @incidentTypeBehavioral.
  ///
  /// In en, this message translates to:
  /// **'Behavioral'**
  String get incidentTypeBehavioral;

  /// No description provided for @incidentTypeHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get incidentTypeHealth;

  /// No description provided for @incidentTypeTechnical.
  ///
  /// In en, this message translates to:
  /// **'Technical Failure'**
  String get incidentTypeTechnical;

  /// No description provided for @incidentTypeTraffic.
  ///
  /// In en, this message translates to:
  /// **'Traffic Accident'**
  String get incidentTypeTraffic;

  /// No description provided for @incidentTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get incidentTypeOther;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports & Statistics'**
  String get reportsTitle;

  /// No description provided for @dailyAverageAttendance.
  ///
  /// In en, this message translates to:
  /// **'Daily Avg Attendance'**
  String get dailyAverageAttendance;

  /// No description provided for @absenceRate.
  ///
  /// In en, this message translates to:
  /// **'Absence Rate'**
  String get absenceRate;

  /// No description provided for @lateRate.
  ///
  /// In en, this message translates to:
  /// **'Late Rate'**
  String get lateRate;

  /// No description provided for @attendanceTrend.
  ///
  /// In en, this message translates to:
  /// **'Attendance Trend'**
  String get attendanceTrend;

  /// No description provided for @insights.
  ///
  /// In en, this message translates to:
  /// **'Insights & Analytics'**
  String get insights;

  /// No description provided for @insightPerfectAttendance.
  ///
  /// In en, this message translates to:
  /// **'Class {className} has perfect attendance today!'**
  String insightPerfectAttendance(String className);

  /// No description provided for @insightLowAttendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance dropped by {percentage}% compared to yesterday'**
  String insightLowAttendance(int percentage);

  /// No description provided for @attendanceToday.
  ///
  /// In en, this message translates to:
  /// **'Attendance Today'**
  String get attendanceToday;

  /// No description provided for @absenceToday.
  ///
  /// In en, this message translates to:
  /// **'Absence Today'**
  String get absenceToday;

  /// No description provided for @weeklyAttendanceTrend.
  ///
  /// In en, this message translates to:
  /// **'Weekly Attendance Trend'**
  String get weeklyAttendanceTrend;

  /// No description provided for @smartInsight.
  ///
  /// In en, this message translates to:
  /// **'Smart Insight'**
  String get smartInsight;

  /// No description provided for @excellentAttendanceInsight.
  ///
  /// In en, this message translates to:
  /// **'Attendance performance is excellent this week! Keep it up.'**
  String get excellentAttendanceInsight;

  /// No description provided for @lowAttendanceInsight.
  ///
  /// In en, this message translates to:
  /// **'There is a slight drop in attendance. You might want to check the reasons.'**
  String get lowAttendanceInsight;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit personal info'**
  String get editProfile;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @changeChildrenLocation.
  ///
  /// In en, this message translates to:
  /// **'Change Children Location'**
  String get changeChildrenLocation;

  /// No description provided for @manageKids.
  ///
  /// In en, this message translates to:
  /// **'Manage registered students'**
  String get manageKids;

  /// No description provided for @locationChangeWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Important Notice'**
  String get locationChangeWarningTitle;

  /// No description provided for @locationChangeWarningBody.
  ///
  /// In en, this message translates to:
  /// **'Please note that if the location is changed, the school must be notified 48 hours prior to the change to ensure transport arrangements.'**
  String get locationChangeWarningBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @proceed.
  ///
  /// In en, this message translates to:
  /// **'Proceed'**
  String get proceed;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemDefault;

  /// No description provided for @activitiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Latest school updates and announcements.'**
  String get activitiesSubtitle;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help center'**
  String get helpCenter;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contactUs;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About app'**
  String get aboutApp;

  /// No description provided for @canteen.
  ///
  /// In en, this message translates to:
  /// **'Canteen'**
  String get canteen;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Msarat Wasel'**
  String get appName;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @aboutAppDescription.
  ///
  /// In en, this message translates to:
  /// **'Msarat Wasel is the ideal solution for managing school transport effectively and safely. It allows parents to track their children and receive real-time notifications, ensuring peace of mind and student safety.'**
  String get aboutAppDescription;

  /// No description provided for @aboutCompanyTitle.
  ///
  /// In en, this message translates to:
  /// **'About Wasel Company'**
  String get aboutCompanyTitle;

  /// No description provided for @aboutCompany.
  ///
  /// In en, this message translates to:
  /// **'Wasel School Transport is a leading company in transport services, striving to provide a safe and comfortable transport experience for students while employing the latest technologies to ensure quality and reliability.'**
  String get aboutCompany;

  /// No description provided for @developedBy.
  ///
  /// In en, this message translates to:
  /// **'Developed by'**
  String get developedBy;

  /// No description provided for @contactMethods.
  ///
  /// In en, this message translates to:
  /// **'Contact Methods'**
  String get contactMethods;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @socialMedia.
  ///
  /// In en, this message translates to:
  /// **'Social Media'**
  String get socialMedia;

  /// No description provided for @complaintsBox.
  ///
  /// In en, this message translates to:
  /// **'Complaints & Suggestions Box'**
  String get complaintsBox;

  /// No description provided for @complaintMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Write your suggestion or complaint here...'**
  String get complaintMessageHint;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @complaintSent.
  ///
  /// In en, this message translates to:
  /// **'Your message has been sent successfully'**
  String get complaintSent;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @passwordLengthError.
  ///
  /// In en, this message translates to:
  /// **'Must be at least 6 characters'**
  String get passwordLengthError;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmPassword;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @passwordUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully'**
  String get passwordUpdatedSuccess;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @privacyIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'First: Introduction'**
  String get privacyIntroTitle;

  /// No description provided for @privacyIntroBody1.
  ///
  /// In en, this message translates to:
  /// **'This document represents a legal agreement between the application users (Guardian, Student, Driver, Supervisor, Teacher, Field Supervisor, School) and the application administration.'**
  String get privacyIntroBody1;

  /// No description provided for @privacyIntroBody2.
  ///
  /// In en, this message translates to:
  /// **'By using the application, all users acknowledge their agreement to this policy and commitment to it.'**
  String get privacyIntroBody2;

  /// No description provided for @privacyDataCollectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Second: Data Collection'**
  String get privacyDataCollectionTitle;

  /// No description provided for @privacyStudentDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Student Data:'**
  String get privacyStudentDataTitle;

  /// No description provided for @privacyStudentData1.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get privacyStudentData1;

  /// No description provided for @privacyStudentData2.
  ///
  /// In en, this message translates to:
  /// **'School ID'**
  String get privacyStudentData2;

  /// No description provided for @privacyStudentData3.
  ///
  /// In en, this message translates to:
  /// **'Civil ID'**
  String get privacyStudentData3;

  /// No description provided for @privacyStudentData4.
  ///
  /// In en, this message translates to:
  /// **'Student Photo'**
  String get privacyStudentData4;

  /// No description provided for @privacyStudentData5.
  ///
  /// In en, this message translates to:
  /// **'Home Photo'**
  String get privacyStudentData5;

  /// No description provided for @privacyStudentData6.
  ///
  /// In en, this message translates to:
  /// **'Bus Geographic Location'**
  String get privacyStudentData6;

  /// No description provided for @privacyStudentData7.
  ///
  /// In en, this message translates to:
  /// **'Attendance Log via Barcode'**
  String get privacyStudentData7;

  /// No description provided for @privacyOtherDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Other Data:'**
  String get privacyOtherDataTitle;

  /// No description provided for @privacyOtherData1.
  ///
  /// In en, this message translates to:
  /// **'Guardian Data: Name, Phone Number, Email, Civil ID.'**
  String get privacyOtherData1;

  /// No description provided for @privacyOtherData2.
  ///
  /// In en, this message translates to:
  /// **'Driver, Supervisor, and Teacher Data: Name, ID/Job Number, Contact Info.'**
  String get privacyOtherData2;

  /// No description provided for @privacyOtherData3.
  ///
  /// In en, this message translates to:
  /// **'Technical Data: Login Log, Barcode Usage, Bus Geographic Location.'**
  String get privacyOtherData3;

  /// No description provided for @privacyDataUsageTitle.
  ///
  /// In en, this message translates to:
  /// **'Third: Data Usage'**
  String get privacyDataUsageTitle;

  /// No description provided for @privacyDataUsage1.
  ///
  /// In en, this message translates to:
  /// **'Ensuring student safety during school transport.'**
  String get privacyDataUsage1;

  /// No description provided for @privacyDataUsage2.
  ///
  /// In en, this message translates to:
  /// **'Enabling guardians to track student status.'**
  String get privacyDataUsage2;

  /// No description provided for @privacyDataUsage3.
  ///
  /// In en, this message translates to:
  /// **'Managing school transport operations efficiently.'**
  String get privacyDataUsage3;

  /// No description provided for @privacyDataUsage4.
  ///
  /// In en, this message translates to:
  /// **'Issuing reports for the school and supervisors.'**
  String get privacyDataUsage4;

  /// No description provided for @privacyDataUsage5.
  ///
  /// In en, this message translates to:
  /// **'Data is not used for any commercial or promotional purposes.'**
  String get privacyDataUsage5;

  /// No description provided for @privacyDataProtectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Fourth: Data Protection'**
  String get privacyDataProtectionTitle;

  /// No description provided for @privacyDataProtection1.
  ///
  /// In en, this message translates to:
  /// **'Storing data in secure servers using encryption technologies.'**
  String get privacyDataProtection1;

  /// No description provided for @privacyDataProtection2.
  ///
  /// In en, this message translates to:
  /// **'Restricting access to data according to user permissions.'**
  String get privacyDataProtection2;

  /// No description provided for @privacyDataProtection3.
  ///
  /// In en, this message translates to:
  /// **'Periodic review of security procedures.'**
  String get privacyDataProtection3;

  /// No description provided for @privacyDataProtection4.
  ///
  /// In en, this message translates to:
  /// **'Not sharing data with third parties unless approved by the school or required by law.'**
  String get privacyDataProtection4;

  /// No description provided for @privacyUserRightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Fifth: User Rights'**
  String get privacyUserRightsTitle;

  /// No description provided for @privacyUserRights1.
  ///
  /// In en, this message translates to:
  /// **'The right to access their data.'**
  String get privacyUserRights1;

  /// No description provided for @privacyUserRights2.
  ///
  /// In en, this message translates to:
  /// **'The right to request correction or deletion of inaccurate data.'**
  String get privacyUserRights2;

  /// No description provided for @privacyUserRights3.
  ///
  /// In en, this message translates to:
  /// **'The right to object to the use of their data for non-educational purposes.'**
  String get privacyUserRights3;

  /// No description provided for @privacyUserObligationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sixth: User Obligations'**
  String get privacyUserObligationsTitle;

  /// No description provided for @privacyUserObligations1.
  ///
  /// In en, this message translates to:
  /// **'Using the application only for educational and school transport purposes.'**
  String get privacyUserObligations1;

  /// No description provided for @privacyUserObligations2.
  ///
  /// In en, this message translates to:
  /// **'Not sharing login credentials with other parties.'**
  String get privacyUserObligations2;

  /// No description provided for @privacyUserObligations3.
  ///
  /// In en, this message translates to:
  /// **'Adhering to local laws regarding data protection.'**
  String get privacyUserObligations3;

  /// No description provided for @privacyLegalLiabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Seventh: Legal Liability'**
  String get privacyLegalLiabilityTitle;

  /// No description provided for @privacyLegalLiability1.
  ///
  /// In en, this message translates to:
  /// **'The application is not responsible for any unauthorized use by users.'**
  String get privacyLegalLiability1;

  /// No description provided for @privacyLegalLiability2.
  ///
  /// In en, this message translates to:
  /// **'The school bears the responsibility of managing user permissions.'**
  String get privacyLegalLiability2;

  /// No description provided for @privacyLegalLiability3.
  ///
  /// In en, this message translates to:
  /// **'Any security breach will be dealt with according to local laws (including Royal Decree No. 6/2022 on Personal Data Protection in Oman).'**
  String get privacyLegalLiability3;

  /// No description provided for @privacyAmendmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Eighth: Amendments'**
  String get privacyAmendmentsTitle;

  /// No description provided for @privacyAmendments1.
  ///
  /// In en, this message translates to:
  /// **'The application administration reserves the right to amend this policy in accordance with laws and technical developments.'**
  String get privacyAmendments1;

  /// No description provided for @privacyAmendments2.
  ///
  /// In en, this message translates to:
  /// **'Users will be notified of any substantial changes.'**
  String get privacyAmendments2;

  /// No description provided for @privacyConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Ninth: Consent'**
  String get privacyConsentTitle;

  /// No description provided for @privacyConsentBody.
  ///
  /// In en, this message translates to:
  /// **'By using the application, all users agree to this policy and adhere to it.'**
  String get privacyConsentBody;

  /// No description provided for @privacySimplifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'📱 Simplified Version for Users'**
  String get privacySimplifiedTitle;

  /// No description provided for @privacyQ1.
  ///
  /// In en, this message translates to:
  /// **'Why do we collect data?'**
  String get privacyQ1;

  /// No description provided for @privacyA1.
  ///
  /// In en, this message translates to:
  /// **'- To ensure student safety during the trip.\n- To help the guardian track the student\'s arrival and departure.\n- To facilitate the work of the driver, supervisor, teacher, and field supervisor.'**
  String get privacyA1;

  /// No description provided for @privacyQ2.
  ///
  /// In en, this message translates to:
  /// **'What data do we use?'**
  String get privacyQ2;

  /// No description provided for @privacyA2.
  ///
  /// In en, this message translates to:
  /// **'- Student name and school number.\n- Civil ID and student photo for identity verification.\n- Home photo and bus geographic location.\n- Student attendance log via barcode.\n- Guardian data for communication.\n- Driver, supervisor, and teacher data.'**
  String get privacyA2;

  /// No description provided for @privacyQ3.
  ///
  /// In en, this message translates to:
  /// **'How do we protect your data?'**
  String get privacyQ3;

  /// No description provided for @privacyA3.
  ///
  /// In en, this message translates to:
  /// **'- We store information in secure and encrypted systems.\n- We do not share your data with any external party unless approved by the school or required by law.\n- We define access permissions so each user only sees what they need for their work.'**
  String get privacyA3;

  /// No description provided for @privacyQ4.
  ///
  /// In en, this message translates to:
  /// **'Your Rights'**
  String get privacyQ4;

  /// No description provided for @privacyA4.
  ///
  /// In en, this message translates to:
  /// **'- You can access your data.\n- You can request correction or deletion of incorrect data.\n- Your data will not be used for any commercial or promotional purposes.'**
  String get privacyA4;

  /// No description provided for @privacyQ5.
  ///
  /// In en, this message translates to:
  /// **'Your Obligations'**
  String get privacyQ5;

  /// No description provided for @privacyA5.
  ///
  /// In en, this message translates to:
  /// **'- Use the application only for school transport.\n- Do not share your account or login details with others.\n- Adhere to local laws regarding data protection.'**
  String get privacyA5;

  /// No description provided for @application.
  ///
  /// In en, this message translates to:
  /// **'Application'**
  String get application;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chats;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @remainingTime.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remainingTime;

  /// No description provided for @busStateAtStation.
  ///
  /// In en, this message translates to:
  /// **'At Station'**
  String get busStateAtStation;

  /// No description provided for @busStateEnRoute.
  ///
  /// In en, this message translates to:
  /// **'En Route'**
  String get busStateEnRoute;

  /// No description provided for @busStateArrived.
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get busStateArrived;

  /// No description provided for @kmPerHour.
  ///
  /// In en, this message translates to:
  /// **'km/h'**
  String get kmPerHour;

  /// No description provided for @km.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get km;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutes;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updated;

  /// No description provided for @driversAndSupervisors.
  ///
  /// In en, this message translates to:
  /// **'Drivers & Supervisors'**
  String get driversAndSupervisors;

  /// No description provided for @drivers.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get drivers;

  /// No description provided for @supervisors.
  ///
  /// In en, this message translates to:
  /// **'Supervisors'**
  String get supervisors;

  /// No description provided for @bus.
  ///
  /// In en, this message translates to:
  /// **'Bus'**
  String get bus;

  /// No description provided for @fieldSupervisor.
  ///
  /// In en, this message translates to:
  /// **'Field Supervisor'**
  String get fieldSupervisor;

  /// No description provided for @supervisorRole.
  ///
  /// In en, this message translates to:
  /// **'Field Supervisor'**
  String get supervisorRole;

  /// No description provided for @incidentsAndEmergencies.
  ///
  /// In en, this message translates to:
  /// **'Incidents & Emergencies'**
  String get incidentsAndEmergencies;

  /// No description provided for @fieldInspection.
  ///
  /// In en, this message translates to:
  /// **'Field Inspection'**
  String get fieldInspection;

  /// No description provided for @registerDelays.
  ///
  /// In en, this message translates to:
  /// **'Register Delays'**
  String get registerDelays;

  /// No description provided for @dailyTrips.
  ///
  /// In en, this message translates to:
  /// **'Daily Trips'**
  String get dailyTrips;

  /// No description provided for @selectBus.
  ///
  /// In en, this message translates to:
  /// **'Select Bus'**
  String get selectBus;

  /// No description provided for @inspectionChecklist.
  ///
  /// In en, this message translates to:
  /// **'Inspection Checklist'**
  String get inspectionChecklist;

  /// No description provided for @takePhotos.
  ///
  /// In en, this message translates to:
  /// **'Take Photos'**
  String get takePhotos;

  /// No description provided for @inspectionSaved.
  ///
  /// In en, this message translates to:
  /// **'Inspection Saved Successfully'**
  String get inspectionSaved;

  /// No description provided for @saveInspection.
  ///
  /// In en, this message translates to:
  /// **'Save Inspection'**
  String get saveInspection;

  /// No description provided for @completedTrips.
  ///
  /// In en, this message translates to:
  /// **'Completed Trips'**
  String get completedTrips;

  /// No description provided for @issues.
  ///
  /// In en, this message translates to:
  /// **'Issues'**
  String get issues;

  /// No description provided for @delays.
  ///
  /// In en, this message translates to:
  /// **'Delays'**
  String get delays;

  /// No description provided for @violations.
  ///
  /// In en, this message translates to:
  /// **'Violations'**
  String get violations;

  /// No description provided for @reportCategories.
  ///
  /// In en, this message translates to:
  /// **'Report Categories'**
  String get reportCategories;

  /// No description provided for @viewAllTrips.
  ///
  /// In en, this message translates to:
  /// **'View All Trips'**
  String get viewAllTrips;

  /// No description provided for @viewAllIssues.
  ///
  /// In en, this message translates to:
  /// **'View All Issues'**
  String get viewAllIssues;

  /// No description provided for @viewAllDelays.
  ///
  /// In en, this message translates to:
  /// **'View All Delays'**
  String get viewAllDelays;

  /// No description provided for @viewAllViolations.
  ///
  /// In en, this message translates to:
  /// **'View All Violations'**
  String get viewAllViolations;

  /// No description provided for @fieldTrips.
  ///
  /// In en, this message translates to:
  /// **'Field Trips'**
  String get fieldTrips;

  /// No description provided for @viewFieldTrips.
  ///
  /// In en, this message translates to:
  /// **'View Field Trips'**
  String get viewFieldTrips;

  /// No description provided for @todayTrips.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Trips'**
  String get todayTrips;

  /// No description provided for @trips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get trips;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get addNote;

  /// No description provided for @viewOnMap.
  ///
  /// In en, this message translates to:
  /// **'View on Map'**
  String get viewOnMap;

  /// No description provided for @trafficJam.
  ///
  /// In en, this message translates to:
  /// **'Traffic Jam'**
  String get trafficJam;

  /// No description provided for @technicalIssue.
  ///
  /// In en, this message translates to:
  /// **'Technical Issue'**
  String get technicalIssue;

  /// No description provided for @studentLate.
  ///
  /// In en, this message translates to:
  /// **'Student Late'**
  String get studentLate;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @delaySavedAndReported.
  ///
  /// In en, this message translates to:
  /// **'Delay Saved and Reported'**
  String get delaySavedAndReported;

  /// No description provided for @saveAndSend.
  ///
  /// In en, this message translates to:
  /// **'Save and Send'**
  String get saveAndSend;

  /// No description provided for @upcomingTrips.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Trips'**
  String get upcomingTrips;

  /// No description provided for @driver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driver;

  /// No description provided for @communication.
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get communication;

  /// No description provided for @activeBuses.
  ///
  /// In en, this message translates to:
  /// **'Active Buses'**
  String get activeBuses;

  /// No description provided for @activeDrivers.
  ///
  /// In en, this message translates to:
  /// **'Active Drivers'**
  String get activeDrivers;

  /// No description provided for @activeTrips.
  ///
  /// In en, this message translates to:
  /// **'Active Trips'**
  String get activeTrips;

  /// No description provided for @activeEmergency.
  ///
  /// In en, this message translates to:
  /// **'Active Emergency'**
  String get activeEmergency;

  /// No description provided for @respond.
  ///
  /// In en, this message translates to:
  /// **'Respond'**
  String get respond;

  /// No description provided for @allIncidents.
  ///
  /// In en, this message translates to:
  /// **'All Incidents'**
  String get allIncidents;

  /// No description provided for @newIncident.
  ///
  /// In en, this message translates to:
  /// **'New Incident'**
  String get newIncident;

  /// No description provided for @incidentDescription.
  ///
  /// In en, this message translates to:
  /// **'Incident Description'**
  String get incidentDescription;

  /// No description provided for @attachPhoto.
  ///
  /// In en, this message translates to:
  /// **'Attach Photo'**
  String get attachPhoto;

  /// No description provided for @incidentReported.
  ///
  /// In en, this message translates to:
  /// **'Incident Reported Successfully'**
  String get incidentReported;

  /// No description provided for @pendingInspections.
  ///
  /// In en, this message translates to:
  /// **'Pending Inspections'**
  String get pendingInspections;

  /// No description provided for @busesNeedInspection.
  ///
  /// In en, this message translates to:
  /// **'Buses Need Inspection'**
  String get busesNeedInspection;

  /// No description provided for @recentInspections.
  ///
  /// In en, this message translates to:
  /// **'Recent Inspections'**
  String get recentInspections;

  /// No description provided for @newInspection.
  ///
  /// In en, this message translates to:
  /// **'New Inspection'**
  String get newInspection;

  /// No description provided for @totalBuses.
  ///
  /// In en, this message translates to:
  /// **'Total Buses'**
  String get totalBuses;

  /// No description provided for @stoppedBuses.
  ///
  /// In en, this message translates to:
  /// **'Stopped Buses'**
  String get stoppedBuses;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @broadcastMessage.
  ///
  /// In en, this message translates to:
  /// **'Broadcast Message'**
  String get broadcastMessage;

  /// No description provided for @sendToAll.
  ///
  /// In en, this message translates to:
  /// **'Send to All'**
  String get sendToAll;

  /// No description provided for @recentChats.
  ///
  /// In en, this message translates to:
  /// **'Recent Chats'**
  String get recentChats;

  /// No description provided for @studentDelays.
  ///
  /// In en, this message translates to:
  /// **'Student Delays'**
  String get studentDelays;

  /// No description provided for @busDelays.
  ///
  /// In en, this message translates to:
  /// **'Bus Delays'**
  String get busDelays;

  /// No description provided for @reportSent.
  ///
  /// In en, this message translates to:
  /// **'Report Sent Successfully'**
  String get reportSent;

  /// No description provided for @registerNewDelay.
  ///
  /// In en, this message translates to:
  /// **'Register New Delay'**
  String get registerNewDelay;

  /// No description provided for @student.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get student;

  /// No description provided for @selectStudent.
  ///
  /// In en, this message translates to:
  /// **'Select Student'**
  String get selectStudent;

  /// No description provided for @delayDuration.
  ///
  /// In en, this message translates to:
  /// **'Delay Duration (min)'**
  String get delayDuration;

  /// No description provided for @delayReason.
  ///
  /// In en, this message translates to:
  /// **'Delay Reason'**
  String get delayReason;

  /// No description provided for @present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get present;

  /// No description provided for @finishAttendance.
  ///
  /// In en, this message translates to:
  /// **'Finish Attendance'**
  String get finishAttendance;

  /// No description provided for @attendanceSummary.
  ///
  /// In en, this message translates to:
  /// **'Attendance Summary'**
  String get attendanceSummary;

  /// No description provided for @confirmSendReport.
  ///
  /// In en, this message translates to:
  /// **'Do you want to finish attendance and send the report?'**
  String get confirmSendReport;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @unmarked.
  ///
  /// In en, this message translates to:
  /// **'Unmarked'**
  String get unmarked;

  /// No description provided for @unmarkedStudentsWarning.
  ///
  /// In en, this message translates to:
  /// **'There are {count} students whose status is unmarked'**
  String unmarkedStudentsWarning(int count);

  /// No description provided for @confirmSend.
  ///
  /// In en, this message translates to:
  /// **'Confirm Send'**
  String get confirmSend;

  /// No description provided for @dailyReportSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Daily report sent successfully'**
  String get dailyReportSentSuccess;

  /// No description provided for @classPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'4th Grade - A'**
  String get classPlaceholder;

  /// No description provided for @parentGuardian.
  ///
  /// In en, this message translates to:
  /// **'Parent/Guardian'**
  String get parentGuardian;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @sosAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Incident Report'**
  String get sosAlertsTitle;

  /// No description provided for @sosAlertsStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get sosAlertsStatusPending;

  /// No description provided for @sosAlertsStatusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get sosAlertsStatusResolved;

  /// No description provided for @sosAlertsStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get sosAlertsStatusActive;

  /// No description provided for @sosAlertsTimeAgo.
  ///
  /// In en, this message translates to:
  /// **'{time} ago'**
  String sosAlertsTimeAgo(String time);

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @civilId.
  ///
  /// In en, this message translates to:
  /// **'Civil ID'**
  String get civilId;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @enterCivilId.
  ///
  /// In en, this message translates to:
  /// **'Please enter Civil ID'**
  String get enterCivilId;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter password'**
  String get enterPassword;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get unexpectedError;

  /// No description provided for @selectCorrectRole.
  ///
  /// In en, this message translates to:
  /// **'Please select the correct role to login'**
  String get selectCorrectRole;

  /// No description provided for @resetPasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent successfully!'**
  String get resetPasswordSuccess;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your ID to recover your account'**
  String get resetPasswordSubtitle;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenance;

  /// No description provided for @fuelRefill.
  ///
  /// In en, this message translates to:
  /// **'Fuel Refill'**
  String get fuelRefill;

  /// No description provided for @maintenanceRequest.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Request'**
  String get maintenanceRequest;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get statusStopped;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get statusScheduled;

  /// No description provided for @statusMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get statusMaintenance;

  /// No description provided for @statusExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get statusExcellent;

  /// No description provided for @statusGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get statusGood;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @typeTechnical.
  ///
  /// In en, this message translates to:
  /// **'Technical'**
  String get typeTechnical;

  /// No description provided for @typeBehavioral.
  ///
  /// In en, this message translates to:
  /// **'Behavioral'**
  String get typeBehavioral;

  /// No description provided for @typeHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get typeHealth;

  /// No description provided for @typeTraffic.
  ///
  /// In en, this message translates to:
  /// **'Traffic'**
  String get typeTraffic;

  /// No description provided for @typeSOS.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get typeSOS;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Administration'**
  String get roleAdmin;

  /// No description provided for @roleDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get roleDriver;

  /// No description provided for @late.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get late;

  /// No description provided for @myClasses.
  ///
  /// In en, this message translates to:
  /// **'My Classes'**
  String get myClasses;

  /// No description provided for @busNumber.
  ///
  /// In en, this message translates to:
  /// **'Bus {number}'**
  String busNumber(int number);

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get sendMessage;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @todayAttendance.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Attendance'**
  String get todayAttendance;

  /// No description provided for @classAttendance.
  ///
  /// In en, this message translates to:
  /// **'Class Attendance'**
  String get classAttendance;

  /// No description provided for @takeAttendance.
  ///
  /// In en, this message translates to:
  /// **'Take Attendance'**
  String get takeAttendance;

  /// No description provided for @markPresent.
  ///
  /// In en, this message translates to:
  /// **'Mark Present'**
  String get markPresent;

  /// No description provided for @markAbsent.
  ///
  /// In en, this message translates to:
  /// **'Mark Absent'**
  String get markAbsent;

  /// No description provided for @noDataFound.
  ///
  /// In en, this message translates to:
  /// **'No data found'**
  String get noDataFound;

  /// No description provided for @loadingData.
  ///
  /// In en, this message translates to:
  /// **'Loading data...'**
  String get loadingData;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// No description provided for @afternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get afternoon;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'this month'**
  String get thisMonth;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get connectionError;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternet;

  /// No description provided for @successMessage.
  ///
  /// In en, this message translates to:
  /// **'Operation successful'**
  String get successMessage;

  /// No description provided for @savedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get savedSuccessfully;

  /// No description provided for @deletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully'**
  String get deletedSuccessfully;

  /// No description provided for @sentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Sent successfully'**
  String get sentSuccessfully;

  /// No description provided for @attendanceMarked.
  ///
  /// In en, this message translates to:
  /// **'Attendance marked successfully'**
  String get attendanceMarked;

  /// No description provided for @navigation.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get navigation;

  /// No description provided for @endTrip.
  ///
  /// In en, this message translates to:
  /// **'End Trip'**
  String get endTrip;

  /// No description provided for @roleBusAssistant.
  ///
  /// In en, this message translates to:
  /// **'Bus Assistant'**
  String get roleBusAssistant;

  /// No description provided for @roleFieldSupervisor.
  ///
  /// In en, this message translates to:
  /// **'Field Supervisor'**
  String get roleFieldSupervisor;

  /// No description provided for @roleTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get roleTeacher;

  /// No description provided for @driverLogin.
  ///
  /// In en, this message translates to:
  /// **'Driver Login'**
  String get driverLogin;

  /// No description provided for @assistantLogin.
  ///
  /// In en, this message translates to:
  /// **'Assistant Login'**
  String get assistantLogin;

  /// No description provided for @supervisorLogin.
  ///
  /// In en, this message translates to:
  /// **'Supervisor Login'**
  String get supervisorLogin;

  /// No description provided for @teacherLogin.
  ///
  /// In en, this message translates to:
  /// **'Teacher Login'**
  String get teacherLogin;

  /// No description provided for @maintenanceLog.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Log'**
  String get maintenanceLog;

  /// No description provided for @theDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get theDriver;

  /// No description provided for @driversGroup.
  ///
  /// In en, this message translates to:
  /// **'Drivers Group'**
  String get driversGroup;

  /// No description provided for @dailyRecord.
  ///
  /// In en, this message translates to:
  /// **'Daily Record'**
  String get dailyRecord;

  /// No description provided for @presentStudents.
  ///
  /// In en, this message translates to:
  /// **'Present Students'**
  String get presentStudents;

  /// No description provided for @parentPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get parentPhone;

  /// No description provided for @parentGuardianLabel.
  ///
  /// In en, this message translates to:
  /// **'Parent/Guardian'**
  String get parentGuardianLabel;

  /// No description provided for @students.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get students;

  /// No description provided for @sos.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get sos;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @boarded.
  ///
  /// In en, this message translates to:
  /// **'Boarded'**
  String get boarded;

  /// No description provided for @pleaseEnterCivilId.
  ///
  /// In en, this message translates to:
  /// **'Please enter civil ID'**
  String get pleaseEnterCivilId;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter password'**
  String get pleaseEnterPassword;

  /// No description provided for @readyToStart.
  ///
  /// In en, this message translates to:
  /// **'Ready to Start'**
  String get readyToStart;

  /// No description provided for @departureTime.
  ///
  /// In en, this message translates to:
  /// **'Departure'**
  String get departureTime;

  /// No description provided for @startTrip.
  ///
  /// In en, this message translates to:
  /// **'Start Trip'**
  String get startTrip;

  /// No description provided for @endTripTitle.
  ///
  /// In en, this message translates to:
  /// **'End Trip'**
  String get endTripTitle;

  /// No description provided for @confirmEndTrip.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to end the trip?'**
  String get confirmEndTrip;

  /// No description provided for @tripEndedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Trip ended successfully!'**
  String get tripEndedSuccess;

  /// No description provided for @scanFrontCode.
  ///
  /// In en, this message translates to:
  /// **'Scan Front Code'**
  String get scanFrontCode;

  /// No description provided for @scanBackCode.
  ///
  /// In en, this message translates to:
  /// **'Scan Back Code'**
  String get scanBackCode;

  /// No description provided for @scanFrontDesc.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code located at the front of the bus.'**
  String get scanFrontDesc;

  /// No description provided for @scanBackDesc.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code located at the back of the bus.'**
  String get scanBackDesc;

  /// No description provided for @recordVideo.
  ///
  /// In en, this message translates to:
  /// **'Record Video'**
  String get recordVideo;

  /// No description provided for @recordVideoDesc.
  ///
  /// In en, this message translates to:
  /// **'Record a video walking from front to back to ensure bus is empty.'**
  String get recordVideoDesc;

  /// No description provided for @nextStop.
  ///
  /// In en, this message translates to:
  /// **'Next Stop'**
  String get nextStop;

  /// No description provided for @arriveAtStudent.
  ///
  /// In en, this message translates to:
  /// **'Arrive at Student'**
  String get arriveAtStudent;

  /// No description provided for @nextDestination.
  ///
  /// In en, this message translates to:
  /// **'Next Destination'**
  String get nextDestination;

  /// No description provided for @probableAbsence.
  ///
  /// In en, this message translates to:
  /// **'Probable Absence'**
  String get probableAbsence;

  /// No description provided for @fuelRefillTitle.
  ///
  /// In en, this message translates to:
  /// **'Fuel Refill'**
  String get fuelRefillTitle;

  /// No description provided for @attachReceipt.
  ///
  /// In en, this message translates to:
  /// **'Attach Receipt Photo'**
  String get attachReceipt;

  /// No description provided for @odometerReading.
  ///
  /// In en, this message translates to:
  /// **'Odometer Reading (km)'**
  String get odometerReading;

  /// No description provided for @recentLogs.
  ///
  /// In en, this message translates to:
  /// **'Recent Logs'**
  String get recentLogs;

  /// No description provided for @fuelEntry.
  ///
  /// In en, this message translates to:
  /// **'Fuel Entry'**
  String get fuelEntry;

  /// No description provided for @requestMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Request Maintenance'**
  String get requestMaintenance;

  /// No description provided for @maintenanceRequestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Maintenance request submitted successfully'**
  String get maintenanceRequestSubmitted;

  /// No description provided for @reRecord.
  ///
  /// In en, this message translates to:
  /// **'Re-record'**
  String get reRecord;

  /// No description provided for @videoRecorded.
  ///
  /// In en, this message translates to:
  /// **'Video Recorded'**
  String get videoRecorded;

  /// No description provided for @busEmptyCheck.
  ///
  /// In en, this message translates to:
  /// **'Bus Empty Check'**
  String get busEmptyCheck;

  /// No description provided for @maintenanceRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Request'**
  String get maintenanceRequestTitle;

  /// No description provided for @estimatedCost.
  ///
  /// In en, this message translates to:
  /// **'Estimated Cost'**
  String get estimatedCost;

  /// No description provided for @requestSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Request sent successfully'**
  String get requestSentSuccess;

  /// No description provided for @dataSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data saved successfully'**
  String get dataSavedSuccess;

  /// No description provided for @pleaseAttachPhoto.
  ///
  /// In en, this message translates to:
  /// **'Please attach a photo'**
  String get pleaseAttachPhoto;

  /// No description provided for @enterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid number'**
  String get enterValidNumber;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter amount'**
  String get enterAmount;

  /// No description provided for @enterOdometer.
  ///
  /// In en, this message translates to:
  /// **'Please enter odometer reading'**
  String get enterOdometer;

  /// No description provided for @describeProblem.
  ///
  /// In en, this message translates to:
  /// **'Please describe the problem'**
  String get describeProblem;

  /// No description provided for @submitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get submitRequest;

  /// No description provided for @studentStatistics.
  ///
  /// In en, this message translates to:
  /// **'Student Statistics'**
  String get studentStatistics;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @searchStudentPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search for a student...'**
  String get searchStudentPlaceholder;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSize;

  /// No description provided for @fontSizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get fontSizeSmall;

  /// No description provided for @fontSizeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get fontSizeMedium;

  /// No description provided for @fontSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get fontSizeLarge;

  /// No description provided for @incorrectPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get incorrectPassword;

  /// No description provided for @civilIdNotRegistered.
  ///
  /// In en, this message translates to:
  /// **'This civil ID is not registered'**
  String get civilIdNotRegistered;

  /// No description provided for @civilIdRegisteredAs.
  ///
  /// In en, this message translates to:
  /// **'This civil ID is registered as {role}'**
  String civilIdRegisteredAs(String role);

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed: Invalid credentials'**
  String get loginFailed;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @clearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear Filter'**
  String get clearFilter;

  /// No description provided for @searchByDate.
  ///
  /// In en, this message translates to:
  /// **'Search by Date'**
  String get searchByDate;

  /// No description provided for @noRecordsForDate.
  ///
  /// In en, this message translates to:
  /// **'No records for this date'**
  String get noRecordsForDate;

  /// No description provided for @noStudentsInList.
  ///
  /// In en, this message translates to:
  /// **'No students in this list'**
  String get noStudentsInList;

  /// No description provided for @showAllRecords.
  ///
  /// In en, this message translates to:
  /// **'Show All'**
  String get showAllRecords;

  /// No description provided for @theTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get theTeacher;

  /// No description provided for @dailyRecordCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Daily Records'**
  String dailyRecordCount(int count);

  /// No description provided for @parentNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Parent: {name}'**
  String parentNameLabel(String name);

  /// No description provided for @unmarkedToday.
  ///
  /// In en, this message translates to:
  /// **'Unmarked Today'**
  String get unmarkedToday;

  /// No description provided for @civilIdPrefix.
  ///
  /// In en, this message translates to:
  /// **'Civil ID'**
  String get civilIdPrefix;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @resolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get resolved;

  /// No description provided for @photoAttached.
  ///
  /// In en, this message translates to:
  /// **'Photo attached'**
  String get photoAttached;

  /// No description provided for @pleaseDescribeIncident.
  ///
  /// In en, this message translates to:
  /// **'Please describe the incident'**
  String get pleaseDescribeIncident;

  /// No description provided for @incidentReportedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Incident reported successfully'**
  String get incidentReportedSuccessfully;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @totalDriversLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Drivers'**
  String get totalDriversLabel;

  /// No description provided for @activeStatus.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeStatus;

  /// No description provided for @todayIncidents.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Incidents'**
  String get todayIncidents;

  /// No description provided for @todayInspections.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Inspections'**
  String get todayInspections;

  /// No description provided for @attendanceDays.
  ///
  /// In en, this message translates to:
  /// **'Attendance Days'**
  String get attendanceDays;

  /// No description provided for @absenceDays.
  ///
  /// In en, this message translates to:
  /// **'Absence Days'**
  String get absenceDays;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
