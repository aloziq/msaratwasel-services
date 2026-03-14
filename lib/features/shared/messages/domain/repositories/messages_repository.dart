import '../entities/conversation_entity.dart';
import '../entities/message_entity.dart';
import '../entities/contact_entity.dart';

abstract class MessagesRepository {
  Future<List<ConversationEntity>> getConversations();
  Future<List<MessageEntity>> getMessages(String conversationId);
  Future<void> sendMessage(String conversationId, String text);
  Future<List<ContactEntity>> getContacts();
  Future<ConversationEntity> startConversation(String receiverId);
  Future<void> markAsRead(String conversationId);
}
