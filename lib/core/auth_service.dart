import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user session
  Session? get currentSession => _supabase.auth.currentSession;
  
  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

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
    await _supabase.auth.resetPasswordForEmail(email);
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
      'updated_at': DateTime.now().toIso8601String(),
      'full_name': metadata['full_name'],
      'avatar_url': metadata['avatar_url'],
      'bio': metadata['bio'],
      'location': metadata['location'],
      'latitude': metadata['latitude'],
      'longitude': metadata['longitude'],
      'gender': metadata['gender'],
      'hobby': metadata['hobby'],
      'interests': metadata['interests'],
    };

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

  // Fetch all public profiles
  Future<List<UserProfile>> getProfiles() async {
    final response = await _supabase
        .from('profiles')
        .select()
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
}
