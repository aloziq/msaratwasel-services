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
  String get dailyChecklist => 'القائمة اليومية';

  @override
  String get busTracking => 'تتبع الحافلة';

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

  @override
  String get editProfile => 'تعديل البيانات الشخصية';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get changeChildrenLocation => 'تغيير موقع الابناء';

  @override
  String get manageKids => 'إدارة الطلاب المسجلين';

  @override
  String get locationChangeWarningTitle => 'تنبيه هام';

  @override
  String get locationChangeWarningBody =>
      'يرجى العلم بأنه في حال تغيير الموقع، يجب إبلاغ المدرسة قبل 48 ساعة من موعد التغيير لضمان ترتيبات النقل.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get proceed => 'متابعة';

  @override
  String get appearance => 'المظهر';

  @override
  String get activitiesSubtitle => 'آخر إعلانات وتحديثات المدرسة.';

  @override
  String get helpCenter => 'مركز المساعدة';

  @override
  String get contactUs => 'تواصل معنا';

  @override
  String get aboutApp => 'عن التطبيق';

  @override
  String get canteen => 'المقصف';

  @override
  String get support => 'الدعم';

  @override
  String get appName => 'مسارات واصل';

  @override
  String get version => 'الإصدار';

  @override
  String get aboutAppDescription =>
      'تطبيق مسارات واصل هو الحل الأمثل لإدارة النقل المدرسي بفعالية وأمان. يتيح لأولياء الأمور متابعة أبنائهم وتلقي الإشعارات اللحظية، مما يضمن راحة البال وسلامة الطلاب.';

  @override
  String get aboutCompanyTitle => 'عن شركة واصل';

  @override
  String get aboutCompany =>
      'شركة واصل للنقل المدرسي هي شركة رائدة في مجال خدمات النقل، تسعى لتقديم تجربة نقل آمنة ومريحة للطلاب مع توظيف أحدث التقنيات لضمان الجودة والموثوقية.';

  @override
  String get developedBy => 'تم التطوير بواسطة';

  @override
  String get contactMethods => 'طرق التواصل';

  @override
  String get phoneNumber => 'رقم الجوال';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get website => 'الموقع الإلكتروني';

  @override
  String get socialMedia => 'حسابات التواصل';

  @override
  String get complaintsBox => 'صندوق الشكاوى والمقترحات';

  @override
  String get complaintMessageHint => 'اكتب نص الاقتراح أو الشكوى هنا...';

  @override
  String get submit => 'إرسال';

  @override
  String get complaintSent => 'تم إرسال رسالتك بنجاح';

  @override
  String get currentPassword => 'كلمة المرور الحالية';

  @override
  String get fieldRequired => 'مطلوب';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get passwordLengthError => 'يجب أن لا تقل عن 6 خانات';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور الجديدة';

  @override
  String get passwordMismatch => 'كلمات المرور غير متطابقة';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get passwordUpdatedSuccess => 'تم تغيير كلمة المرور بنجاح';

  @override
  String get privacyPolicy => 'السياسة والخصوصية';

  @override
  String get privacyIntroTitle => 'أولًا: المقدمة';

  @override
  String get privacyIntroBody1 =>
      'هذه الوثيقة تمثل اتفاقًا قانونيًا بين مستخدمي التطبيق (ولي الأمر، الطالب، السائق، المشرفة، المعلم، المشرف الميداني، المدرسة) وبين إدارة التطبيق.';

  @override
  String get privacyIntroBody2 =>
      'باستخدام التطبيق، يقر جميع المستخدمين بموافقتهم على هذه السياسة والالتزام بها.';

  @override
  String get privacyDataCollectionTitle => 'ثانيًا: جمع البيانات';

  @override
  String get privacyStudentDataTitle => 'بيانات الطالب:';

  @override
  String get privacyStudentData1 => 'الاسم الكامل';

  @override
  String get privacyStudentData2 => 'الرقم المدرسي';

  @override
  String get privacyStudentData3 => 'الرقم المدني';

  @override
  String get privacyStudentData4 => 'صورة الطالب';

  @override
  String get privacyStudentData5 => 'صورة المنزل';

  @override
  String get privacyStudentData6 => 'الموقع الجغرافي للحافلة';

  @override
  String get privacyStudentData7 => 'سجل الحضور والانصراف عبر الباركود';

  @override
  String get privacyOtherDataTitle => 'بيانات أخرى:';

  @override
  String get privacyOtherData1 =>
      'بيانات ولي الأمر: الاسم، رقم الهاتف، البريد الإلكتروني، رقم الهوية المدنية.';

  @override
  String get privacyOtherData2 =>
      'بيانات السائق والمشرفين والمعلمين: الاسم، رقم الهوية/الوظيفة، بيانات الاتصال.';

  @override
  String get privacyOtherData3 =>
      'بيانات تقنية: سجل الدخول، استخدام الباركود، الموقع الجغرافي للحافلة.';

  @override
  String get privacyDataUsageTitle => 'ثالثًا: استخدام البيانات';

  @override
  String get privacyDataUsage1 => 'ضمان سلامة الطالب أثناء النقل المدرسي.';

  @override
  String get privacyDataUsage2 => 'تمكين ولي الأمر من متابعة حالة الطالب.';

  @override
  String get privacyDataUsage3 => 'إدارة عمليات النقل المدرسي بكفاءة.';

  @override
  String get privacyDataUsage4 => 'إصدار تقارير للمدرسة والمشرفين.';

  @override
  String get privacyDataUsage5 =>
      'لا تُستخدم البيانات لأي أغراض تجارية أو دعائية.';

  @override
  String get privacyDataProtectionTitle => 'رابعًا: حماية البيانات';

  @override
  String get privacyDataProtection1 =>
      'تخزين البيانات في خوادم آمنة باستخدام تقنيات التشفير.';

  @override
  String get privacyDataProtection2 =>
      'تقييد الوصول للبيانات حسب صلاحيات المستخدم.';

  @override
  String get privacyDataProtection3 => 'مراجعة دورية لإجراءات الأمان.';

  @override
  String get privacyDataProtection4 =>
      'عدم مشاركة البيانات مع أطراف ثالثة إلا بموافقة المدرسة أو وفق القانون.';

  @override
  String get privacyUserRightsTitle => 'خامسًا: حقوق المستخدمين';

  @override
  String get privacyUserRights1 => 'الحق في الاطلاع على بياناتهم.';

  @override
  String get privacyUserRights2 => 'الحق في طلب تصحيح أو حذف بيانات غير دقيقة.';

  @override
  String get privacyUserRights3 =>
      'الحق في الاعتراض على استخدام بياناتهم لأغراض غير تعليمية.';

  @override
  String get privacyUserObligationsTitle => 'سادسًا: التزامات المستخدمين';

  @override
  String get privacyUserObligations1 =>
      'استخدام التطبيق فقط للأغراض التعليمية والنقل المدرسي.';

  @override
  String get privacyUserObligations2 =>
      'عدم مشاركة بيانات الدخول مع أطراف أخرى.';

  @override
  String get privacyUserObligations3 =>
      'الالتزام بالقوانين المحلية المتعلقة بحماية البيانات.';

  @override
  String get privacyLegalLiabilityTitle => 'سابعًا: المسؤولية القانونية';

  @override
  String get privacyLegalLiability1 =>
      'التطبيق غير مسؤول عن أي استخدام غير مصرح به من قبل المستخدمين.';

  @override
  String get privacyLegalLiability2 =>
      'المدرسة تتحمل مسؤولية إدارة صلاحيات المستخدمين.';

  @override
  String get privacyLegalLiability3 =>
      'أي خرق أمني سيتم التعامل معه وفق القوانين المحلية (بما في ذلك المرسوم السلطاني رقم 6/2022 بشأن حماية البيانات الشخصية في سلطنة عمان).';

  @override
  String get privacyAmendmentsTitle => 'ثامنًا: التعديلات';

  @override
  String get privacyAmendments1 =>
      'تحتفظ إدارة التطبيق بحق تعديل هذه السياسة بما يتوافق مع القوانين والتطورات التقنية.';

  @override
  String get privacyAmendments2 => 'سيتم إخطار المستخدمين بأي تغييرات جوهرية.';

  @override
  String get privacyConsentTitle => 'تاسعًا: الموافقة';

  @override
  String get privacyConsentBody =>
      'باستخدام التطبيق، يوافق جميع المستخدمين على هذه السياسة ويلتزمون بها.';

  @override
  String get privacySimplifiedTitle => '📱 نسخة مبسطة للمستخدمين';

  @override
  String get privacyQ1 => 'لماذا نجمع البيانات؟';

  @override
  String get privacyA1 =>
      '- لضمان سلامة الطالب أثناء الرحلة.\n- لمساعدة ولي الأمر على متابعة وصول وخروج الطالب.\n- لتسهيل عمل السائق والمشرفة والمعلم والمشرف الميداني.';

  @override
  String get privacyQ2 => 'ما هي البيانات التي نستخدمها؟';

  @override
  String get privacyA2 =>
      '- اسم الطالب ورقمه المدرسي.\n- الرقم المدني وصورة الطالب للتأكد من الهوية.\n- صورة المنزل والموقع الجغرافي للحافلة.\n- سجل حضور وانصراف الطالب عبر الباركود.\n- بيانات ولي الأمر للتواصل.\n- بيانات السائق والمشرفين والمعلمين.';

  @override
  String get privacyQ3 => 'كيف نحمي بياناتك؟';

  @override
  String get privacyA3 =>
      '- نخزن المعلومات في أنظمة آمنة ومشفرة.\n- لا نشارك بياناتك مع أي طرف خارجي إلا بموافقة المدرسة أو إذا طلب القانون ذلك.\n- نحدد صلاحيات الدخول بحيث يرى كل مستخدم فقط ما يحتاجه لعمله.';

  @override
  String get privacyQ4 => 'حقوقك';

  @override
  String get privacyA4 =>
      '- يمكنك الاطلاع على بياناتك.\n- يمكنك طلب تعديل أو حذف بيانات غير صحيحة.\n- بياناتك لن تُستخدم لأي أغراض تجارية أو دعائية.';

  @override
  String get privacyQ5 => 'التزاماتك';

  @override
  String get privacyA5 =>
      '- استخدام التطبيق للنقل المدرسي فقط.\n- عدم مشاركة حسابك أو بيانات الدخول مع آخرين.\n- الالتزام بالقوانين المحلية بخصوص حماية البيانات.';

  @override
  String get application => 'التطبيق';

  @override
  String get light => 'فاتح';

  @override
  String get dark => 'داكن';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get chats => 'المحادثات';
}
