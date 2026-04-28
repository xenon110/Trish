import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';

class ChatMatch {
  final String id;
  final UserProfile otherUser;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final bool isUnlocked;
  final bool isBlind;
  final bool currentUserUnlocked;
  final bool otherUserUnlocked;
  final int unreadCount;

  ChatMatch({
    required this.id,
    required this.otherUser,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
    this.isUnlocked = false,
    this.isBlind = false,
    this.currentUserUnlocked = false,
    this.otherUserUnlocked = false,
    this.unreadCount = 0,
  });

  /// True when no message has ever been sent in this match.
  bool get hasNoMessages => lastMessage == null || lastMessage!.isEmpty;
}

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  /// Fetches all matches for the current user including the other user's
  /// profile and the latest message preview from the messages table.
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

      final matchesList = (matchesResponse as List).where((m) {
        // Safety: Filter out any self-matches (where both IDs are the same user)
        return m['user1_id'] != m['user2_id'];
      }).toList();
      
      if (matchesList.isEmpty) return [];

      // 2. Collect match IDs and other-user IDs in one pass
      final List<String> matchIds = [];
      final List<String> otherUserIds = [];
      for (var match in matchesList) {
        final isUser1 = match['user1_id'] == userId;
        final targetId = isUser1 ? match['user2_id'] : match['user1_id'];
        
        // Final sanity check: targetId must NOT be the current user
        if (targetId != userId) {
          matchIds.add(match['id'] as String);
          otherUserIds.add(targetId);
        }
      }

      // 3. Fetch all other-user profiles in one query
      final profilesResponse = await _supabase
          .from('profiles')
          .select()
          .inFilter('id', otherUserIds);
      final profilesList = profilesResponse as List;

      // 4. Fetch latest message + unread count per match from the messages table
      final Map<String, String?> lastMessageContent = {};
      final Map<String, DateTime?> lastMessageTime = {};
      final Map<String, int> unreadCounts = {};

      try {
        final msgsResponse = await _supabase
            .from('messages')
            .select('match_id, content, created_at, sender_id, is_read')
            .inFilter('match_id', matchIds)
            .order('created_at', ascending: false);

        for (final msg in msgsResponse as List) {
          final mid = msg['match_id'] as String;
          // First occurrence = latest message for this match
          if (!lastMessageContent.containsKey(mid)) {
            lastMessageContent[mid] = msg['content'] as String?;
            lastMessageTime[mid] =
                DateTime.tryParse(msg['created_at'] as String? ?? '')?.toLocal();
          }
          // Count messages sent by the other user that are NOT read yet
          if (msg['sender_id'] != userId && msg['is_read'] == false) {
            unreadCounts[mid] = (unreadCounts[mid] ?? 0) + 1;
          }
        }
      } catch (_) {
        // messages table may not exist in older DB setups – degrade gracefully
      }

      // 5. Build ChatMatch objects
      final result = matchesList.map((matchJson) {
        final matchId = matchJson['id'] as String;
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
          id: matchId,
          otherUser: profileJson != null
              ? UserProfile.fromJson(profileJson)
              : UserProfile.fromJson(
                  {'id': targetId, 'full_name': 'Unknown User'}),
          createdAt: DateTime.parse(matchJson['created_at']).toLocal(),
          lastMessage: lastMessageContent[matchId],
          lastMessageAt: lastMessageTime[matchId],
          isUnlocked: matchJson['is_unlocked'] == true,
          isBlind: matchJson['is_blind'] == true,
          currentUserUnlocked: isUser1
              ? matchJson['user1_unlocked'] == true
              : matchJson['user2_unlocked'] == true,
          otherUserUnlocked: isUser1
              ? matchJson['user2_unlocked'] == true
              : matchJson['user1_unlocked'] == true,
          unreadCount: unreadCounts[matchId] ?? 0,
        );
      }).toList();

      // Sort: conversations with recent messages first, then by match date
      result.sort((a, b) {
        final aTime = a.lastMessageAt ?? a.createdAt;
        final bTime = b.lastMessageAt ?? b.createdAt;
        return bTime.compareTo(aTime);
      });

      return result;
    } catch (e) {
      print('Error fetching matches in ChatService: $e');
      rethrow;
    }
  }
  
  /// Returns a real-time stream of all matches for the current user.
  /// This will emit a new list whenever a match is added or updated.
  Stream<List<ChatMatch>> getMatchesStream() {
    final userId = _currentUserId;
    if (userId == null) return Stream.value([]);

    return _supabase
        .from('matches')
        .stream(primaryKey: ['id'])
        .asyncMap((_) => getMatches());
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

  /// Marks all messages in a match as read for the current user.
  Future<void> markMessagesAsRead(String matchId) async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('match_id', matchId)
          .neq('sender_id', userId)
          .eq('is_read', false);
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }
}
