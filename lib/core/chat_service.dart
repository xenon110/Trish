import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';

class ChatMatch {
  final String id;
  final UserProfile otherUser;
  final String? lastMessage;
  final DateTime createdAt;
  final bool isUnlocked;
  final bool isBlind;
  final bool currentUserUnlocked;
  final bool otherUserUnlocked;

  ChatMatch({
    required this.id,
    required this.otherUser,
    this.lastMessage,
    required this.createdAt,
    this.isUnlocked = false,
    this.isBlind = false,
    this.currentUserUnlocked = false,
    this.otherUserUnlocked = false,
  });
}

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  /// Fetches all matches for the current user including the other user's profile.
  Future<List<ChatMatch>> getMatches() async {
    final userId = _currentUserId;
    if (userId == null) return [];

    try {
      // 1. Fetch the match rows
      final matchesResponse = await _supabase
          .from('matches')
          .select()
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .order('created_at', ascending: false);

      final matchesList = matchesResponse as List;
      if (matchesList.isEmpty) return [];

      // 2. Extract all the other users' IDs
      final List<String> otherUserIds = [];
      for (var match in matchesList) {
        final isUser1 = match['user1_id'] == userId;
        otherUserIds.add(isUser1 ? match['user2_id'] : match['user1_id']);
      }

      // 3. Fetch all those profiles
      final profilesResponse = await _supabase
          .from('profiles')
          .select()
          .inFilter('id', otherUserIds);

      final profilesList = profilesResponse as List;
      
      // 4. Combine them
      return matchesList.map((matchJson) {
        final isUser1 = matchJson['user1_id'] == userId;
        final targetId = isUser1 ? matchJson['user2_id'] : matchJson['user1_id'];
        
        dynamic profileJson;
        for (var p in profilesList) {
          if (p['id'] == targetId) {
            profileJson = p;
            break;
          }
        }

        return ChatMatch(
          id: matchJson['id'],
          otherUser: profileJson != null ? UserProfile.fromJson(profileJson) : UserProfile.fromJson({'id': targetId, 'full_name': 'Unknown User'}),
          createdAt: DateTime.parse(matchJson['created_at']),
          isUnlocked: matchJson['is_unlocked'] == true,
          isBlind: matchJson['is_blind'] == true,
          currentUserUnlocked: isUser1 ? matchJson['user1_unlocked'] == true : matchJson['user2_unlocked'] == true,
          otherUserUnlocked: isUser1 ? matchJson['user2_unlocked'] == true : matchJson['user1_unlocked'] == true,
        );
      }).toList();
    } catch (e) {
      print('Error fetching matches in ChatService: $e');
      rethrow;
    }
  }

  /// Returns a real-time stream of messages for a specific match.
  Stream<List<ChatMessage>> getMessagesStream(String matchId) {
    final userId = _currentUserId ?? '';
    
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('match_id', matchId)
        .order('created_at', ascending: false)
        .map((data) {
           final msgs = data.map((json) => ChatMessage.fromJson(json, userId)).toList();
           msgs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
           return msgs;
        });
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

  /// Unlocks a blind match. Requires both users to unlock before identities are revealed.
  Future<bool> unlockMatch(String matchId) async {
    final userId = _currentUserId;
    if (userId == null) return false;

    // 1. Fetch the match to see if we are user1 or user2, and what the current status is
    final matchData = await _supabase
        .from('matches')
        .select()
        .eq('id', matchId)
        .single();
    
    final isUser1 = matchData['user1_id'] == userId;
    final otherUnlocked = isUser1 ? matchData['user2_unlocked'] == true : matchData['user1_unlocked'] == true;

    // 2. Update our side
    final Map<String, dynamic> updateData = {
      isUser1 ? 'user1_unlocked' : 'user2_unlocked': true,
    };

    // 3. If the other user already unlocked, officially unlock the whole match!
    if (otherUnlocked) {
      updateData['is_unlocked'] = true;
    }

    await _supabase.from('matches').update(updateData).eq('id', matchId);
    return otherUnlocked;
  }
}
