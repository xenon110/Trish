import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'onboarding_screen.dart';
import '../../core/auth_service.dart';
import '../home/main_navigation_screen.dart';
import '../auth/verify_email_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       duration: const Duration(seconds: 2),
       vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Navigate based on auth session and verification status
    _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final user = _authService.currentUser;
    
    if (user == null) {
      // User not logged in
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    } else {
      // User is logged in, check verification
      await _authService.reloadUser();
      final freshUser = _authService.currentUser;

      if (freshUser?.emailConfirmedAt == null) {
        // User logged in but email not verified
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => VerifyEmailScreen(email: freshUser?.email ?? ''),
          ),
        );
      } else {
        // Logged in and verified
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFDECEB), Color(0xFFF7D9CE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(flex: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDF0ED),
                                borderRadius: BorderRadius.circular(50),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryMaroon.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Text(
                                'TRISH',
                                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                      color: AppTheme.primaryMaroon,
                                      letterSpacing: -1,
                                      fontSize: 48,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Container(
                              width: 40,
                              height: 3,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryMaroon.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(1.5),
                              ),
                            ),
                            const Spacer(flex: 4),
                            Text(
                              'Build Real Connections',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.primaryMaroon.withOpacity(0.8),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(height: 28),
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMaroon),
                              strokeWidth: 2,
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
