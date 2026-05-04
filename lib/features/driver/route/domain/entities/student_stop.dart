import 'package:google_maps_flutter/google_maps_flutter.dart';

class StudentStop {
  final String id;
  final String nameAr;
  final String nameEn;
  final String parentAr;
  final String parentEn;
  final LatLng location;
  final String? photoUrl;
  final String? parentUserId;
  final bool isAbsent;
  final bool isBoarded;
  final bool isDroppedOff;

  const StudentStop({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.parentAr,
    required this.parentEn,
    required this.location,
    this.photoUrl,
    this.parentUserId,
    this.isAbsent = false,
    this.isBoarded = false,
    this.isDroppedOff = false,
  });

  StudentStop copyWith({bool? isAbsent, bool? isBoarded, bool? isDroppedOff}) {
    return StudentStop(
      id: id,
      nameAr: nameAr,
      nameEn: nameEn,
      parentAr: parentAr,
      parentEn: parentEn,
      location: location,
      photoUrl: photoUrl,
      isAbsent: isAbsent ?? this.isAbsent,
      isBoarded: isBoarded ?? this.isBoarded,
      isDroppedOff: isDroppedOff ?? this.isDroppedOff,
    );
  }
}
