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
  /// **'Attach photo (optional)'**
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
