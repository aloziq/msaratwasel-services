import '../../domain/entities/message_entity.dart';

class MessageModel extends MessageEntity {
  const MessageModel({
    required super.id,
    required super.text,
    required super.sender,
    required super.time,
    required super.incoming,
    super.mediaUrl,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      text: json['text'] as String,
      sender: json['sender'] as String,
      time: DateTime.parse(json['time'] as String),
      incoming: json['incoming'] as bool? ?? false,
      mediaUrl: json['mediaUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'sender': sender,
      'time': time.toIso8601String(),
      'incoming': incoming,
      'mediaUrl': mediaUrl,
    };
  }
}
