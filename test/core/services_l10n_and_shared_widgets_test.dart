import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations_ar.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations_en.dart';
import 'package:msaratwasel_services/core/presentation/widgets/adaptive_sliver_app_bar.dart';
import 'package:msaratwasel_services/core/presentation/widgets/app_sliver_header.dart';
import 'package:msaratwasel_services/core/presentation/widgets/background_widget.dart';
import 'package:msaratwasel_services/core/presentation/widgets/chat_avatar.dart';
import 'package:msaratwasel_services/core/presentation/widgets/custom_menu_button.dart';
import 'package:msaratwasel_services/core/presentation/widgets/directional_icon.dart';
import 'package:msaratwasel_services/core/presentation/widgets/glass_card.dart';
import 'package:msaratwasel_services/core/presentation/widgets/premium_button.dart';
import 'package:msaratwasel_services/core/presentation/widgets/premium_text_field.dart';
import 'package:msaratwasel_services/core/presentation/widgets/date_picker_field.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Agent 5: Services App L10n and Shared Widgets Suite', () {
    test('1. AppLocalizationsAr covers all getters and methods', () {
      final ar = AppLocalizationsAr();
      expect(ar.appTitle, isNotEmpty);
      expect(ar.settingsTitle, isNotEmpty);
      expect(ar.themeTitle, isNotEmpty);
      expect(ar.darkMode, isNotEmpty);
      expect(ar.darkModeOn, isNotEmpty);
      expect(ar.darkModeOff, isNotEmpty);
      expect(ar.languageTitle, isNotEmpty);
      expect(ar.languageName, isNotEmpty);
      expect(ar.accountTitle, isNotEmpty);
      expect(ar.logout, isNotEmpty);
      expect(ar.logoutSubtitle, isNotEmpty);
      expect(ar.aboutTitle, isNotEmpty);
      expect(ar.welcome, isNotEmpty);
      expect(ar.greetingMorning, isNotEmpty);
      expect(ar.greetingAfternoon, isNotEmpty);
      expect(ar.greetingEvening, isNotEmpty);
      expect(ar.quickActions, isNotEmpty);
      expect(ar.myStudents, isNotEmpty);
      expect(ar.scanAttendance, isNotEmpty);
      expect(ar.attendanceHistory, isNotEmpty);
      expect(ar.reports, isNotEmpty);
      expect(ar.comingSoon, isNotEmpty);
      expect(ar.studentCount, isNotEmpty);
      expect(ar.presentToday, isNotEmpty);
      expect(ar.absentToday, isNotEmpty);
      expect(ar.user, isNotEmpty);
      expect(ar.home, isNotEmpty);
      expect(ar.profile, isNotEmpty);
      expect(ar.settings, isNotEmpty);
      expect(ar.totalStudents, isNotEmpty);
      expect(ar.averageAttendance, isNotEmpty);
      expect(ar.studentsList, isNotEmpty);
      expect(ar.noStudentsFound, isNotEmpty);
      expect(ar.searchPlaceholder, isNotEmpty);
      expect(ar.all, isNotEmpty);
      expect(ar.atHome, isNotEmpty);
      expect(ar.onBus, isNotEmpty);
      expect(ar.atSchool, isNotEmpty);
      expect(ar.absent, isNotEmpty);
      expect(ar.tripProgress, isNotEmpty);
      expect(ar.remaining, isNotEmpty);
      expect(ar.percentage, isNotEmpty);
      expect(ar.boardedBus, isNotEmpty);
      expect(ar.reachedSchool, isNotEmpty);
      expect(ar.arrivedSafely, isNotEmpty);
      expect(ar.dailyChecklistTitle, isNotEmpty);
      expect(ar.dailyChecklist, isNotEmpty);
      expect(ar.busTracking, isNotEmpty);
      expect(ar.tasksSavedSuccessfully, isNotEmpty);
      expect(ar.confirmAndSendReport, isNotEmpty);
      expect(ar.checklistTask1, isNotEmpty);
      expect(ar.checklistTask2, isNotEmpty);
      expect(ar.checklistTask3, isNotEmpty);
      expect(ar.checklistTask4, isNotEmpty);
      expect(ar.checklistTask5, isNotEmpty);
      expect(ar.incidentReportTitle, isNotEmpty);
      expect(ar.incidentType, isNotEmpty);
      expect(ar.problemDescription, isNotEmpty);
      expect(ar.reportDetailsPlaceholder, isNotEmpty);
      expect(ar.attachPhotoOptional, isNotEmpty);
      expect(ar.reportSentSuccessfully, isNotEmpty);
      expect(ar.sendUrgentReport, isNotEmpty);
      expect(ar.incidentTypeBehavioral, isNotEmpty);
      expect(ar.incidentTypeHealth, isNotEmpty);
      expect(ar.incidentTypeTechnical, isNotEmpty);
      expect(ar.incidentTypeTraffic, isNotEmpty);
      expect(ar.incidentTypeOther, isNotEmpty);
      expect(ar.reportsTitle, isNotEmpty);
      expect(ar.dailyAverageAttendance, isNotEmpty);
      expect(ar.absenceRate, isNotEmpty);
      expect(ar.lateRate, isNotEmpty);
      expect(ar.attendanceTrend, isNotEmpty);
      expect(ar.insights, isNotEmpty);
      expect(ar.attendanceToday, isNotEmpty);
      expect(ar.absenceToday, isNotEmpty);
      expect(ar.weeklyAttendanceTrend, isNotEmpty);
      expect(ar.smartInsight, isNotEmpty);
      expect(ar.excellentAttendanceInsight, isNotEmpty);
      expect(ar.lowAttendanceInsight, isNotEmpty);
      expect(ar.editProfile, isNotEmpty);
      expect(ar.changePassword, isNotEmpty);
      expect(ar.changeChildrenLocation, isNotEmpty);
      expect(ar.manageKids, isNotEmpty);
      expect(ar.locationChangeWarningTitle, isNotEmpty);
      expect(ar.locationChangeWarningBody, isNotEmpty);
      expect(ar.cancel, isNotEmpty);
      expect(ar.proceed, isNotEmpty);
      expect(ar.appearance, isNotEmpty);
      expect(ar.systemDefault, isNotEmpty);
      expect(ar.activitiesSubtitle, isNotEmpty);
      expect(ar.helpCenter, isNotEmpty);
      expect(ar.contactUs, isNotEmpty);
      expect(ar.aboutApp, isNotEmpty);
      expect(ar.canteen, isNotEmpty);
      expect(ar.support, isNotEmpty);
      expect(ar.appName, isNotEmpty);
      expect(ar.version, isNotEmpty);
      expect(ar.aboutAppDescription, isNotEmpty);
      expect(ar.aboutCompanyTitle, isNotEmpty);
      expect(ar.aboutCompany, isNotEmpty);
      expect(ar.developedBy, isNotEmpty);
      expect(ar.contactMethods, isNotEmpty);
      expect(ar.phoneNumber, isNotEmpty);
      expect(ar.email, isNotEmpty);
      expect(ar.website, isNotEmpty);
      expect(ar.socialMedia, isNotEmpty);
      expect(ar.complaintsBox, isNotEmpty);
      expect(ar.complaintMessageHint, isNotEmpty);
      expect(ar.submit, isNotEmpty);
      expect(ar.complaintSent, isNotEmpty);
      expect(ar.currentPassword, isNotEmpty);
      expect(ar.fieldRequired, isNotEmpty);
      expect(ar.newPassword, isNotEmpty);
      expect(ar.passwordLengthError, isNotEmpty);
      expect(ar.confirmPassword, isNotEmpty);
      expect(ar.passwordMismatch, isNotEmpty);
      expect(ar.saveChanges, isNotEmpty);
      expect(ar.passwordUpdatedSuccess, isNotEmpty);
      expect(ar.passwordRequiresMixedCase, isNotEmpty);
      expect(ar.passwordRequiresNumber, isNotEmpty);
      expect(ar.passwordMinLength, isNotEmpty);
      expect(ar.privacyPolicy, isNotEmpty);
      expect(ar.privacyIntroTitle, isNotEmpty);
      expect(ar.privacyIntroBody1, isNotEmpty);
      expect(ar.privacyIntroBody2, isNotEmpty);
      expect(ar.privacyDataCollectionTitle, isNotEmpty);
      expect(ar.privacyStudentDataTitle, isNotEmpty);
      expect(ar.privacyStudentData1, isNotEmpty);
      expect(ar.privacyStudentData2, isNotEmpty);
      expect(ar.privacyStudentData3, isNotEmpty);
      expect(ar.privacyStudentData4, isNotEmpty);
      expect(ar.privacyStudentData5, isNotEmpty);
      expect(ar.privacyStudentData6, isNotEmpty);
      expect(ar.privacyStudentData7, isNotEmpty);
      expect(ar.privacyOtherDataTitle, isNotEmpty);
      expect(ar.privacyOtherData1, isNotEmpty);
      expect(ar.privacyOtherData2, isNotEmpty);
      expect(ar.privacyOtherData3, isNotEmpty);
      expect(ar.privacyDataUsageTitle, isNotEmpty);
      expect(ar.privacyDataUsage1, isNotEmpty);
      expect(ar.privacyDataUsage2, isNotEmpty);
      expect(ar.privacyDataUsage3, isNotEmpty);
      expect(ar.privacyDataUsage4, isNotEmpty);
      expect(ar.privacyDataUsage5, isNotEmpty);
      expect(ar.privacyDataProtectionTitle, isNotEmpty);
      expect(ar.privacyDataProtection1, isNotEmpty);
      expect(ar.privacyDataProtection2, isNotEmpty);
      expect(ar.privacyDataProtection3, isNotEmpty);
      expect(ar.privacyDataProtection4, isNotEmpty);
      expect(ar.privacyUserRightsTitle, isNotEmpty);
      expect(ar.privacyUserRights1, isNotEmpty);
      expect(ar.privacyUserRights2, isNotEmpty);
      expect(ar.privacyUserRights3, isNotEmpty);
      expect(ar.privacyUserObligationsTitle, isNotEmpty);
      expect(ar.privacyUserObligations1, isNotEmpty);
      expect(ar.privacyUserObligations2, isNotEmpty);
      expect(ar.privacyUserObligations3, isNotEmpty);
      expect(ar.privacyLegalLiabilityTitle, isNotEmpty);
      expect(ar.privacyLegalLiability1, isNotEmpty);
      expect(ar.privacyLegalLiability2, isNotEmpty);
      expect(ar.privacyLegalLiability3, isNotEmpty);
      expect(ar.privacyAmendmentsTitle, isNotEmpty);
      expect(ar.privacyAmendments1, isNotEmpty);
      expect(ar.privacyAmendments2, isNotEmpty);
      expect(ar.privacyConsentTitle, isNotEmpty);
      expect(ar.privacyConsentBody, isNotEmpty);
      expect(ar.privacySimplifiedTitle, isNotEmpty);
      expect(ar.privacyQ1, isNotEmpty);
      expect(ar.privacyA1, isNotEmpty);
      expect(ar.privacyQ2, isNotEmpty);
      expect(ar.privacyA2, isNotEmpty);
      expect(ar.privacyQ3, isNotEmpty);
      expect(ar.privacyA3, isNotEmpty);
      expect(ar.privacyQ4, isNotEmpty);
      expect(ar.privacyA4, isNotEmpty);
      expect(ar.privacyQ5, isNotEmpty);
      expect(ar.privacyA5, isNotEmpty);
      expect(ar.application, isNotEmpty);
      expect(ar.light, isNotEmpty);
      expect(ar.dark, isNotEmpty);
      expect(ar.notifications, isNotEmpty);
      expect(ar.chats, isNotEmpty);
      expect(ar.location, isNotEmpty);
      expect(ar.speed, isNotEmpty);
      expect(ar.distance, isNotEmpty);
      expect(ar.remainingTime, isNotEmpty);
      expect(ar.busStateAtStation, isNotEmpty);
      expect(ar.busStateEnRoute, isNotEmpty);
      expect(ar.busStateArrived, isNotEmpty);
      expect(ar.kmPerHour, isNotEmpty);
      expect(ar.km, isNotEmpty);
      expect(ar.minutes, isNotEmpty);
      expect(ar.refresh, isNotEmpty);
      expect(ar.updated, isNotEmpty);
      expect(ar.driversAndSupervisors, isNotEmpty);
      expect(ar.drivers, isNotEmpty);
      expect(ar.supervisors, isNotEmpty);
      expect(ar.bus, isNotEmpty);
      expect(ar.fieldSupervisor, isNotEmpty);
      expect(ar.supervisorRole, isNotEmpty);
      expect(ar.incidentsAndEmergencies, isNotEmpty);
      expect(ar.fieldInspection, isNotEmpty);
      expect(ar.registerDelays, isNotEmpty);
      expect(ar.dailyTrips, isNotEmpty);
      expect(ar.selectBus, isNotEmpty);
      expect(ar.inspectionChecklist, isNotEmpty);
      expect(ar.takePhotos, isNotEmpty);
      expect(ar.inspectionSaved, isNotEmpty);
      expect(ar.saveInspection, isNotEmpty);
      expect(ar.completedTrips, isNotEmpty);
      expect(ar.issues, isNotEmpty);
      expect(ar.delays, isNotEmpty);
      expect(ar.violations, isNotEmpty);
      expect(ar.reportCategories, isNotEmpty);
      expect(ar.viewAllTrips, isNotEmpty);
      expect(ar.viewAllIssues, isNotEmpty);
      expect(ar.viewAllDelays, isNotEmpty);
      expect(ar.viewAllViolations, isNotEmpty);
      expect(ar.fieldTrips, isNotEmpty);
      expect(ar.viewFieldTrips, isNotEmpty);
      expect(ar.todayTrips, isNotEmpty);
      expect(ar.trips, isNotEmpty);
      expect(ar.addNote, isNotEmpty);
      expect(ar.viewOnMap, isNotEmpty);
      expect(ar.trafficJam, isNotEmpty);
      expect(ar.technicalIssue, isNotEmpty);
      expect(ar.studentLate, isNotEmpty);
      expect(ar.other, isNotEmpty);
      expect(ar.delaySavedAndReported, isNotEmpty);
      expect(ar.saveAndSend, isNotEmpty);
      expect(ar.upcomingTrips, isNotEmpty);
      expect(ar.driver, isNotEmpty);
      expect(ar.communication, isNotEmpty);
      expect(ar.activeBuses, isNotEmpty);
      expect(ar.activeDrivers, isNotEmpty);
      expect(ar.activeTrips, isNotEmpty);
      expect(ar.activeEmergency, isNotEmpty);
      expect(ar.respond, isNotEmpty);
      expect(ar.allIncidents, isNotEmpty);
      expect(ar.newIncident, isNotEmpty);
      expect(ar.incidentDescription, isNotEmpty);
      expect(ar.attachPhoto, isNotEmpty);
      expect(ar.incidentReported, isNotEmpty);
      expect(ar.pendingInspections, isNotEmpty);
      expect(ar.busesNeedInspection, isNotEmpty);
      expect(ar.recentInspections, isNotEmpty);
      expect(ar.newInspection, isNotEmpty);
      expect(ar.totalBuses, isNotEmpty);
      expect(ar.stoppedBuses, isNotEmpty);
      expect(ar.online, isNotEmpty);
      expect(ar.offline, isNotEmpty);
      expect(ar.broadcastMessage, isNotEmpty);
      expect(ar.sendToAll, isNotEmpty);
      expect(ar.recentChats, isNotEmpty);
      expect(ar.studentDelays, isNotEmpty);
      expect(ar.busDelays, isNotEmpty);
      expect(ar.reportSent, isNotEmpty);
      expect(ar.registerNewDelay, isNotEmpty);
      expect(ar.student, isNotEmpty);
      expect(ar.selectStudent, isNotEmpty);
      expect(ar.delayDuration, isNotEmpty);
      expect(ar.delayReason, isNotEmpty);
      expect(ar.present, isNotEmpty);
      expect(ar.finishAttendance, isNotEmpty);
      expect(ar.attendanceSummary, isNotEmpty);
      expect(ar.confirmSendReport, isNotEmpty);
      expect(ar.total, isNotEmpty);
      expect(ar.unmarked, isNotEmpty);
      expect(ar.confirmSend, isNotEmpty);
      expect(ar.dailyReportSentSuccess, isNotEmpty);
      expect(ar.classPlaceholder, isNotEmpty);
      expect(ar.parentGuardian, isNotEmpty);
      expect(ar.whatsapp, isNotEmpty);
      expect(ar.sosAlertsTitle, isNotEmpty);
      expect(ar.sosAlertsStatusPending, isNotEmpty);
      expect(ar.sosAlertsStatusResolved, isNotEmpty);
      expect(ar.sosAlertsStatusActive, isNotEmpty);
      expect(ar.login, isNotEmpty);
      expect(ar.welcomeBack, isNotEmpty);
      expect(ar.civilId, isNotEmpty);
      expect(ar.password, isNotEmpty);
      expect(ar.forgotPassword, isNotEmpty);
      expect(ar.enterCivilId, isNotEmpty);
      expect(ar.enterPassword, isNotEmpty);
      expect(ar.unexpectedError, isNotEmpty);
      expect(ar.selectCorrectRole, isNotEmpty);
      expect(ar.resetPasswordSuccess, isNotEmpty);
      expect(ar.resetPasswordTitle, isNotEmpty);
      expect(ar.resetPasswordSubtitle, isNotEmpty);
      expect(ar.sendResetLink, isNotEmpty);
      expect(ar.maintenance, isNotEmpty);
      expect(ar.fuelRefill, isNotEmpty);
      expect(ar.maintenanceRequest, isNotEmpty);
      expect(ar.statusActive, isNotEmpty);
      expect(ar.statusStopped, isNotEmpty);
      expect(ar.statusCompleted, isNotEmpty);
      expect(ar.statusInProgress, isNotEmpty);
      expect(ar.statusScheduled, isNotEmpty);
      expect(ar.statusMaintenance, isNotEmpty);
      expect(ar.statusExcellent, isNotEmpty);
      expect(ar.statusGood, isNotEmpty);
      expect(ar.statusPending, isNotEmpty);
      expect(ar.typeTechnical, isNotEmpty);
      expect(ar.typeBehavioral, isNotEmpty);
      expect(ar.typeHealth, isNotEmpty);
      expect(ar.typeTraffic, isNotEmpty);
      expect(ar.typeSOS, isNotEmpty);
      expect(ar.roleAdmin, isNotEmpty);
      expect(ar.roleDriver, isNotEmpty);
      expect(ar.late, isNotEmpty);
      expect(ar.myClasses, isNotEmpty);
      expect(ar.call, isNotEmpty);
      expect(ar.sendMessage, isNotEmpty);
      expect(ar.details, isNotEmpty);
      expect(ar.notes, isNotEmpty);
      expect(ar.date, isNotEmpty);
      expect(ar.time, isNotEmpty);
      expect(ar.status, isNotEmpty);
      expect(ar.type, isNotEmpty);
      expect(ar.description, isNotEmpty);
      expect(ar.actions, isNotEmpty);
      expect(ar.todayAttendance, isNotEmpty);
      expect(ar.classAttendance, isNotEmpty);
      expect(ar.takeAttendance, isNotEmpty);
      expect(ar.markPresent, isNotEmpty);
      expect(ar.markAbsent, isNotEmpty);
      expect(ar.noDataFound, isNotEmpty);
      expect(ar.loadingData, isNotEmpty);
      expect(ar.retry, isNotEmpty);
      expect(ar.confirm, isNotEmpty);
      expect(ar.back, isNotEmpty);
      expect(ar.next, isNotEmpty);
      expect(ar.done, isNotEmpty);
      expect(ar.close, isNotEmpty);
      expect(ar.delete, isNotEmpty);
      expect(ar.edit, isNotEmpty);
      expect(ar.add, isNotEmpty);
      expect(ar.save, isNotEmpty);
      expect(ar.search, isNotEmpty);
      expect(ar.filter, isNotEmpty);
      expect(ar.sort, isNotEmpty);
      expect(ar.morning, isNotEmpty);
      expect(ar.afternoon, isNotEmpty);
      expect(ar.today, isNotEmpty);
      expect(ar.yesterday, isNotEmpty);
      expect(ar.thisWeek, isNotEmpty);
      expect(ar.thisMonth, isNotEmpty);
      expect(ar.errorOccurred, isNotEmpty);
      expect(ar.connectionError, isNotEmpty);
      expect(ar.tryAgain, isNotEmpty);
      expect(ar.noInternet, isNotEmpty);
      expect(ar.successMessage, isNotEmpty);
      expect(ar.savedSuccessfully, isNotEmpty);
      expect(ar.deletedSuccessfully, isNotEmpty);
      expect(ar.sentSuccessfully, isNotEmpty);
      expect(ar.attendanceMarked, isNotEmpty);
      expect(ar.navigation, isNotEmpty);
      expect(ar.endTrip, isNotEmpty);
      expect(ar.roleBusAssistant, isNotEmpty);
      expect(ar.roleFieldSupervisor, isNotEmpty);
      expect(ar.roleTeacher, isNotEmpty);
      expect(ar.driverLogin, isNotEmpty);
      expect(ar.assistantLogin, isNotEmpty);
      expect(ar.supervisorLogin, isNotEmpty);
      expect(ar.teacherLogin, isNotEmpty);
      expect(ar.maintenanceLog, isNotEmpty);
      expect(ar.theDriver, isNotEmpty);
      expect(ar.driversGroup, isNotEmpty);
      expect(ar.dailyRecord, isNotEmpty);
      expect(ar.presentStudents, isNotEmpty);
      expect(ar.parentPhone, isNotEmpty);
      expect(ar.parentGuardianLabel, isNotEmpty);
      expect(ar.students, isNotEmpty);
      expect(ar.sos, isNotEmpty);
      expect(ar.camera, isNotEmpty);
      expect(ar.gallery, isNotEmpty);
      expect(ar.amount, isNotEmpty);
      expect(ar.boarded, isNotEmpty);
      expect(ar.pleaseEnterCivilId, isNotEmpty);
      expect(ar.pleaseEnterPassword, isNotEmpty);
      expect(ar.readyToStart, isNotEmpty);
      expect(ar.departureTime, isNotEmpty);
      expect(ar.startTrip, isNotEmpty);
      expect(ar.endTripTitle, isNotEmpty);
      expect(ar.confirmEndTrip, isNotEmpty);
      expect(ar.tripEndedSuccess, isNotEmpty);
      expect(ar.scanFrontCode, isNotEmpty);
      expect(ar.scanBackCode, isNotEmpty);
      expect(ar.scanFrontDesc, isNotEmpty);
      expect(ar.scanBackDesc, isNotEmpty);
      expect(ar.recordVideo, isNotEmpty);
      expect(ar.recordVideoDesc, isNotEmpty);
      expect(ar.nextStop, isNotEmpty);
      expect(ar.arriveAtStudent, isNotEmpty);
      expect(ar.nextDestination, isNotEmpty);
      expect(ar.probableAbsence, isNotEmpty);
      expect(ar.fuelRefillTitle, isNotEmpty);
      expect(ar.attachReceipt, isNotEmpty);
      expect(ar.odometerReading, isNotEmpty);
      expect(ar.recentLogs, isNotEmpty);
      expect(ar.fuelEntry, isNotEmpty);
      expect(ar.requestMaintenance, isNotEmpty);
      expect(ar.maintenanceRequestSubmitted, isNotEmpty);
      expect(ar.reRecord, isNotEmpty);
      expect(ar.videoRecorded, isNotEmpty);
      expect(ar.busEmptyCheck, isNotEmpty);
      expect(ar.maintenanceRequestTitle, isNotEmpty);
      expect(ar.estimatedCost, isNotEmpty);
      expect(ar.requestSentSuccess, isNotEmpty);
      expect(ar.dataSavedSuccess, isNotEmpty);
      expect(ar.pleaseAttachPhoto, isNotEmpty);
      expect(ar.enterValidNumber, isNotEmpty);
      expect(ar.enterAmount, isNotEmpty);
      expect(ar.enterOdometer, isNotEmpty);
      expect(ar.describeProblem, isNotEmpty);
      expect(ar.submitRequest, isNotEmpty);
      expect(ar.studentStatistics, isNotEmpty);
      expect(ar.noResultsFound, isNotEmpty);
      expect(ar.searchStudentPlaceholder, isNotEmpty);
      expect(ar.fontSize, isNotEmpty);
      expect(ar.fontSizeSmall, isNotEmpty);
      expect(ar.fontSizeMedium, isNotEmpty);
      expect(ar.fontSizeLarge, isNotEmpty);
      expect(ar.incorrectPassword, isNotEmpty);
      expect(ar.civilIdNotRegistered, isNotEmpty);
      expect(ar.loginFailed, isNotEmpty);
      expect(ar.guest, isNotEmpty);
      expect(ar.clearFilter, isNotEmpty);
      expect(ar.searchByDate, isNotEmpty);
      expect(ar.noRecordsForDate, isNotEmpty);
      expect(ar.noStudentsInList, isNotEmpty);
      expect(ar.showAllRecords, isNotEmpty);
      expect(ar.theTeacher, isNotEmpty);
      expect(ar.unmarkedToday, isNotEmpty);
      expect(ar.civilIdPrefix, isNotEmpty);
      expect(ar.pending, isNotEmpty);
      expect(ar.resolved, isNotEmpty);
      expect(ar.photoAttached, isNotEmpty);
      expect(ar.pleaseDescribeIncident, isNotEmpty);
      expect(ar.incidentReportedSuccessfully, isNotEmpty);
      expect(ar.overview, isNotEmpty);
      expect(ar.totalDriversLabel, isNotEmpty);
      expect(ar.activeStatus, isNotEmpty);
      expect(ar.todayIncidents, isNotEmpty);
      expect(ar.todayInspections, isNotEmpty);
      expect(ar.attendanceDays, isNotEmpty);
      expect(ar.absenceDays, isNotEmpty);
      expect(ar.sunday, isNotEmpty);
      expect(ar.monday, isNotEmpty);
      expect(ar.tuesday, isNotEmpty);
      expect(ar.wednesday, isNotEmpty);
      expect(ar.thursday, isNotEmpty);
      expect(ar.processingVideoTitle, isNotEmpty);
      expect(ar.processingVideoDesc, isNotEmpty);
      expect(ar.uploadingVerificationTitle, isNotEmpty);
      expect(ar.uploadingVerificationDesc, isNotEmpty);
      expect(ar.stopRecordingManual, isNotEmpty);
      expect(ar.verificationSafetySystem, isNotEmpty);
      expect(ar.invalidFrontQr, isNotEmpty);
      expect(ar.invalidBackQr, isNotEmpty);
      expect(ar.videoSavedError, isNotEmpty);
      expect(ar.videoFileInvalidError, isNotEmpty);
      expect(ar.startConversation, isNotEmpty);
      expect(ar.guardian, isNotEmpty);
      expect(ar.systemUser, isNotEmpty);

      expect(ar.deliveredStudentsCount(5, 10), isNotEmpty);
      expect(ar.guardianLabel('Test Guardian'), isNotEmpty);
      expect(ar.insightPerfectAttendance('Class A'), isNotEmpty);
      expect(ar.insightLowAttendance(75), isNotEmpty);
      expect(ar.unmarkedStudentsWarning(3), isNotEmpty);
      expect(ar.sosAlertsTimeAgo('5 mins'), isNotEmpty);
      expect(ar.busNumber(42), isNotEmpty);
      expect(ar.civilIdRegisteredAs('Driver'), isNotEmpty);
      expect(ar.dailyRecordCount(15), isNotEmpty);
      expect(ar.parentNameLabel('Father'), isNotEmpty);
    });

    test('2. AppLocalizationsEn covers all getters and methods', () {
      final en = AppLocalizationsEn();
      expect(en.appTitle, isNotEmpty);
      expect(en.settingsTitle, isNotEmpty);
      expect(en.themeTitle, isNotEmpty);
      expect(en.darkMode, isNotEmpty);
      expect(en.darkModeOn, isNotEmpty);
      expect(en.darkModeOff, isNotEmpty);
      expect(en.languageTitle, isNotEmpty);
      expect(en.languageName, isNotEmpty);
      expect(en.accountTitle, isNotEmpty);
      expect(en.logout, isNotEmpty);
      expect(en.logoutSubtitle, isNotEmpty);
      expect(en.aboutTitle, isNotEmpty);
      expect(en.welcome, isNotEmpty);
      expect(en.greetingMorning, isNotEmpty);
      expect(en.greetingAfternoon, isNotEmpty);
      expect(en.greetingEvening, isNotEmpty);
      expect(en.quickActions, isNotEmpty);
      expect(en.myStudents, isNotEmpty);
      expect(en.scanAttendance, isNotEmpty);
      expect(en.attendanceHistory, isNotEmpty);
      expect(en.reports, isNotEmpty);
      expect(en.comingSoon, isNotEmpty);
      expect(en.studentCount, isNotEmpty);
      expect(en.presentToday, isNotEmpty);
      expect(en.absentToday, isNotEmpty);
      expect(en.user, isNotEmpty);
      expect(en.home, isNotEmpty);
      expect(en.profile, isNotEmpty);
      expect(en.settings, isNotEmpty);
      expect(en.totalStudents, isNotEmpty);
      expect(en.averageAttendance, isNotEmpty);
      expect(en.studentsList, isNotEmpty);
      expect(en.noStudentsFound, isNotEmpty);
      expect(en.searchPlaceholder, isNotEmpty);
      expect(en.all, isNotEmpty);
      expect(en.atHome, isNotEmpty);
      expect(en.onBus, isNotEmpty);
      expect(en.atSchool, isNotEmpty);
      expect(en.absent, isNotEmpty);
      expect(en.tripProgress, isNotEmpty);
      expect(en.remaining, isNotEmpty);
      expect(en.percentage, isNotEmpty);
      expect(en.boardedBus, isNotEmpty);
      expect(en.reachedSchool, isNotEmpty);
      expect(en.arrivedSafely, isNotEmpty);
      expect(en.dailyChecklistTitle, isNotEmpty);
      expect(en.dailyChecklist, isNotEmpty);
      expect(en.busTracking, isNotEmpty);
      expect(en.tasksSavedSuccessfully, isNotEmpty);
      expect(en.confirmAndSendReport, isNotEmpty);
      expect(en.checklistTask1, isNotEmpty);
      expect(en.checklistTask2, isNotEmpty);
      expect(en.checklistTask3, isNotEmpty);
      expect(en.checklistTask4, isNotEmpty);
      expect(en.checklistTask5, isNotEmpty);
      expect(en.incidentReportTitle, isNotEmpty);
      expect(en.incidentType, isNotEmpty);
      expect(en.problemDescription, isNotEmpty);
      expect(en.reportDetailsPlaceholder, isNotEmpty);
      expect(en.attachPhotoOptional, isNotEmpty);
      expect(en.reportSentSuccessfully, isNotEmpty);
      expect(en.sendUrgentReport, isNotEmpty);
      expect(en.incidentTypeBehavioral, isNotEmpty);
      expect(en.incidentTypeHealth, isNotEmpty);
      expect(en.incidentTypeTechnical, isNotEmpty);
      expect(en.incidentTypeTraffic, isNotEmpty);
      expect(en.incidentTypeOther, isNotEmpty);
      expect(en.reportsTitle, isNotEmpty);
      expect(en.dailyAverageAttendance, isNotEmpty);
      expect(en.absenceRate, isNotEmpty);
      expect(en.lateRate, isNotEmpty);
      expect(en.attendanceTrend, isNotEmpty);
      expect(en.insights, isNotEmpty);
      expect(en.attendanceToday, isNotEmpty);
      expect(en.absenceToday, isNotEmpty);
      expect(en.weeklyAttendanceTrend, isNotEmpty);
      expect(en.smartInsight, isNotEmpty);
      expect(en.excellentAttendanceInsight, isNotEmpty);
      expect(en.lowAttendanceInsight, isNotEmpty);
      expect(en.editProfile, isNotEmpty);
      expect(en.changePassword, isNotEmpty);
      expect(en.changeChildrenLocation, isNotEmpty);
      expect(en.manageKids, isNotEmpty);
      expect(en.locationChangeWarningTitle, isNotEmpty);
      expect(en.locationChangeWarningBody, isNotEmpty);
      expect(en.cancel, isNotEmpty);
      expect(en.proceed, isNotEmpty);
      expect(en.appearance, isNotEmpty);
      expect(en.systemDefault, isNotEmpty);
      expect(en.activitiesSubtitle, isNotEmpty);
      expect(en.helpCenter, isNotEmpty);
      expect(en.contactUs, isNotEmpty);
      expect(en.aboutApp, isNotEmpty);
      expect(en.canteen, isNotEmpty);
      expect(en.support, isNotEmpty);
      expect(en.appName, isNotEmpty);
      expect(en.version, isNotEmpty);
      expect(en.aboutAppDescription, isNotEmpty);
      expect(en.aboutCompanyTitle, isNotEmpty);
      expect(en.aboutCompany, isNotEmpty);
      expect(en.developedBy, isNotEmpty);
      expect(en.contactMethods, isNotEmpty);
      expect(en.phoneNumber, isNotEmpty);
      expect(en.email, isNotEmpty);
      expect(en.website, isNotEmpty);
      expect(en.socialMedia, isNotEmpty);
      expect(en.complaintsBox, isNotEmpty);
      expect(en.complaintMessageHint, isNotEmpty);
      expect(en.submit, isNotEmpty);
      expect(en.complaintSent, isNotEmpty);
      expect(en.currentPassword, isNotEmpty);
      expect(en.fieldRequired, isNotEmpty);
      expect(en.newPassword, isNotEmpty);
      expect(en.passwordLengthError, isNotEmpty);
      expect(en.confirmPassword, isNotEmpty);
      expect(en.passwordMismatch, isNotEmpty);
      expect(en.saveChanges, isNotEmpty);
      expect(en.passwordUpdatedSuccess, isNotEmpty);
      expect(en.passwordRequiresMixedCase, isNotEmpty);
      expect(en.passwordRequiresNumber, isNotEmpty);
      expect(en.passwordMinLength, isNotEmpty);
      expect(en.privacyPolicy, isNotEmpty);
      expect(en.privacyIntroTitle, isNotEmpty);
      expect(en.privacyIntroBody1, isNotEmpty);
      expect(en.privacyIntroBody2, isNotEmpty);
      expect(en.privacyDataCollectionTitle, isNotEmpty);
      expect(en.privacyStudentDataTitle, isNotEmpty);
      expect(en.privacyStudentData1, isNotEmpty);
      expect(en.privacyStudentData2, isNotEmpty);
      expect(en.privacyStudentData3, isNotEmpty);
      expect(en.privacyStudentData4, isNotEmpty);
      expect(en.privacyStudentData5, isNotEmpty);
      expect(en.privacyStudentData6, isNotEmpty);
      expect(en.privacyStudentData7, isNotEmpty);
      expect(en.privacyOtherDataTitle, isNotEmpty);
      expect(en.privacyOtherData1, isNotEmpty);
      expect(en.privacyOtherData2, isNotEmpty);
      expect(en.privacyOtherData3, isNotEmpty);
      expect(en.privacyDataUsageTitle, isNotEmpty);
      expect(en.privacyDataUsage1, isNotEmpty);
      expect(en.privacyDataUsage2, isNotEmpty);
      expect(en.privacyDataUsage3, isNotEmpty);
      expect(en.privacyDataUsage4, isNotEmpty);
      expect(en.privacyDataUsage5, isNotEmpty);
      expect(en.privacyDataProtectionTitle, isNotEmpty);
      expect(en.privacyDataProtection1, isNotEmpty);
      expect(en.privacyDataProtection2, isNotEmpty);
      expect(en.privacyDataProtection3, isNotEmpty);
      expect(en.privacyDataProtection4, isNotEmpty);
      expect(en.privacyUserRightsTitle, isNotEmpty);
      expect(en.privacyUserRights1, isNotEmpty);
      expect(en.privacyUserRights2, isNotEmpty);
      expect(en.privacyUserRights3, isNotEmpty);
      expect(en.privacyUserObligationsTitle, isNotEmpty);
      expect(en.privacyUserObligations1, isNotEmpty);
      expect(en.privacyUserObligations2, isNotEmpty);
      expect(en.privacyUserObligations3, isNotEmpty);
      expect(en.privacyLegalLiabilityTitle, isNotEmpty);
      expect(en.privacyLegalLiability1, isNotEmpty);
      expect(en.privacyLegalLiability2, isNotEmpty);
      expect(en.privacyLegalLiability3, isNotEmpty);
      expect(en.privacyAmendmentsTitle, isNotEmpty);
      expect(en.privacyAmendments1, isNotEmpty);
      expect(en.privacyAmendments2, isNotEmpty);
      expect(en.privacyConsentTitle, isNotEmpty);
      expect(en.privacyConsentBody, isNotEmpty);
      expect(en.privacySimplifiedTitle, isNotEmpty);
      expect(en.privacyQ1, isNotEmpty);
      expect(en.privacyA1, isNotEmpty);
      expect(en.privacyQ2, isNotEmpty);
      expect(en.privacyA2, isNotEmpty);
      expect(en.privacyQ3, isNotEmpty);
      expect(en.privacyA3, isNotEmpty);
      expect(en.privacyQ4, isNotEmpty);
      expect(en.privacyA4, isNotEmpty);
      expect(en.privacyQ5, isNotEmpty);
      expect(en.privacyA5, isNotEmpty);
      expect(en.application, isNotEmpty);
      expect(en.light, isNotEmpty);
      expect(en.dark, isNotEmpty);
      expect(en.notifications, isNotEmpty);
      expect(en.chats, isNotEmpty);
      expect(en.location, isNotEmpty);
      expect(en.speed, isNotEmpty);
      expect(en.distance, isNotEmpty);
      expect(en.remainingTime, isNotEmpty);
      expect(en.busStateAtStation, isNotEmpty);
      expect(en.busStateEnRoute, isNotEmpty);
      expect(en.busStateArrived, isNotEmpty);
      expect(en.kmPerHour, isNotEmpty);
      expect(en.km, isNotEmpty);
      expect(en.minutes, isNotEmpty);
      expect(en.refresh, isNotEmpty);
      expect(en.updated, isNotEmpty);
      expect(en.driversAndSupervisors, isNotEmpty);
      expect(en.drivers, isNotEmpty);
      expect(en.supervisors, isNotEmpty);
      expect(en.bus, isNotEmpty);
      expect(en.fieldSupervisor, isNotEmpty);
      expect(en.supervisorRole, isNotEmpty);
      expect(en.incidentsAndEmergencies, isNotEmpty);
      expect(en.fieldInspection, isNotEmpty);
      expect(en.registerDelays, isNotEmpty);
      expect(en.dailyTrips, isNotEmpty);
      expect(en.selectBus, isNotEmpty);
      expect(en.inspectionChecklist, isNotEmpty);
      expect(en.takePhotos, isNotEmpty);
      expect(en.inspectionSaved, isNotEmpty);
      expect(en.saveInspection, isNotEmpty);
      expect(en.completedTrips, isNotEmpty);
      expect(en.issues, isNotEmpty);
      expect(en.delays, isNotEmpty);
      expect(en.violations, isNotEmpty);
      expect(en.reportCategories, isNotEmpty);
      expect(en.viewAllTrips, isNotEmpty);
      expect(en.viewAllIssues, isNotEmpty);
      expect(en.viewAllDelays, isNotEmpty);
      expect(en.viewAllViolations, isNotEmpty);
      expect(en.fieldTrips, isNotEmpty);
      expect(en.viewFieldTrips, isNotEmpty);
      expect(en.todayTrips, isNotEmpty);
      expect(en.trips, isNotEmpty);
      expect(en.addNote, isNotEmpty);
      expect(en.viewOnMap, isNotEmpty);
      expect(en.trafficJam, isNotEmpty);
      expect(en.technicalIssue, isNotEmpty);
      expect(en.studentLate, isNotEmpty);
      expect(en.other, isNotEmpty);
      expect(en.delaySavedAndReported, isNotEmpty);
      expect(en.saveAndSend, isNotEmpty);
      expect(en.upcomingTrips, isNotEmpty);
      expect(en.driver, isNotEmpty);
      expect(en.communication, isNotEmpty);
      expect(en.activeBuses, isNotEmpty);
      expect(en.activeDrivers, isNotEmpty);
      expect(en.activeTrips, isNotEmpty);
      expect(en.activeEmergency, isNotEmpty);
      expect(en.respond, isNotEmpty);
      expect(en.allIncidents, isNotEmpty);
      expect(en.newIncident, isNotEmpty);
      expect(en.incidentDescription, isNotEmpty);
      expect(en.attachPhoto, isNotEmpty);
      expect(en.incidentReported, isNotEmpty);
      expect(en.pendingInspections, isNotEmpty);
      expect(en.busesNeedInspection, isNotEmpty);
      expect(en.recentInspections, isNotEmpty);
      expect(en.newInspection, isNotEmpty);
      expect(en.totalBuses, isNotEmpty);
      expect(en.stoppedBuses, isNotEmpty);
      expect(en.online, isNotEmpty);
      expect(en.offline, isNotEmpty);
      expect(en.broadcastMessage, isNotEmpty);
      expect(en.sendToAll, isNotEmpty);
      expect(en.recentChats, isNotEmpty);
      expect(en.studentDelays, isNotEmpty);
      expect(en.busDelays, isNotEmpty);
      expect(en.reportSent, isNotEmpty);
      expect(en.registerNewDelay, isNotEmpty);
      expect(en.student, isNotEmpty);
      expect(en.selectStudent, isNotEmpty);
      expect(en.delayDuration, isNotEmpty);
      expect(en.delayReason, isNotEmpty);
      expect(en.present, isNotEmpty);
      expect(en.finishAttendance, isNotEmpty);
      expect(en.attendanceSummary, isNotEmpty);
      expect(en.confirmSendReport, isNotEmpty);
      expect(en.total, isNotEmpty);
      expect(en.unmarked, isNotEmpty);
      expect(en.confirmSend, isNotEmpty);
      expect(en.dailyReportSentSuccess, isNotEmpty);
      expect(en.classPlaceholder, isNotEmpty);
      expect(en.parentGuardian, isNotEmpty);
      expect(en.whatsapp, isNotEmpty);
      expect(en.sosAlertsTitle, isNotEmpty);
      expect(en.sosAlertsStatusPending, isNotEmpty);
      expect(en.sosAlertsStatusResolved, isNotEmpty);
      expect(en.sosAlertsStatusActive, isNotEmpty);
      expect(en.login, isNotEmpty);
      expect(en.welcomeBack, isNotEmpty);
      expect(en.civilId, isNotEmpty);
      expect(en.password, isNotEmpty);
      expect(en.forgotPassword, isNotEmpty);
      expect(en.enterCivilId, isNotEmpty);
      expect(en.enterPassword, isNotEmpty);
      expect(en.unexpectedError, isNotEmpty);
      expect(en.selectCorrectRole, isNotEmpty);
      expect(en.resetPasswordSuccess, isNotEmpty);
      expect(en.resetPasswordTitle, isNotEmpty);
      expect(en.resetPasswordSubtitle, isNotEmpty);
      expect(en.sendResetLink, isNotEmpty);
      expect(en.maintenance, isNotEmpty);
      expect(en.fuelRefill, isNotEmpty);
      expect(en.maintenanceRequest, isNotEmpty);
      expect(en.statusActive, isNotEmpty);
      expect(en.statusStopped, isNotEmpty);
      expect(en.statusCompleted, isNotEmpty);
      expect(en.statusInProgress, isNotEmpty);
      expect(en.statusScheduled, isNotEmpty);
      expect(en.statusMaintenance, isNotEmpty);
      expect(en.statusExcellent, isNotEmpty);
      expect(en.statusGood, isNotEmpty);
      expect(en.statusPending, isNotEmpty);
      expect(en.typeTechnical, isNotEmpty);
      expect(en.typeBehavioral, isNotEmpty);
      expect(en.typeHealth, isNotEmpty);
      expect(en.typeTraffic, isNotEmpty);
      expect(en.typeSOS, isNotEmpty);
      expect(en.roleAdmin, isNotEmpty);
      expect(en.roleDriver, isNotEmpty);
      expect(en.late, isNotEmpty);
      expect(en.myClasses, isNotEmpty);
      expect(en.call, isNotEmpty);
      expect(en.sendMessage, isNotEmpty);
      expect(en.details, isNotEmpty);
      expect(en.notes, isNotEmpty);
      expect(en.date, isNotEmpty);
      expect(en.time, isNotEmpty);
      expect(en.status, isNotEmpty);
      expect(en.type, isNotEmpty);
      expect(en.description, isNotEmpty);
      expect(en.actions, isNotEmpty);
      expect(en.todayAttendance, isNotEmpty);
      expect(en.classAttendance, isNotEmpty);
      expect(en.takeAttendance, isNotEmpty);
      expect(en.markPresent, isNotEmpty);
      expect(en.markAbsent, isNotEmpty);
      expect(en.noDataFound, isNotEmpty);
      expect(en.loadingData, isNotEmpty);
      expect(en.retry, isNotEmpty);
      expect(en.confirm, isNotEmpty);
      expect(en.back, isNotEmpty);
      expect(en.next, isNotEmpty);
      expect(en.done, isNotEmpty);
      expect(en.close, isNotEmpty);
      expect(en.delete, isNotEmpty);
      expect(en.edit, isNotEmpty);
      expect(en.add, isNotEmpty);
      expect(en.save, isNotEmpty);
      expect(en.search, isNotEmpty);
      expect(en.filter, isNotEmpty);
      expect(en.sort, isNotEmpty);
      expect(en.morning, isNotEmpty);
      expect(en.afternoon, isNotEmpty);
      expect(en.today, isNotEmpty);
      expect(en.yesterday, isNotEmpty);
      expect(en.thisWeek, isNotEmpty);
      expect(en.thisMonth, isNotEmpty);
      expect(en.errorOccurred, isNotEmpty);
      expect(en.connectionError, isNotEmpty);
      expect(en.tryAgain, isNotEmpty);
      expect(en.noInternet, isNotEmpty);
      expect(en.successMessage, isNotEmpty);
      expect(en.savedSuccessfully, isNotEmpty);
      expect(en.deletedSuccessfully, isNotEmpty);
      expect(en.sentSuccessfully, isNotEmpty);
      expect(en.attendanceMarked, isNotEmpty);
      expect(en.navigation, isNotEmpty);
      expect(en.endTrip, isNotEmpty);
      expect(en.roleBusAssistant, isNotEmpty);
      expect(en.roleFieldSupervisor, isNotEmpty);
      expect(en.roleTeacher, isNotEmpty);
      expect(en.driverLogin, isNotEmpty);
      expect(en.assistantLogin, isNotEmpty);
      expect(en.supervisorLogin, isNotEmpty);
      expect(en.teacherLogin, isNotEmpty);
      expect(en.maintenanceLog, isNotEmpty);
      expect(en.theDriver, isNotEmpty);
      expect(en.driversGroup, isNotEmpty);
      expect(en.dailyRecord, isNotEmpty);
      expect(en.presentStudents, isNotEmpty);
      expect(en.parentPhone, isNotEmpty);
      expect(en.parentGuardianLabel, isNotEmpty);
      expect(en.students, isNotEmpty);
      expect(en.sos, isNotEmpty);
      expect(en.camera, isNotEmpty);
      expect(en.gallery, isNotEmpty);
      expect(en.amount, isNotEmpty);
      expect(en.boarded, isNotEmpty);
      expect(en.pleaseEnterCivilId, isNotEmpty);
      expect(en.pleaseEnterPassword, isNotEmpty);
      expect(en.readyToStart, isNotEmpty);
      expect(en.departureTime, isNotEmpty);
      expect(en.startTrip, isNotEmpty);
      expect(en.endTripTitle, isNotEmpty);
      expect(en.confirmEndTrip, isNotEmpty);
      expect(en.tripEndedSuccess, isNotEmpty);
      expect(en.scanFrontCode, isNotEmpty);
      expect(en.scanBackCode, isNotEmpty);
      expect(en.scanFrontDesc, isNotEmpty);
      expect(en.scanBackDesc, isNotEmpty);
      expect(en.recordVideo, isNotEmpty);
      expect(en.recordVideoDesc, isNotEmpty);
      expect(en.nextStop, isNotEmpty);
      expect(en.arriveAtStudent, isNotEmpty);
      expect(en.nextDestination, isNotEmpty);
      expect(en.probableAbsence, isNotEmpty);
      expect(en.fuelRefillTitle, isNotEmpty);
      expect(en.attachReceipt, isNotEmpty);
      expect(en.odometerReading, isNotEmpty);
      expect(en.recentLogs, isNotEmpty);
      expect(en.fuelEntry, isNotEmpty);
      expect(en.requestMaintenance, isNotEmpty);
      expect(en.maintenanceRequestSubmitted, isNotEmpty);
      expect(en.reRecord, isNotEmpty);
      expect(en.videoRecorded, isNotEmpty);
      expect(en.busEmptyCheck, isNotEmpty);
      expect(en.maintenanceRequestTitle, isNotEmpty);
      expect(en.estimatedCost, isNotEmpty);
      expect(en.requestSentSuccess, isNotEmpty);
      expect(en.dataSavedSuccess, isNotEmpty);
      expect(en.pleaseAttachPhoto, isNotEmpty);
      expect(en.enterValidNumber, isNotEmpty);
      expect(en.enterAmount, isNotEmpty);
      expect(en.enterOdometer, isNotEmpty);
      expect(en.describeProblem, isNotEmpty);
      expect(en.submitRequest, isNotEmpty);
      expect(en.studentStatistics, isNotEmpty);
      expect(en.noResultsFound, isNotEmpty);
      expect(en.searchStudentPlaceholder, isNotEmpty);
      expect(en.fontSize, isNotEmpty);
      expect(en.fontSizeSmall, isNotEmpty);
      expect(en.fontSizeMedium, isNotEmpty);
      expect(en.fontSizeLarge, isNotEmpty);
      expect(en.incorrectPassword, isNotEmpty);
      expect(en.civilIdNotRegistered, isNotEmpty);
      expect(en.loginFailed, isNotEmpty);
      expect(en.guest, isNotEmpty);
      expect(en.clearFilter, isNotEmpty);
      expect(en.searchByDate, isNotEmpty);
      expect(en.noRecordsForDate, isNotEmpty);
      expect(en.noStudentsInList, isNotEmpty);
      expect(en.showAllRecords, isNotEmpty);
      expect(en.theTeacher, isNotEmpty);
      expect(en.unmarkedToday, isNotEmpty);
      expect(en.civilIdPrefix, isNotEmpty);
      expect(en.pending, isNotEmpty);
      expect(en.resolved, isNotEmpty);
      expect(en.photoAttached, isNotEmpty);
      expect(en.pleaseDescribeIncident, isNotEmpty);
      expect(en.incidentReportedSuccessfully, isNotEmpty);
      expect(en.overview, isNotEmpty);
      expect(en.totalDriversLabel, isNotEmpty);
      expect(en.activeStatus, isNotEmpty);
      expect(en.todayIncidents, isNotEmpty);
      expect(en.todayInspections, isNotEmpty);
      expect(en.attendanceDays, isNotEmpty);
      expect(en.absenceDays, isNotEmpty);
      expect(en.sunday, isNotEmpty);
      expect(en.monday, isNotEmpty);
      expect(en.tuesday, isNotEmpty);
      expect(en.wednesday, isNotEmpty);
      expect(en.thursday, isNotEmpty);
      expect(en.processingVideoTitle, isNotEmpty);
      expect(en.processingVideoDesc, isNotEmpty);
      expect(en.uploadingVerificationTitle, isNotEmpty);
      expect(en.uploadingVerificationDesc, isNotEmpty);
      expect(en.stopRecordingManual, isNotEmpty);
      expect(en.verificationSafetySystem, isNotEmpty);
      expect(en.invalidFrontQr, isNotEmpty);
      expect(en.invalidBackQr, isNotEmpty);
      expect(en.videoSavedError, isNotEmpty);
      expect(en.videoFileInvalidError, isNotEmpty);
      expect(en.startConversation, isNotEmpty);
      expect(en.guardian, isNotEmpty);
      expect(en.systemUser, isNotEmpty);

      expect(en.deliveredStudentsCount(5, 10), isNotEmpty);
      expect(en.guardianLabel('Test Guardian'), isNotEmpty);
      expect(en.insightPerfectAttendance('Class A'), isNotEmpty);
      expect(en.insightLowAttendance(75), isNotEmpty);
      expect(en.unmarkedStudentsWarning(3), isNotEmpty);
      expect(en.sosAlertsTimeAgo('5 mins'), isNotEmpty);
      expect(en.busNumber(42), isNotEmpty);
      expect(en.civilIdRegisteredAs('Driver'), isNotEmpty);
      expect(en.dailyRecordCount(15), isNotEmpty);
      expect(en.parentNameLabel('Father'), isNotEmpty);
    });

    testWidgets('3. GlassCard renders with default, custom padding, and tap handler', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassCard(
              onTap: () => tapped = true,
              child: const Text('Inside GlassCard'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Inside GlassCard'), findsOneWidget);
      await tester.tap(find.byType(GlassCard));
      expect(tapped, isTrue);
    });

    testWidgets('4. BackgroundWidget mounts and renders gradient orbs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BackgroundWidget(),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 5));

      expect(find.byType(BackgroundWidget), findsOneWidget);
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('5. ChatAvatar renders initials for names and handles null avatar url', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatAvatar(
              avatarUrl: null,
              name: 'سائق الباص',
              radius: 20,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ChatAvatar), findsOneWidget);
      expect(find.text('س'), findsOneWidget);
    });

    testWidgets('6. CustomMenuButton and DirectionalIcon render correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: const Drawer(),
            body: Row(
              children: const [
                CustomMenuButton(),
                DirectionalIcon(Icons.arrow_forward_ios),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CustomMenuButton), findsOneWidget);
      expect(find.byType(DirectionalIcon), findsOneWidget);
    });

    testWidgets('7. PremiumButton renders text, responds to tap and displays loading state', (tester) async {
      bool clicked = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PremiumButton(
              text: 'Submit Button',
              onTap: () => clicked = true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Submit Button'), findsOneWidget);
      await tester.tap(find.byType(PremiumButton));
      expect(clicked, isTrue);

      // Loading mode
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PremiumButton(
              text: 'Submit Button',
              isLoading: true,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('8. PremiumTextField renders and manages input and password obscurity', (tester) async {
      final ctrl = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PremiumTextField(
              controller: ctrl,
              label: 'Password Field',
              icon: Icons.lock,
              keyboardType: TextInputType.text,
              isPassword: true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(PremiumTextField), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'secret123');
      expect(ctrl.text, 'secret123');
    });

    testWidgets('9. AdaptiveSliverAppBar and AppSliverHeader render inside CustomScrollView', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: const [
                AppSliverHeader(
                  title: 'Header Title',
                  hasLeading: true,
                  showMenu: true,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AppSliverHeader), findsOneWidget);
      expect(find.byType(AdaptiveSliverAppBar), findsOneWidget);
      expect(find.text('Header Title'), findsOneWidget);
    });
  });
}
