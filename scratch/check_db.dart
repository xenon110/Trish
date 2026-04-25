import 'package:supabase_flutter/supabase_flutter.dart';
import 'lib/core/supabase_config.dart';
import 'package:flutter/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  
  final client = Supabase.instance.client;
  try {
    print('Fetching likes...');
    final likes = await client.from('likes').select();
    print('Likes: $likes');
    
    print('Fetching matches...');
    final matches = await client.from('matches').select();
    print('Matches: $matches');
    
    print('Testing query...');
    final query = await client.from('matches').select('*, user1:profiles!user1_id(*), user2:profiles!user2_id(*)');
    print('Query success: $query');
  } catch (e) {
    print('Error: $e');
  }
}
