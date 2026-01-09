import '../models/classroom_model.dart';

abstract class TeacherLocalDataSource {
  Future<ClassroomModel> getTeacherClassroom();
  Future<List<ClassroomModel>> getTeacherClassrooms();
}

class TeacherLocalDataSourceImpl implements TeacherLocalDataSource {
  // Mock Data
  final List<ClassroomModel> _classes = [
    const ClassroomModel(
      id: '1',
      name: 'الصف الأول - أ',
      grade: '1',
      studentCount: 25,
    ),
    const ClassroomModel(
      id: '2',
      name: 'الصف الثاني - ب',
      grade: '2',
      studentCount: 22,
    ),
    const ClassroomModel(
      id: '3',
      name: 'الصف الثالث - ج',
      grade: '3',
      studentCount: 28,
    ),
  ];

  @override
  Future<ClassroomModel> getTeacherClassroom() async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate delay
    return _classes.first;
  }

  @override
  Future<List<ClassroomModel>> getTeacherClassrooms() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _classes;
  }
}
