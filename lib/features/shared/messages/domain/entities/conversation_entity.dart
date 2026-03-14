import 'package:equatable/equatable.dart';

class ConversationEntity extends Equatable {
  final String id;
  final String parentName;
  final String studentName;
  final String lastMessage;
  final DateTime lastMessageTime;
  int unreadCount;
  final String? avatarUrl;

  ConversationEntity({
    required this.id,
    required this.parentName,
    required this.studentName,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [
    id,
    parentName,
    studentName,
    lastMessage,
    lastMessageTime,
    unreadCount,
    avatarUrl,
  ];
}
