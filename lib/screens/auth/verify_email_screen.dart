import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/auth_service.dart';
import '../../core/ui_helpers.dart';
import '../home/main_navigation_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  late StreamSubscription<AuthState> _authSubscription;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    
    // 1. Listen for Auth State changes (Fired when deep link opens the app)
    _authSubscription = _authService.authStateChanges.listen((data) {
      if (data.session != null && data.session!.user.emailConfirmedAt != null) {
        _goToHome();
      }
    });

    // 2. Fallback: Periodically reload user status every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkStatusSilently();
    });
  }

  Future<void> _checkStatusSilently() async {
    try {
      await _authService.reloadUser();
      final user = _authService.currentUser;
      if (user?.emailConfirmedAt != null) {
        _goToHome();
      }
    } catch (_) {
      // Ignore errors in silent background check
    }
  }

  void _goToHome() {
    if (mounted) {
      _refreshTimer?.cancel();
      UIHelpers.showSnackBar(context, 'Email Verified! Welcome to TRISH.');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        (route) => false,
      );
    }
  }

  int _resendCountdown = 0;
  Timer? _countdownTimer;

  Future<void> _resendEmail() async {
    if (_resendCountdown > 0) return;

    setState(() => _isLoading = true);
    try {
      await _authService.resendVerificationEmail(widget.email);
      if (mounted) {
        UIHelpers.showSnackBar(context, 'Verification email resent to ${widget.email}');
        setState(() {
          _resendCountdown = 30;
        });
        _startCountdown();
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('429')) {
          UIHelpers.showSnackBar(context, 'Too many requests. Please wait a minute before trying again.');
        } else {
          UIHelpers.showSnackBar(context, 'Error resending email: ${e.toString()}');
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown == 0) {
        timer.cancel();
      } else {
        setState(() {
          _resendCountdown--;
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPeach,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryMaroon),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryMaroon.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMaroon),
                        strokeWidth: 2,
                      ),
                      Icon(Icons.mark_email_unread_outlined, color: AppTheme.primaryMaroon, size: 40),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Waiting for verification...',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppTheme.textDark,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Check your inbox and click the verification link.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textLight),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryMaroon.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.email,
                  style: const TextStyle(
                    color: AppTheme.primaryMaroon,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              const Text(
                'Once you click the link in your email,\nthis page will automatically redirect.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 80),
              TextButton.icon(
                onPressed: _isLoading || _resendCountdown > 0 ? null : _resendEmail,
                icon: Icon(
                  _resendCountdown > 0 ? Icons.timer : Icons.refresh_rounded,
                  color: _resendCountdown > 0 ? Colors.grey : AppTheme.primaryMaroon,
                ),
                label: Text(
                  _resendCountdown > 0 
                    ? 'Wait ${_resendCountdown}s to resend' 
                    : 'Resend verification email',
                  style: TextStyle(
                    color: _resendCountdown > 0 ? Colors.grey : AppTheme.primaryMaroon,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
