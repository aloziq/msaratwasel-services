import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/network/api_client.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/messages_repository.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

@LazySingleton(as: MessagesRepository)
class MessagesRepositoryImpl implements MessagesRepository {
  final Dio _dio;

  MessagesRepositoryImpl() : _dio = ApiClient.instance;

  @override
  Future<List<ConversationEntity>> getConversations() async {
    try {
      final response = await _dio.get('/chat/conversations');
      final List<dynamic> data = response.data['data'] ?? [];
      
      return data.map((json) {
        // Find the other participant's name
        final List<dynamic> participants = json['participants'] ?? [];
        String parentName = 'ولي أمر';
        if (participants.isNotEmpty) {
          parentName = participants.first['name'] ?? 'ولي أمر';
        }

        final lastMessageObj = json['last_message'];
        
        return ConversationModel(
          id: json['id'].toString(),
          parentName: parentName,
          studentName: 'الطالب', // API doesn't return student name directly here yet
          lastMessage: lastMessageObj != null ? lastMessageObj['body'] : 'بدء محادثة',
          lastMessageTime: lastMessageObj != null 
              ? DateTime.parse(lastMessageObj['created_at'])
              : DateTime.parse(json['updated_at']),
          unreadCount: json['unread_count'] ?? 0,
          avatarUrl: 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(parentName)}&background=random',
        );
      }).toList();
    } catch (e) {
      throw Exception('فشل جلب المحادثات: ${e.toString()}');
    }
  }

  @override
  Future<List<MessageEntity>> getMessages(String conversationId) async {
    try {
      final response = await _dio.get('/chat/conversations/$conversationId/messages');
      final List<dynamic> data = response.data['data'] ?? [];
      
      return data.map((json) {
        final senderObj = json['sender'];
        
        return MessageModel(
          id: json['id'].toString(),
          text: json['body'] ?? '',
          sender: senderObj != null ? senderObj['name'] : 'System',
          time: DateTime.parse(json['created_at']),
          incoming: !(json['is_mine'] == true),
          mediaUrl: json['attachment_url'],
        );
      }).toList();
    } catch (e) {
      throw Exception('فشل جلب الرسائل');
    }
  }

  @override
  Future<void> sendMessage(String conversationId, String text) async {
    try {
      await _dio.post('/chat/conversations/$conversationId/messages', data: {
        'body': text,
        'type': 'text',
      });
    } catch (e) {
      throw Exception('فشل إرسال الرسالة');
    }
  }
}
