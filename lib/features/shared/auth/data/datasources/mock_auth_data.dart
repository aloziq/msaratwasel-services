import '../../domain/entities/user_entity.dart';

/// Mock authentication data for development
final Map<UserRole, String> kMockRoleToId = {
  UserRole.teacher: '1',
  UserRole.assistant: '2',
  UserRole.driver: '3',
  UserRole.fieldSupervisor: '4',
};

final Map<UserRole, String> kMockAvatars = {
  UserRole.teacher: 'https://i.pravatar.cc/300?img=5',
  UserRole.assistant: 'https://i.pravatar.cc/300?img=12',
  UserRole.driver: 'https://i.pravatar.cc/300?img=11',
  UserRole.fieldSupervisor: 'https://i.pravatar.cc/300?img=3',
};

const String kMockPassword = '123456';
