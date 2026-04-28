
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class MatchingService {
  final _supabase = Supabase.instance.client;

  // 1. Send a Like
  Future<String?> sendLike(String targetUserId) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null || targetUserId == currentUser.id) return null;

    try {
      // Use liker_id and liked_id to match Supabase schema
      await _supabase.from('likes').upsert({
        'liker_id': currentUser.id,
        'liked_id': targetUserId,
      });
      
      // Check if it's a match immediately
      return await _checkForMatch(targetUserId);
    } catch (e) {
      print('Error sending like: $e');
      return null;
    }
  }

  // 2. Check if the other person already liked us
  Future<String?> _checkForMatch(String targetUserId) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return null;

    try {
      // Check if they liked us (we are now the liked_id)
      final response = await _supabase
          .from('likes')
          .select()
          .eq('liker_id', targetUserId)
          .eq('liked_id', currentUser.id)
          .maybeSingle();

      if (response != null) {
        // It's a match! Create/Return the match ID
        return await _createMatch(targetUserId);
      }
      return null;
    } catch (e) {
      print('Error checking for match: $e');
      return null;
    }
  }

  // 3. Create a Match (or get existing if trigger already created it)
  Future<String?> _createMatch(String targetUserId) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return null;

    // Ensure user1_id is always the smaller UUID for the UNIQUE index
    final ids = [currentUser.id, targetUserId]..sort();

    try {
      // Try to get the match first (in case trigger already created it)
      final existing = await _supabase
          .from('matches')
          .select('id')
          .eq('user1_id', ids[0])
          .eq('user2_id', ids[1])
          .maybeSingle();
      
      if (existing != null) return existing['id'] as String;

      // Otherwise upsert
      final response = await _supabase.from('matches').upsert({
        'user1_id': ids[0],
        'user2_id': ids[1],
        'is_unlocked': true, // Standard matches are unlocked
        'is_blind': false,
      }, onConflict: 'user1_id,user2_id').select('id').single();
      
      return response['id'] as String;
    } catch (e) {
      print('Error creating match: $e');
      return null;
    }
  }

  // 4. Get all Matched Profiles
  Future<List<UserProfile>> getMatches() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return [];

    try {
      final response = await _supabase
          .from('matches')
          .select('user1_id, user2_id')
          .or('user1_id.eq.${currentUser.id},user2_id.eq.${currentUser.id}');

      final matchIds = (response as List).map((match) {
        return match['user1_id'] == currentUser.id 
            ? match['user2_id'] as String 
            : match['user1_id'] as String;
      }).toList();

      if (matchIds.isEmpty) return [];

      // Fetch profile details for these IDs
      final profilesResponse = await _supabase
          .from('profiles')
          .select()
          .inFilter('id', matchIds);

      return (profilesResponse as List)
          .map((json) => UserProfile.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching matches: $e');
      return [];
    }
  }
}
