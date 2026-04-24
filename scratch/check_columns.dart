
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://evhdrxenapbcgueuvupy.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV2aGRyeGVuYXBiY2d1ZXV2dXB5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY4MzExNzksImV4cCI6MjA5MjQwNzE3OX0.T-bvAnH5SKBHRZD5OGOvTHTVog2Bk317RvA70OyxEfs',
  );

  try {
    final response = await supabase.from('profiles').select().limit(1).single();
    print('Columns in profiles: ${response.keys.toList()}');
  } catch (e) {
    print('Error checking columns: $e');
  }
}
