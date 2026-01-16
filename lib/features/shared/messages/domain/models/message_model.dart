/// Simple data model for chat messages.
class MessageModel {
  const MessageModel({
    required this.id,
    required this.text,
    required this.sender,
    required this.time,
    required this.incoming,
    this.mediaUrl,
  });

  final String id;
  final String text;
  final String sender;
  final DateTime time;
  final bool incoming; // true = received, false = sent by user
  final String? mediaUrl;

  MessageModel copyWith({
    String? id,
    String? text,
    String? sender,
    DateTime? time,
    bool? incoming,
    String? mediaUrl,
  }) {
    return MessageModel(
      id: id ?? this.id,
      text: text ?? this.text,
      sender: sender ?? this.sender,
      time: time ?? this.time,
      incoming: incoming ?? this.incoming,
      mediaUrl: mediaUrl ?? this.mediaUrl,
    );
  }
}
