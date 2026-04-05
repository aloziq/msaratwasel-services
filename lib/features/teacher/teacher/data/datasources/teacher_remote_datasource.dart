import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:msaratwasel_services/core/network/api_client.dart';
import '../models/classroom_model.dart';

abstract class TeacherRemoteDataSource {
  Future<List<ClassroomModel>> getTeacherClassrooms();
}

@LazySingleton(as: TeacherRemoteDataSource)
class TeacherRemoteDataSourceImpl implements TeacherRemoteDataSource {
  @override
  Future<List<ClassroomModel>> getTeacherClassrooms() async {
    try {
      final dio = ApiClient.instance;
      final response = await dio.get('teacher/classes');

      debugPrint('[TeacherRemoteDS] ✅ Classes fetched: ${response.data}');

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => ClassroomModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[TeacherRemoteDS] ❌ Error fetching classes: $e');
      rethrow;
    }
  }
}
