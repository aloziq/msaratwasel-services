import '../../domain/entities/user_entity.dart';

/// Mock authentication data for development
final Map<UserRole, String> kMockRoleToId = {
  UserRole.teacher: '1',
  UserRole.busAssistant: '2',
  UserRole.driver: '3',
  UserRole.fieldSupervisor: '4',
};

const String kMockPassword = '123456';
