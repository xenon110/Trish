import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/custom_button.dart';
import '../home/dashboard_screen.dart';
import '../home/main_navigation_screen.dart';
import '../../core/ui_helpers.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryMaroon),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24.0),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8FC),
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF8F8FC), Color(0xFFFDF0EC)],
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.lock_person_outlined, color: AppTheme.primaryMaroon, size: 28),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Check your\nmessages',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                color: AppTheme.textDark,
                                height: 1.1,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'We\'ve sent a 4-digit code to\nyour device. Please enter it\nbelow to verify your identity.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppTheme.textLight,
                                height: 1.5,
                              ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(4, (index) => _buildOtpField()),
                        ),
                        const SizedBox(height: 32),
                        CustomButton(
                          text: 'Verify',
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        Text('Didn\'t receive the code?', style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            UIHelpers.showSnackBar(context, 'OTP has been resent to your device.');
                          },
                          child: const Text(
                            'Resend OTP',
                            style: TextStyle(
                              color: AppTheme.primaryMaroon,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOtpField() {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        color: Color(0xFFEBEBEB),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          '0',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD4D4D4),
          ),
        ),
      ),
    );
  }
}
