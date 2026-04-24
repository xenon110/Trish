import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';

class ChatMatch {
  final String id;
  final UserProfile otherUser;
  final String? lastMessage;
  final DateTime createdAt;

  ChatMatch({
    required this.id,
    required this.otherUser,
    this.lastMessage,
    required this.createdAt,
  });
}

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  /// Fetches all matches for the current user including the other user's profile.
  Future<List<ChatMatch>> getMatches() async {
    final userId = _currentUserId;
    if (userId == null) return [];

    final response = await _supabase
        .from('matches')
        .select('*, user1:profiles!matches_user1_id_fkey(*), user2:profiles!matches_user2_id_fkey(*)')
        .or('user1_id.eq.$userId,user2_id.eq.$userId')
        .order('created_at', ascending: false);

    return (response as List).map((matchJson) {
      final bool isUser1 = matchJson['user1_id'] == userId;
      final otherUserJson = isUser1 ? matchJson['user2'] : matchJson['user1'];
      
      return ChatMatch(
        id: matchJson['id'],
        otherUser: UserProfile.fromJson(otherUserJson as Map<String, dynamic>?),
        createdAt: DateTime.parse(matchJson['created_at']),
      );
    }).toList();
  }

  /// Returns a real-time stream of messages for a specific match.
  Stream<List<ChatMessage>> getMessagesStream(String matchId) {
    final userId = _currentUserId ?? '';
    
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('match_id', matchId)
        .order('created_at')
        .map((data) => data
            .map((json) => ChatMessage.fromJson(json, userId))
            .toList());
  }

  /// Sends a new message to the match.
  Future<void> sendMessage(String matchId, String content) async {
    final userId = _currentUserId;
    if (userId == null) return;

    await _supabase.from('messages').insert({
      'match_id': matchId,
      'sender_id': userId,
      'content': content,
    });
  }
}
