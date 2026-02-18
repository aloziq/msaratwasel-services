import 'package:injectable/injectable.dart';
import '../../domain/entities/fleet_bus.dart';

abstract class FleetRemoteDataSource {
  Future<List<FleetBus>> getFleetBuses();
}

@LazySingleton(as: FleetRemoteDataSource)
class MockFleetRemoteDataSourceImpl implements FleetRemoteDataSource {
  @override
  Future<List<FleetBus>> getFleetBuses() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final now = DateTime.now();
    return [
      FleetBus(
        id: 'B001',
        name: 'حافلة 1',
        driverName: 'محمد أحمد',
        supervisorName: 'فاطمة الحارثي',
        schoolName: 'مدرسة النور',
        driverPhone: '96812345678',
        route: 'المعبيلة → المطار',
        lat: 23.5880,
        lng: 58.3829,
        speedKmh: 45,
        studentsOnBoard: 18,
        status: FleetBusStatus.active,
        updatedAt: now.subtract(const Duration(minutes: 1)),
      ),
      FleetBus(
        id: 'B002',
        name: 'حافلة 2',
        driverName: 'علي سالم',
        supervisorName: 'مريم البلوشي',
        schoolName: 'مدرسة الأمل',
        driverPhone: '96887654321',
        route: 'القرم → الخوض',
        lat: 23.6100,
        lng: 58.4050,
        speedKmh: 0,
        studentsOnBoard: 12,
        status: FleetBusStatus.stopped,
        updatedAt: now.subtract(const Duration(minutes: 5)),
      ),
      FleetBus(
        id: 'B003',
        name: 'حافلة 3',
        driverName: 'خالد ناصر',
        supervisorName: 'عائشة الراشدي',
        schoolName: 'مدرسة السلام',
        driverPhone: '96899887766',
        route: 'بوشر → السيب',
        lat: 23.5750,
        lng: 58.4200,
        speedKmh: 38,
        studentsOnBoard: 22,
        status: FleetBusStatus.active,
        updatedAt: now.subtract(const Duration(minutes: 2)),
      ),
      FleetBus(
        id: 'B004',
        name: 'حافلة 4',
        driverName: 'سعيد حمد',
        supervisorName: 'نورة الكندي',
        schoolName: 'مدرسة العلم',
        driverPhone: '96811223344',
        route: 'الموالح → العامرات',
        lat: 23.5500,
        lng: 58.3500,
        speedKmh: 0,
        studentsOnBoard: 0,
        status: FleetBusStatus.maintenance,
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      FleetBus(
        id: 'B005',
        name: 'حافلة 5',
        driverName: 'ياسر عبدالله',
        supervisorName: 'سميرة المعمري',
        schoolName: 'مدرسة المعرفة',
        driverPhone: '96855667788',
        route: 'الأنصب → المعبيلة',
        lat: 23.6000,
        lng: 58.3600,
        speedKmh: 52,
        studentsOnBoard: 15,
        status: FleetBusStatus.active,
        updatedAt: now.subtract(const Duration(seconds: 30)),
      ),
    ];
  }
}
