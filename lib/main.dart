import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme.dart';
import 'screens/onboarding/splash_screen.dart';
import 'core/supabase_config.dart';

import 'screens/auth/update_password_screen.dart';
import 'core/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const TrishApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class TrishApp extends StatefulWidget {
  const TrishApp({super.key});

  @override
  State<TrishApp> createState() => _TrishAppState();
}

class _TrishAppState extends State<TrishApp> {
  @override
  void initState() {
    super.initState();
    
    // 1. Listen for auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      _handleAuthEvent(data.event);
    });

    // 2. Check initial session in case the event was already fired
    _checkInitialSession();
  }

  void _checkInitialSession() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      // If we have a session and it's a recovery flow, navigate.
      // Note: Supabase doesn't easily show "recovery" on the session, 
      // but the event usually fires. We'll rely on the event mostly.
    }
  }

  void _handleAuthEvent(AuthChangeEvent event) {
    debugPrint('Auth Event: $event');
    if (event == AuthChangeEvent.passwordRecovery) {
      AuthService.isRecoveryMode = true;
      debugPrint('Password recovery detected, navigating...');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const UpdatePasswordScreen()),
            (route) => false,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'TRISH Dating App',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
