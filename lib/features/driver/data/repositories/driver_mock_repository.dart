import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/driver_entities.dart';
import 'package:msaratwasel_services/features/driver/domain/repositories/driver_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: DriverRepository)
class DriverMockRepository implements DriverRepository {
  // Mock Data
  final List<StudentStop> _mockStops = [
    const StudentStop(
      id: '1',
      nameAr: 'أحمد سعيد',
      nameEn: 'Ahmed Saeed',
      parentAr: 'سعيد العلوي',
      parentEn: 'Saeed Al-Alawi',
      location: LatLng(23.6000, 58.3500), // Stop 1: Azaiba North
      photoUrl:
          'https://images.unsplash.com/photo-1599566150163-29194dcaad36?w=200',
    ),
    const StudentStop(
      id: '2',
      nameAr: 'سارة محمد',
      nameEn: 'Sara Mohammed',
      parentAr: 'محمد الكندي',
      parentEn: 'Mohammed Al-Kindi',
      location: LatLng(23.5900, 58.4000), // Stop 2: Al Ghubra
      isAbsent: true,
      photoUrl:
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200',
    ),
    const StudentStop(
      id: '3',
      nameAr: 'عمر خالد',
      nameEn: 'Omar Khaled',
      parentAr: 'خالد المعولي',
      parentEn: 'Khaled Al-Maawali',
      location: LatLng(23.6000, 58.4300), // Stop 3: Al Khuwair 33
      photoUrl:
          'https://images.unsplash.com/photo-1566492031773-4f4e44671857?w=200',
    ),
    const StudentStop(
      id: '4',
      nameAr: 'ليلى البلوشي',
      nameEn: 'Layla Al-Balushi',
      parentAr: 'ياسر البلوشي',
      parentEn: 'Yasser Al-Balushi',
      location: LatLng(23.6080, 58.4500), // Stop 4: MSQ
      photoUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
    ),
  ];

  @override
  Future<TripStatus> getCurrentTripStatus() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network
    return const TripStatus(
      id: 'trip_123',
      departureTime: '06:30 AM',
      totalStudents: 22,
      isStarted: false,
    );
  }

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
      const LatLng(23.6230, 58.2630), // Roundabout
      // 2. 18th November Street (Main Highway - Eastbound)
      const LatLng(23.6190, 58.2690),
      const LatLng(23.6170, 58.2750),
      const LatLng(23.6150, 58.2850),
      const LatLng(23.6130, 58.2950),
      const LatLng(23.6110, 58.3050),
      const LatLng(23.6090, 58.3150),
      const LatLng(23.6070, 58.3250),
      const LatLng(23.6050, 58.3350),

      // 3. Turn into Azaiba North (Smooth Curve)
      const LatLng(23.6042, 58.3410),
      const LatLng(23.6035, 58.3430),
      const LatLng(23.6030, 58.3450),
      const LatLng(23.6015, 58.3470),
      const LatLng(23.6000, 58.3500), // Stop 1: Azaiba North
      // ... and so on (keeping it brief for this file, but you can copy the full list if needed)
      // For now, let's just make a simple direct line to the other stops for the mock
      const LatLng(23.5900, 58.4000), // Stop 2
      const LatLng(23.6000, 58.4300), // Stop 3
      const LatLng(23.6080, 58.4500), // Stop 4
    ];
  }

  @override
  Future<void> startTrip(String tripId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // In a real app, we'd update backend state
  }

  @override
  Future<void> updateStudentStatus(
    String studentId, {
    bool? isAbsent,
    bool? isBoarded,
    bool? isDroppedOff,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Find stop and update locally if needed for simulation
  }

  @override
  Future<void> endTrip(String tripId) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<void> submitFuelRefill({
    required double amount,
    required int odometer,
    required DateTime date,
    String? photoPath,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<void> submitMaintenanceRequest({
    required String description,
    required DateTime date,
    double? cost,
    String? photoPath,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
  }
}
