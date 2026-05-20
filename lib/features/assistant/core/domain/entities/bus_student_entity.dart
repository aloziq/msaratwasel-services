import 'package:equatable/equatable.dart';

enum BusStudentStatus {
  atHome,
  onBus,
  atSchool,
  absent,
  waiting,
  unknown;

  String get labelAr {
    switch (this) {
      case BusStudentStatus.atHome:
        return 'في المنزل';
      case BusStudentStatus.onBus:
        return 'في الحافلة';
      case BusStudentStatus.atSchool:
        return 'في المدرسة';
      case BusStudentStatus.absent:
        return 'غائب';
      case BusStudentStatus.waiting:
        return 'انتظار';
      case BusStudentStatus.unknown:
        return 'غير محدد';
    }
  }
}

class BusStudentEntity extends Equatable {
  final String id;
  final String studentCode;
  final String name;
  final String? nameEn;
  final String grade;
  final String schoolId;
  final String parentName;
  final String parentPhone;
  final String? parentUserId;
  final String? photoUrl;
  final BusStudentStatus status;
  final String? behavioralNote;
  final DateTime? waitingSince;
  final int waitingElapsedSeconds;

  const BusStudentEntity({
    required this.id,
    required this.studentCode,
    required this.name,
    this.nameEn,
    required this.grade,
    required this.schoolId,
    required this.parentName,
    required this.parentPhone,
    this.parentUserId,
    this.photoUrl,
    this.status = BusStudentStatus.unknown,
    this.behavioralNote,
    this.waitingSince,
    this.waitingElapsedSeconds = 0,
  });

  String getLocalizedName(String languageCode) {
    if (languageCode.toLowerCase() == 'en') {
      return (nameEn != null && nameEn!.trim().isNotEmpty) ? nameEn! : name;
    }
    return name;
  }

  String getLocalizedGrade(String languageCode) {
    if (languageCode.toLowerCase() == 'en') {
      final input = grade.trim();
      if (input.isEmpty || input == 'غير محدد') {
        return 'Not Specified';
      }

      // Check for exact matches of simple stages
      switch (input) {
        case 'حضانة':
        case 'الحضانة':
        case 'حضانه':
          return 'Nursery';
        case 'روضة':
        case 'الروضة':
          return 'Kindergarten';
        case 'تمهيدي':
        case 'التمهيدي':
          return 'Preschool';
        case 'ابتدائي':
        case 'الابتدائي':
        case 'الابتدائية':
          return 'Primary';
        case 'متوسط':
        case 'المتوسط':
        case 'المتوسطة':
          return 'Intermediate';
        case 'ثانوي':
        case 'الثانوي':
        case 'الثانوية':
          return 'Secondary';
      }

      // Normalized version to handle different forms of arabic letters
      String normalized = input
          .replaceAll('أ', 'ا')
          .replaceAll('إ', 'ا')
          .replaceAll('آ', 'ا')
          .replaceAll('ة', 'ه')
          .replaceAll('ى', 'ي');
      
      String ordinal = '';
      if (normalized.contains('اول') || normalized.contains('1')) {
        ordinal = '1st';
      } else if (normalized.contains('ثاني') || normalized.contains('2')) {
        ordinal = '2nd';
      } else if (normalized.contains('ثالث') || normalized.contains('3')) {
        ordinal = '3rd';
      } else if (normalized.contains('رابع') || normalized.contains('4')) {
        ordinal = '4th';
      } else if (normalized.contains('خامس') || normalized.contains('5')) {
        ordinal = '5th';
      } else if (normalized.contains('سادس') || normalized.contains('6')) {
        ordinal = '6th';
      }

      String stage = '';
      if (normalized.contains('حضانه') || normalized.contains('حضانة')) {
        stage = 'Nursery';
      } else if (normalized.contains('روضه') || normalized.contains('روضة')) {
        stage = 'Kindergarten';
      } else if (normalized.contains('تمهيدي')) {
        stage = 'Preschool';
      } else if (normalized.contains('ابتدائي') || normalized.contains('ابتدائيه')) {
        stage = 'Primary';
      } else if (normalized.contains('متوسط')) {
        stage = 'Intermediate';
      } else if (normalized.contains('ثانوي') || normalized.contains('ثانويه')) {
        stage = 'Secondary';
      }

      if (ordinal.isNotEmpty && stage.isNotEmpty) {
        return '$ordinal $stage';
      } else if (ordinal.isNotEmpty) {
        return '$ordinal Grade';
      } else if (stage.isNotEmpty) {
        return stage;
      }

      return input;
    }
    return grade;
  }

  BusStudentEntity copyWith({
    String? id,
    String? studentCode,
    String? name,
    String? nameEn,
    String? grade,
    String? schoolId,
    String? parentName,
    String? parentPhone,
    String? parentUserId,
    String? photoUrl,
    BusStudentStatus? status,
    String? behavioralNote,
    DateTime? waitingSince,
    int? waitingElapsedSeconds,
  }) {
    return BusStudentEntity(
      id: id ?? this.id,
      studentCode: studentCode ?? this.studentCode,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      grade: grade ?? this.grade,
      schoolId: schoolId ?? this.schoolId,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      parentUserId: parentUserId ?? this.parentUserId,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      behavioralNote: behavioralNote ?? this.behavioralNote,
      waitingSince: waitingSince ?? this.waitingSince,
      waitingElapsedSeconds: waitingElapsedSeconds ?? this.waitingElapsedSeconds,
    );
  }

  @override
  List<Object?> get props => [
    id,
    studentCode,
    name,
    nameEn,
    grade,
    schoolId,
    parentName,
    parentPhone,
    parentUserId,
    photoUrl,
    status,
    behavioralNote,
    waitingSince,
    waitingElapsedSeconds,
  ];
}
