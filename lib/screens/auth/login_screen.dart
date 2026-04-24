import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/custom_button.dart';
import 'signup_screen.dart';
import 'verify_email_screen.dart';
import '../../core/ui_helpers.dart';
import '../../core/auth_service.dart';
import '../home/main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Check verification status
      await _authService.reloadUser();
      final user = _authService.currentUser;

      if (mounted) {
        if (user?.emailConfirmedAt == null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => VerifyEmailScreen(email: _emailController.text.trim()),
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google login failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryMaroon),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'TRISH',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppTheme.primaryMaroon,
                      letterSpacing: 2,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome back. Let\'s find your match.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textLight,
                    ),
              ),
              const SizedBox(height: 48),
              _buildInputContainer(
                context,
                label: 'Email or Phone',
                hint: 'Enter your email or phone',
                icon: Icons.email_outlined,
                controller: _emailController,
              ),
              const SizedBox(height: 24),
              _buildInputContainer(
                context,
                label: 'Password',
                hint: 'Enter your password',
                icon: Icons.lock_outline,
                isPassword: true,
                controller: _passwordController,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => UIHelpers.showFeatureComingSoon(context),
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(color: AppTheme.primaryMaroon),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: _isLoading ? 'Logging in...' : 'Login',
                onPressed: _isLoading ? () {} : _login,
              ),
              const SizedBox(height: 32),
              _buildDivider(),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Continue with Google',
                isSecondary: true,
                onPressed: _isLoading ? () {} : _loginWithGoogle,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Continue with Apple',
                isSecondary: true,
                onPressed: () => UIHelpers.showFeatureComingSoon(context),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Don\'t have an account? ', style: TextStyle(color: AppTheme.textDark)),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const SignupScreen()),
                      );
                    },
                    child: Text(
                      'Sign up',
                      style: TextStyle(
                        color: AppTheme.primaryMaroon,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputContainer(BuildContext context, {required String label, required String hint, required IconData icon, bool isPassword = false, required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(28),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppTheme.textLight),
              prefixIcon: Icon(icon, color: AppTheme.primaryMaroon.withOpacity(0.5)),
              suffixIcon: isPassword ? Icon(Icons.remove_red_eye, color: AppTheme.textDark) : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('OR', style: TextStyle(color: AppTheme.textLight)),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300)),
      ],
    );
  }
}
