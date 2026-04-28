import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class DiscoveryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  /// Fetches profiles using the Smart Recommendation Engine.
  Future<List<UserProfile>> getDiscoveryProfiles() async {
    final userId = _currentUserId;
    if (userId == null) return [];

    try {
      // Update last active status only if user hasn't disabled it in settings
      final metadata = _supabase.auth.currentUser?.userMetadata;
      final showOnline = metadata?['pref_show_online'] ?? true;
      
      if (showOnline) {
        await _supabase.from('profiles').update({
          'last_active_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', userId);
      }

      // Fetch discovery filters from user metadata
      final filters = _supabase.auth.currentUser?.userMetadata?['discovery_filters'] ?? {};

      // Call the SQL Recommendation Engine with filters
      final response = await _supabase.rpc(
        'get_recommended_feed',
        params: {
          'current_user_uuid': userId,
          'limit_count': 20,
          'filters_json': filters,
        },
      );

      return (response as List).map((item) {
        return UserProfile.fromJson(item['profile_json'] as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Error fetching smart feed: $e');
      
      // 1. Fetch active matches first to ensure they are excluded
      final matchesRes = await _supabase.from('matches')
          .select('user1_id, user2_id')
          .or('user1_id.eq.$userId,user2_id.eq.$userId');
      
      final matchedIds = (matchesRes as List).map((m) => 
        m['user1_id'] == userId ? m['user2_id'] : m['user1_id']
      ).toList();

      // 2. Build the list of IDs to exclude (Self + All Matches)
      final List<String> excludeIds = [userId, ...matchedIds.cast<String>()];
      
      // 3. Fetch profiles and EXCLUDE them strictly
      var query = _supabase.from('profiles').select();
      if (excludeIds.isNotEmpty) {
        query = query.not('id', 'in', '(${excludeIds.join(",")})');
      }

      final fallbackResponse = await query.limit(20);
      return (fallbackResponse as List).map((json) => UserProfile.fromJson(json)).toList();
    }
  }

  /// Fetches profiles specifically matched for Blind Mode (personality first).
  Future<List<UserProfile>> getBlindDiscoveryProfiles() async {
    final userId = _currentUserId;
    if (userId == null) return [];

    try {
      final response = await _supabase.rpc(
        'get_blind_matches',
        params: {
          'current_user_uuid': userId,
          'limit_count': 10,
        },
      );

      return (response as List).map((item) {
        return UserProfile.fromJson(item['profile_json'] as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Error fetching blind matches: $e');
      // Fallback: Just return some regular profiles if the RPC isn't set up yet
      final fallbackResponse = await _supabase.from('profiles').select().neq('id', userId).limit(10);
      return (fallbackResponse as List).map((json) => UserProfile.fromJson(json)).toList();
    }
  }

  /// Records a swipe (like or pass) and checks for a match.
  /// Returns the match ID if a match was created.
  Future<String?> swipe(String targetId, bool isLike) async {
    final userId = _currentUserId;
    if (userId == null || targetId == userId) return null;

    if (isLike) {
      // 1. Record the like
      await _supabase.from('likes').upsert({
        'liker_id': userId,
        'liked_id': targetId,
      });

      // 2. Check if the target user has already liked the current user
      final checkLikeResponse = await _supabase
          .from('likes')
          .select()
          .eq('liker_id', targetId)
          .eq('liked_id', userId)
          .maybeSingle();

      if (checkLikeResponse != null) {
        // It's a match!
        return await _createMatch(userId, targetId);
      }
    } else {
      // Record a dislike/pass with cooldown tracking
      try {
        final existingDislike = await _supabase
            .from('dislikes')
            .select('dislike_count')
            .eq('user_id', userId)
            .eq('target_id', targetId)
            .maybeSingle();

        final int newCount = (existingDislike?['dislike_count'] ?? 0) + 1;

        await _supabase.from('dislikes').upsert({
          'user_id': userId,
          'target_id': targetId,
          'dislike_count': newCount,
          'last_disliked_at': DateTime.now().toUtc().toIso8601String(),
        });
        
        await _supabase.from('likes').delete()
            .eq('liker_id', userId)
            .eq('liked_id', targetId);
      } catch (e) {
        print('Error recording dislike: $e');
      }
    }

    return null;
  }

  Future<String?> _createMatch(String user1Id, String user2Id) async {
    // Sort IDs to ensure uniqueness in the matches table
    final ids = [user1Id, user2Id]..sort();
    
    final response = await _supabase.from('matches').upsert({
      'user1_id': ids[0],
      'user2_id': ids[1],
      'is_unlocked': true,
      'is_blind': false,
    }, onConflict: 'user1_id,user2_id').select('id').single();

    return response['id'] as String?;
  }
}
