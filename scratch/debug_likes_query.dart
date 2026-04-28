
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://evhdrxenapbcgueuvupy.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV2aDRyeGVuYXBiY2d1ZXV2dXB5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY4MzExNzksImV4cCI6MjA5MjQwNzE3OX0.T-bvAnH5SKBHRZD5OGOvTHTVog2Bk317RvA70OyxEfs',
  );

  try {
    // Current query in AuthService
    print('Testing current query...');
    final res1 = await supabase
        .from('likes')
        .select('liker_id, created_at, profiles!likes_liker_id_fkey(id, full_name)')
        .limit(5);
    print('Current query result: $res1');
  } catch (e) {
    print('Current query failed: $e');
  }

  try {
    // Alternative 1: using column name as hint
    print('\nTesting Alternative 1 (hint = liker_id)...');
    final res2 = await supabase
        .from('likes')
        .select('liker_id, created_at, profiles!liker_id(id, full_name)')
        .limit(5);
    print('Alternative 1 result: $res2');
  } catch (e) {
    print('Alternative 1 failed: $e');
  }

  try {
    // Alternative 2: explicit join if possible
    print('\nTesting Alternative 2 (no hint)...');
    final res3 = await supabase
        .from('likes')
        .select('liker_id, created_at, profiles(id, full_name)')
        .limit(5);
    print('Alternative 2 result: $res3');
  } catch (e) {
    print('Alternative 2 failed: $e');
  }
}
