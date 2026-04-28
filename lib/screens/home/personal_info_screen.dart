import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/auth_service.dart';
import '../../core/ui_helpers.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final AuthService _authService = AuthService();
  bool _isResettingPassword = false;

  String get _userEmail {
    return _authService.currentUser?.email ?? 'Not provided';
  }

  String get _userPhone {
    return _authService.currentUser?.userMetadata?['phone_number'] ?? 'Not provided';
  }

  Future<void> _handlePasswordReset() async {
    final email = _authService.currentUser?.email;
    if (email == null || email.isEmpty) {
      UIHelpers.showSnackBar(context, 'No email associated with this account.');
      return;
    }

    setState(() => _isResettingPassword = true);

    try {
      await _authService.resetPassword(email);
      if (mounted) {
        UIHelpers.showSnackBar(context, 'Password reset email sent to $email');
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showSnackBar(context, 'Error sending reset email: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isResettingPassword = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFAFA),
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Info',
              style: TextStyle(
                color: Color(0xFF2C2C2E),
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'These details are private and will not be displayed on your public profile.',
              style: TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 40),
            
            _buildInfoCard(
              title: 'Email Address',
              value: _userEmail,
              icon: Icons.email_rounded,
            ),
            const SizedBox(height: 20),
            
            _buildInfoCard(
              title: 'Phone Number',
              value: _userPhone,
              icon: Icons.phone_rounded,
            ),
            const SizedBox(height: 48),

            const Text(
              'Security',
              style: TextStyle(
                color: Color(0xFF2C2C2E),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildSecurityAction(
              title: 'Reset Password',
              subtitle: 'We will send a reset link to your email.',
              icon: Icons.lock_reset_rounded,
              isLoading: _isResettingPassword,
              onTap: _handlePasswordReset,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFF7F7F8),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF8E8E93), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF2C2C2E),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 20),
        ],
      ),
    );
  }

  Widget _buildSecurityAction({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryMaroon.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFFDECEC),
                shape: BoxShape.circle,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF9D4C5E)),
                    )
                  : Icon(icon, color: const Color(0xFF9D4C5E), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF2C2C2E),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF9D4C5E), size: 16),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Color(0xFFF2F2F7), shape: BoxShape.circle),
          child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF7D4249), size: 16),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}
