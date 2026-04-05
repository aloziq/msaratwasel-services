import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/repositories/reports_repository.dart';
import '../datasources/reports_remote_datasource.dart';

@LazySingleton(as: ReportsRepository)
class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsRemoteDataSource remoteDataSource;

  ReportsRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<String, AttendanceStatsEntity>> getAttendanceStats() async {
    try {
      final stats = await remoteDataSource.getAttendanceStats();
      return Right(stats);
    } catch (e, stackTrace) {
      debugPrint('ReportsRepository.getAttendanceStats failed: $e');
      debugPrint('Stack trace: $stackTrace');
      
      String debugMsg = 'فشل تحميل بيانات التقارير\n';
      if (e.toString().contains('DioException')) {
        debugMsg += 'تفاصيل الاتصال بالسيرفر: $e';
      } else {
        debugMsg += 'خطأ في معالجة البيانات: $e';
      }
      return Left(debugMsg);
    }
  }
}
