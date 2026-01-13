// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'مسارات واصل للخدمات';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get themeTitle => 'المظهر';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get darkModeOn => 'مفعل';

  @override
  String get darkModeOff => 'معطل';

  @override
  String get languageTitle => 'اللغة';

  @override
  String get languageName => 'العربية';

  @override
  String get accountTitle => 'الحساب';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get logoutSubtitle => 'تسجيل الخروج من الحساب الحالي';

  @override
  String get aboutTitle => 'عن التطبيق';

  @override
  String get welcome => 'مرحباً،';

  @override
  String get greetingMorning => 'صباح الخير! يوم موفق لك';

  @override
  String get greetingAfternoon => 'مساء الخير! إستمر بالعطاء';

  @override
  String get greetingEvening => 'مساء النور! يوم جميل';

  @override
  String get quickActions => 'إجراءات سريعة';

  @override
  String get myStudents => 'طلابي';

  @override
  String get scanAttendance => 'مسح الحضور';

  @override
  String get attendanceHistory => 'سجل الحضور';

  @override
  String get reports => 'التقارير';

  @override
  String get comingSoon => 'قريباً...';

  @override
  String get studentCount => 'عدد الطلاب';

  @override
  String get presentToday => 'حاضرون اليوم';

  @override
  String get absentToday => 'غائبون اليوم';

  @override
  String get user => 'المستخدم';

  @override
  String get home => 'الرئيسية';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get settings => 'الإعدادات';

  @override
  String get totalStudents => 'الطلاب';

  @override
  String get averageAttendance => 'متوسط الحضور';

  @override
  String get studentsList => 'قائمة الطلاب';

  @override
  String get noStudentsFound => 'لا يوجد طلاب يطابقون البحث';

  @override
  String get searchPlaceholder => 'البحث باسم الطالب أو الرقم...';

  @override
  String get all => 'الكل';

  @override
  String get atHome => 'في المنزل';

  @override
  String get onBus => 'في الحافلة';

  @override
  String get atSchool => 'في المدرسة';

  @override
  String get absent => 'غائب';

  @override
  String get tripProgress => 'تقدم الرحلة';

  @override
  String deliveredStudentsCount(int atSchool, int total) {
    return 'تم توصيل $atSchool من $total طلاب';
  }

  @override
  String get remaining => 'المتبقي';

  @override
  String get percentage => 'النسبة';

  @override
  String get boardedBus => 'ركب الحافلة';

  @override
  String get reachedSchool => 'وصل المدرسة';

  @override
  String get arrivedSafely => 'وصل بالسلامة';

  @override
  String guardianLabel(String name) {
    return 'ولي الأمر: $name';
  }

  @override
  String get dailyChecklistTitle => 'قائمة المهام اليومية';

  @override
  String get tasksSavedSuccessfully => 'تم حفظ المهام بنجاح';

  @override
  String get confirmAndSendReport => 'تأكيد وإرسال التقرير';

  @override
  String get checklistTask1 => 'التأكد من ربط أحزمة الأمان لجميع الطلاب';

  @override
  String get checklistTask2 => 'مراجعة نظافة الحافلة قبل وبعد الرحلة';

  @override
  String get checklistTask3 => 'التأكد من خلو الحافلة من الطلاب تماماً';

  @override
  String get checklistTask4 => 'فحص حقائب الطلاب المنسية';

  @override
  String get checklistTask5 => 'التأكد من تشغيل نظام التكييف/التهوية';

  @override
  String get incidentReportTitle => 'بلاغ عن حادث';

  @override
  String get incidentType => 'نوع البلاغ';

  @override
  String get problemDescription => 'وصف المشكلة';

  @override
  String get reportDetailsPlaceholder => 'اكتب تفاصيل البلاغ هنا...';

  @override
  String get attachPhotoOptional => 'إرفاق صورة (اختياري)';

  @override
  String get reportSentSuccessfully => 'تم إرسال البلاغ للإدارة فوراً';

  @override
  String get sendUrgentReport => 'إرسال البلاغ العاجل';

  @override
  String get incidentTypeBehavioral => 'سلوكي';

  @override
  String get incidentTypeHealth => 'صحي';

  @override
  String get incidentTypeTechnical => 'عطل فني';

  @override
  String get incidentTypeTraffic => 'حادث مروري';

  @override
  String get incidentTypeOther => 'آخر';

  @override
  String get reportsTitle => 'التقارير والإحصائيات';

  @override
  String get dailyAverageAttendance => 'متوسط الحضور اليومي';

  @override
  String get absenceRate => 'نسبة الغياب';

  @override
  String get lateRate => 'نسبة التأخير';

  @override
  String get attendanceTrend => 'اتجاه الحضور';

  @override
  String get insights => 'رؤى وتحليلات';

  @override
  String insightPerfectAttendance(String className) {
    return 'فصل $className لديه حضور مثالي اليوم!';
  }

  @override
  String insightLowAttendance(int percentage) {
    return 'انخفاض بنسبة الحضور بنسبة $percentage% مقارنة بالأمس';
  }

  @override
  String get attendanceToday => 'حضور اليوم';

  @override
  String get absenceToday => 'غياب اليوم';

  @override
  String get weeklyAttendanceTrend => 'اتجاه الحضور الأسبوعي';

  @override
  String get smartInsight => 'رؤية ذكية';

  @override
  String get excellentAttendanceInsight =>
      'أداء الحضور ممتاز هذا الأسبوع! استمر في تحفيز الطلاب.';

  @override
  String get lowAttendanceInsight =>
      'هناك انخفاض طفيف في الحضور. قد ترغب في مراجعة الأسباب.';
}
