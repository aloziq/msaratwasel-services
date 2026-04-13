import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/network/api_client.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/messages_repository.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../../domain/entities/contact_entity.dart';

@LazySingleton(as: MessagesRepository)
class MessagesRepositoryImpl implements MessagesRepository {
  final Dio _dio;
  
  MessagesRepositoryImpl() : _dio = ApiClient.instance;

  // Add a getter to ensure we always have the latest instance if needed, 
  // but for now, the single instance should work if it's configured once.

  @override
  Future<List<ConversationEntity>> getConversations() async {
    try {
      final response = await _dio.get('/chat/conversations');
      final List<dynamic> data = response.data['data'] ?? [];
      
      return data.map((json) {
        // Find the other participant's name and avatar
        final List<dynamic> participants = json['participants'] ?? [];
        String parentName = 'ولي أمر';
        String? avatarUrl;
        if (participants.isNotEmpty) {
          parentName = participants.first['name'] ?? 'ولي أمر';
          avatarUrl  = participants.first['avatar'];
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
          avatarUrl: avatarUrl,
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

  @override
  Future<List<ContactEntity>> getContacts() async {
    try {
      final response = await _dio.get('/chat/contacts');
      final List<dynamic> data = response.data['data'] ?? [];
      
      return data.map((json) {
        return ContactEntity(
          id: json['id'].toString(),
          name: json['name'] ?? 'مستخدم',
          description: json['chat_description'] ?? '',
          avatarUrl: json['avatar'],
        );
      }).toList();
    } catch (e) {
      throw Exception('فشل جلب جهات الاتصال');
    }
  }

  @override
  Future<ConversationEntity> startConversation(String receiverId) async {
    try {
      final response = await _dio.post('/chat/conversations', data: {
        'receiver_id': receiverId,
      });
      final json = response.data['data'];
      
      final List<dynamic> participants = json['participants'] ?? [];
      String parentName = 'مستخدم';
      if (participants.isNotEmpty) {
        // find someone who is not me
        final other = participants.firstWhere(
          (p) => true, // ideally check id != myId but backend usually puts receiver first or we just take first
          orElse: () => {'name': 'مستخدم'}
        );
        parentName = other['name'] ?? 'مستخدم';
      }

      return ConversationModel(
        id: json['id'].toString(),
        parentName: parentName,
        studentName: 'الطالب',
        lastMessage: 'بدء محادثة',
        lastMessageTime: DateTime.now(),
        unreadCount: 0,
        avatarUrl: null,
      );
    } catch (e) {
      throw Exception('فشل بدء المحادثة');
    }
  }

  @override
  Future<void> markAsRead(String conversationId) async {
    try {
      await _dio.post('/chat/conversations/$conversationId/read');
    } catch (e) {
      // Non-critical, just log
      print('⚠️ markAsRead failed: $e');
    }
  }
}
