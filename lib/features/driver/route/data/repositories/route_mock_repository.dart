import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/route_repository.dart';
import '../../domain/entities/student_stop.dart';
import '../models/student_stop_model.dart';

@LazySingleton(as: RouteRepository)
class RouteMockRepository implements RouteRepository {
  final List<StudentStop> _mockStops = [
    const StudentStopModel(
      id: '1',
      nameAr: 'أحمد سعيد',
      nameEn: 'Ahmed Saeed',
      parentAr: 'سعيد العلوي',
      parentEn: 'Saeed Al-Alawi',
      location: LatLng(23.6000, 58.3500),
      photoUrl:
          'https://images.unsplash.com/photo-1599566150163-29194dcaad36?w=200',
    ),
    const StudentStopModel(
      id: '2',
      nameAr: 'سارة محمد',
      nameEn: 'Sara Mohammed',
      parentAr: 'محمد الكندي',
      parentEn: 'Mohammed Al-Kindi',
      location: LatLng(23.5900, 58.4000),
      isAbsent: true,
      photoUrl:
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200',
    ),
    const StudentStopModel(
      id: '3',
      nameAr: 'عمر خالد',
      nameEn: 'Omar Khaled',
      parentAr: 'خالد المعولي',
      parentEn: 'Khaled Al-Maawali',
      location: LatLng(23.6000, 58.4300),
      photoUrl:
          'https://images.unsplash.com/photo-1566492031773-4f4e44671857?w=200',
    ),
    const StudentStopModel(
      id: '4',
      nameAr: 'ليلى البلوشي',
      nameEn: 'Layla Al-Balushi',
      parentAr: 'ياسر البلوشي',
      parentEn: 'Yasser Al-Balushi',
      location: LatLng(23.6080, 58.4500),
      photoUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
    ),
  ];

  @override
  Future<List<StudentStop>> getTripStops() async {
    await Future.delayed(const Duration(seconds: 1));
    return List.from(_mockStops);
  }

  @override
  Future<List<LatLng>> getRoutePoints() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      const LatLng(23.6264, 58.2618),
      const LatLng(23.6245, 58.2625),
      const LatLng(23.6230, 58.2630),
      const LatLng(23.6190, 58.2690),
      const LatLng(23.6170, 58.2750),
      const LatLng(23.6150, 58.2850),
      const LatLng(23.6130, 58.2950),
      const LatLng(23.6110, 58.3050),
      const LatLng(23.6090, 58.3150),
      const LatLng(23.6070, 58.3250),
      const LatLng(23.6050, 58.3350),
      const LatLng(23.6042, 58.3410),
      const LatLng(23.6035, 58.3430),
      const LatLng(23.6030, 58.3450),
      const LatLng(23.6015, 58.3470),
      const LatLng(23.6000, 58.3500),
      const LatLng(23.5900, 58.4000),
      const LatLng(23.6000, 58.4300),
      const LatLng(23.6080, 58.4500),
    ];
  }
}
