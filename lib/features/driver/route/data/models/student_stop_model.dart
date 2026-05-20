import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/student_stop.dart';

class StudentStopModel extends StudentStop {
  const StudentStopModel({
    required super.id,
    required super.nameAr,
    required super.nameEn,
    required super.parentAr,
    required super.parentEn,
    required super.location,
    super.photoUrl,
    super.parentUserId,
    super.isAbsent = false,
    super.isBoarded = false,
    super.isDroppedOff = false,
    super.isWaiting = false,
    super.waitingSince,
    super.waitingElapsedSeconds = 0,
  });

  factory StudentStopModel.fromJson(Map<String, dynamic> json) {
    return StudentStopModel(
      id: json['id'] as String,
      nameAr: json['nameAr'] as String,
      nameEn: json['nameEn'] as String,
      parentAr: json['parentAr'] as String,
      parentEn: json['parentEn'] as String,
      location: LatLng(
        double.tryParse(json['location']?['lat']?.toString() ?? '0.0') ?? 0.0,
        double.tryParse(json['location']?['lng']?.toString() ?? '0.0') ?? 0.0,
      ),
      photoUrl: json['photoUrl'] as String?,
      parentUserId: json['parentUserId']?.toString(),
      isAbsent: json['isAbsent'] as bool? ?? false,
      isBoarded: json['isBoarded'] as bool? ?? false,
      isDroppedOff: json['isDroppedOff'] as bool? ?? false,
      isWaiting: json['isWaiting'] as bool? ?? false,
      waitingSince: json['waitingSince'] as String?,
      waitingElapsedSeconds: json['waitingElapsedSeconds'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'parentAr': parentAr,
      'parentEn': parentEn,
      'location': {'lat': location.latitude, 'lng': location.longitude},
      'photoUrl': photoUrl,
      'parentUserId': parentUserId,
      'isAbsent': isAbsent,
      'isBoarded': isBoarded,
      'isDroppedOff': isDroppedOff,
      'isWaiting': isWaiting,
      'waitingSince': waitingSince,
      'waitingElapsedSeconds': waitingElapsedSeconds,
    };
  }
}
