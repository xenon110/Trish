
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://evhdrxenapbcgueuvupy.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV2aGRyeGVuYXBiY2d1ZXV2dXB5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY4MzExNzksImV4cCI6MjA5MjQwNzE3OX0.T-bvAnH5SKBHRZD5OGOvTHTVog2Bk317RvA70OyxEfs', // I'll use the one from check_buckets.dart
  );

  try {
    // 1. Check moments bucket
    final buckets = await supabase.storage.listBuckets();
    final momentsBucket = buckets.firstWhere((b) => b.name == 'moments', orElse: () => throw 'Bucket moments not found');
    print('Bucket "moments" Public: ${momentsBucket.public}');

    // 2. Check public moments in DB
    final res = await supabase
        .from('moments')
        .select('id, user_id, visibility, image_url')
        .eq('visibility', 'public');
    
    print('Found ${res.length} public moments in DB');
    for (var m in res) {
      print(' - ID: ${m['id']}, User: ${m['user_id']}, URL: ${m['image_url']}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
