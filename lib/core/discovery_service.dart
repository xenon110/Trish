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
      // Update last active status first
      await _supabase.from('profiles').update({
        'last_active_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      // Call the SQL Recommendation Engine
      final response = await _supabase.rpc(
        'get_recommended_feed',
        params: {
          'current_user_uuid': userId,
          'limit_count': 20,
        },
      );

      return (response as List).map((item) {
        return UserProfile.fromJson(item['profile_json'] as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Error fetching smart feed: $e');
      // Fallback to basic fetch if RPC fails
      final fallbackResponse = await _supabase.from('profiles').select().limit(20);
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
  /// Returns true if a match was created.
  Future<bool> swipe(String targetId, bool isLike) async {
    final userId = _currentUserId;
    if (userId == null) return false;

    // 1. Record the swipe
    await _supabase.from('likes').upsert({
      'user_id': userId,
      'target_id': targetId,
      'is_like': isLike,
    });

    if (!isLike) return false;

    // 2. Check if the target user has already liked the current user
    final checkLikeResponse = await _supabase
        .from('likes')
        .select()
        .eq('user_id', targetId)
        .eq('target_id', userId)
        .eq('is_like', true)
        .maybeSingle();

    if (checkLikeResponse != null) {
      // It's a match!
      await _createMatch(userId, targetId);
      return true;
    }

    return false;
  }

  Future<void> _createMatch(String user1Id, String user2Id) async {
    // Sort IDs to ensure uniqueness in the matches table
    final ids = [user1Id, user2Id]..sort();
    
    await _supabase.from('matches').upsert({
      'user1_id': ids[0],
      'user2_id': ids[1],
    }, onConflict: 'user1_id,user2_id');
  }
}
