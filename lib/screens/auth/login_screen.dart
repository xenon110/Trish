import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/custom_button.dart';
import 'otp_screen.dart';
import 'signup_screen.dart';
import '../../core/ui_helpers.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
              ),
              const SizedBox(height: 24),
              _buildInputContainer(
                context,
                label: 'Password',
                hint: 'Enter your password',
                icon: Icons.lock_outline,
                isPassword: true,
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
                text: 'Login',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const OtpScreen()),
                  );
                },
              ),
              const SizedBox(height: 32),
              _buildDivider(),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Continue with Google',
                isSecondary: true,
                onPressed: () => UIHelpers.showFeatureComingSoon(context),
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

  Widget _buildInputContainer(BuildContext context, {required String label, required String hint, required IconData icon, bool isPassword = false}) {
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
