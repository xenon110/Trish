class ChatMessage {
  final String id;
  final String matchId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final bool isMe;

  ChatMessage({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.isMe,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, String currentUserId) {
    return ChatMessage(
      id: json['id'],
      matchId: json['match_id'],
      senderId: json['sender_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      isMe: json['sender_id'] == currentUserId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'match_id': matchId,
      'sender_id': senderId,
      'content': content,
    };
  }
}
