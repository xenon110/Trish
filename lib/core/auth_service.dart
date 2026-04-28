import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static bool isRecoveryMode = false;

  // Get current user session
  Session? get currentSession => _supabase.auth.currentSession;
  
  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Check if an email already exists in the database
  Future<bool> checkEmailExists(String email) async {
    try {
      final response = await _supabase.rpc(
        'check_email_exists',
        params: {'email_to_check': email.trim().toLowerCase()},
      );
      return response as bool;
    } catch (e) {
      debugPrint('Error checking email exists: $e');
      return false;
    }
  }

  // Sign Up with Email Link Verification
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    Map<String, dynamic>? metadata,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: "io.supabase.trish://login-callback",
      data: {
        'full_name': fullName,
        ...?metadata,
      },
    );
  }

  // Sign In with Email and Password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Reload user data to check verification status
  Future<void> reloadUser() async {
    await _supabase.auth.getUser();
  }

  // Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Reset Password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: "io.supabase.trish://login-callback",
    );
  }

  // Update Password (used after recovery)
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // Resend Verification Email
  Future<void> resendVerificationEmail(String email) async {
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: "io.supabase.trish://login-callback",
      );
    } catch (e) {
      // Re-throw to handle in UI
      rethrow;
    }
  }

  // Sign In with Google (OAuth)
  Future<void> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.trish://login-callback',
    );
  }

  // Stream of Auth Changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Update user profile metadata and public profile table
  Future<void> updateProfile(Map<String, dynamic> metadata) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    // 1. Update Auth Metadata
    await _supabase.auth.updateUser(
      UserAttributes(
        data: metadata,
      ),
    );

    // 2. Sync to Public Profiles table (Only sync fields that exist in the table)
    final profileFields = {
      'id': userId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'full_name': metadata['full_name'],
      'avatar_url': metadata['avatar_url'],
      'bio': metadata['bio'],
      'location': metadata['location'],
      'latitude': metadata['latitude'],
      'longitude': metadata['longitude'],
      'gender': metadata['gender'],
      'hobby': metadata['hobby'],
      'interests': metadata['interests'],
      'birthday': metadata['birthday'],
      'interested_in': metadata['interested_in'],
      'min_age_preference': metadata['min_age_preference'],
      'max_age_preference': metadata['max_age_preference'],
      'distance_preference': metadata['distance_preference'],
      'job': metadata['job'],
      'education': metadata['education'],
      'lifestyle': metadata['lifestyle'],
      'religion': metadata['religion'],
      'relationship_type': metadata['relationship_type'],
      'prompts': metadata['prompts'],
      'social_links': metadata['social_links'],
      'is_verified': metadata['is_verified'],
      'height': metadata['height'],
      'languages': metadata['languages'],
      'zodiac': metadata['zodiac'],
      'future_plans': metadata['future_plans'],
      'phone_number': metadata['phone_number'],
      'pref_private_profile': metadata['pref_private_profile'] ?? false,
      'pref_show_online': metadata['pref_show_online'] ?? true,
      'pref_read_receipts': metadata['pref_read_receipts'] ?? true,
    };

    // Remove null values to avoid overwriting with nulls if partial update
    profileFields.removeWhere((key, value) => value == null);

    // Only add moments if they exist in the metadata
    if (metadata.containsKey('moments')) {
      profileFields['moments'] = metadata['moments'];
    }

    try {
      await _supabase.from('profiles').upsert(profileFields);
    } catch (e) {
      // If moments column is missing, try again without it so it doesn't crash
      if (e.toString().contains('moments')) {
        profileFields.remove('moments');
        await _supabase.from('profiles').upsert(profileFields);
      } else {
        rethrow;
      }
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    await _supabase.rpc('delete_user_account');
    await signOut();
  }

  // Fetch current user's profile
  Future<UserProfile?> getCurrentProfile() async {
    final userId = currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle(); // Use maybeSingle to avoid throwing if not found
      
      if (response == null) return null;
      return UserProfile.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }

  // Fetch all public profiles
  Future<List<UserProfile>> getProfiles() async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('is_blocked', false)
        .neq('id', currentUser?.id ?? ''); // Don't show the current user to themselves
    
    return (response as List).map((json) => UserProfile.fromJson(json)).toList();
  }

  // Upload an image to Supabase Storage
  Future<String> uploadImage(String bucket, String path, Uint8List file) async {
    await _supabase.storage.from(bucket).uploadBinary(
          path,
          file,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
    
    // Get public URL
    return _supabase.storage.from(bucket).getPublicUrl(path);
  }

  // ── Moments (dedicated table) ────────────────────────────────

  /// Upload image & insert a row into the moments table
  Future<Map<String, dynamic>> addMoment({
    required Uint8List bytes,
    required String visibility, // 'personal' | 'public'
    String caption = '',
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw 'Not logged in';

    final fileName = '$userId/moment_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final imageUrl = await uploadImage('moments', fileName, bytes);

    final row = await _supabase.from('moments').insert({
      'user_id': userId,
      'image_url': imageUrl,
      'caption': caption,
      'visibility': visibility,
    }).select().single();

    return row;
  }

  /// Fetch moments for the current user (both personal & public)
  Future<List<Map<String, dynamic>>> getMyMoments() async {
    final userId = currentUser?.id;
    if (userId == null) return [];
    final res = await _supabase
        .from('moments')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  /// Fetch all PUBLIC moments from all users (for the global feed)
  Future<List<Map<String, dynamic>>> getPublicMoments() async {
    final res = await _supabase
        .from('moments')
        .select('*, profiles!moments_user_id_fkey(full_name, avatar_url, location, is_blocked)')
        .eq('visibility', 'public')
        .eq('profiles.is_blocked', false)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  /// Delete a moment by id
  Future<void> deleteMoment(String momentId) async {
    await _supabase.from('moments').delete().eq('id', momentId);
  }

  // ── Likes ────────────────────────────────────────────────────

  /// Returns profiles of users who liked the current user
  Future<List<Map<String, dynamic>>> getLikesReceived() async {
    final userId = currentUser?.id;
    if (userId == null) return [];
    final res = await _supabase
        .from('likes')
        .select('liker_id, created_at, profiles!liker_id(id, full_name, avatar_url, age, location, job, bio, interests, is_blocked)')
        .eq('liked_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  /// Returns count of users who liked the current user
  Future<int> getLikeCount() async {
    final userId = currentUser?.id;
    if (userId == null) return 0;
    final res = await _supabase
        .from('likes')
        .select('id')
        .eq('liked_id', userId);
    return (res as List).length;
  }

  /// Fetch all notifications for the current user
  Future<List<Map<String, dynamic>>> getNotifications() async {
    final userId = currentUser?.id;
    if (userId == null) return [];
    
    final res = await _supabase
        .from('notifications')
        .select('*, profiles:actor_id(full_name, avatar_url)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
        
    return List<Map<String, dynamic>>.from(res);
  }

  /// Mark a notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  /// Get count of unread notifications
  Future<int> getUnreadNotificationCount() async {
    final userId = currentUser?.id;
    if (userId == null) return 0;
    
    final res = await _supabase
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);
        
    return (res as List).length;
  }

  /// Like a user. Returns the match ID if it created/found a mutual match.
  Future<String?> likeUser(String targetId) async {
    final userId = currentUser?.id;
    if (userId == null || userId == targetId) return null;
    
    // 1. Record the like
    await _supabase.from('likes').upsert({
      'liker_id': userId,
      'liked_id': targetId,
    });
    
    // 2. Check if a match now exists between these two specifically
    final ids = [userId, targetId]..sort();
    final matchRes = await _supabase
        .from('matches')
        .select('id')
        .eq('user1_id', ids[0])
        .eq('user2_id', ids[1])
        .maybeSingle();
        
    return matchRes?['id'] as String?;
  }

  /// Remove a like (pass/dislike)
  Future<void> dislikeUser(String targetId) async {
    final userId = currentUser?.id;
    if (userId == null) return;
    await _supabase.from('likes').delete()
        .eq('liker_id', userId)
        .eq('liked_id', targetId);
  }

  /// Check if current user already liked a specific user
  Future<bool> hasLiked(String targetId) async {
    final userId = currentUser?.id;
    if (userId == null) return false;
    final res = await _supabase
        .from('likes')
        .select('id')
        .eq('liker_id', userId)
        .eq('liked_id', targetId);
    return (res as List).isNotEmpty;
  }

  // ── Compatibility ────────────────────────────────────────────

  /// Runs the server-side compatibility check for the current user.
  /// Creates matches with any user scoring >= 50.
  /// Call this on app start / after profile update.
  Future<List<Map<String, dynamic>>> checkCompatibilityMatches() async {
    final userId = currentUser?.id;
    if (userId == null) return [];
    try {
      final res = await _supabase.rpc(
        'check_compatibility_matches',
        params: {'target_uid': userId},
      );
      return List<Map<String, dynamic>>.from(res ?? []);
    } catch (e) {
      debugPrint('checkCompatibilityMatches error: $e');
      return [];
    }
  }

  /// Returns the 0-100 compatibility score between current user and [otherId].
  Future<int> getCompatibilityScore(String otherId) async {
    final userId = currentUser?.id;
    if (userId == null) return 0;
    try {
      final res = await _supabase.rpc(
        'profile_compatibility',
        params: {'uid1': userId, 'uid2': otherId},
      );
      return (res as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Returns true if [currentUser] can chat with [otherId].
  /// Criteria: mutual like OR compatibility >= 50 (i.e. a match row exists).
  Future<bool> canChat(String otherId) async {
    final userId = currentUser?.id;
    if (userId == null) return false;
    final res = await _supabase
        .from('matches')
        .select('id')
        .or('user1_id.eq.$userId,user2_id.eq.$userId')
        .or('user1_id.eq.$otherId,user2_id.eq.$otherId');
    return (res as List).isNotEmpty;
  }
}
