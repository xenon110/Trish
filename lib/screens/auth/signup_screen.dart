import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/custom_button.dart';
import 'otp_screen.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  String _selectedGoal = 'Meaningful connection';
  String _selectedMatter = 'Kindness';
  bool _hasGenuineIntent = false;

  final List<String> _goals = [
    'Meaningful connection',
    'Casual',
    'Exploring',
  ];

  final List<String> _matters = [
    'Kindness',
    'Ambition',
    'Shared values',
  ];

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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildLogoSection(),
              const SizedBox(height: 40),
              _buildInputFields(),
              const SizedBox(height: 32),
              _buildGoalSelection(),
              const SizedBox(height: 32),
              _buildPersonalityStarter(),
              const SizedBox(height: 32),
              _buildConsentCheckbox(),
              const SizedBox(height: 40),
              CustomButton(
                text: 'Continue',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const OtpScreen()),
                  );
                },
              ),
              const SizedBox(height: 24),
              _buildLoginLink(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        Text(
          'TRISH',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: AppTheme.primaryMaroon,
                letterSpacing: 2,
                fontSize: 40,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Start something real.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textLight,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  Widget _buildInputFields() {
    return Column(
      children: [
        _buildTextField(label: 'Name', hint: 'Your full name', icon: Icons.person_outline),
        const SizedBox(height: 20),
        _buildTextField(label: 'Phone or Email', hint: 'Enter your phone or email', icon: Icons.email_outlined),
        const SizedBox(height: 20),
        _buildTextField(label: 'Password', hint: 'Create a password', icon: Icons.lock_outline, isPassword: true),
      ],
    );
  }

  Widget _buildTextField({required String label, required String hint, required IconData icon, bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            obscureText: isPassword,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppTheme.textLight, fontSize: 14),
              prefixIcon: Icon(icon, color: AppTheme.primaryMaroon.withOpacity(0.6)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What are you here for?',
          style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _goals.map((goal) => _buildChoiceChip(goal, _selectedGoal == goal, (selected) {
            setState(() { _selectedGoal = goal; });
          })).toList(),
        ),
      ],
    );
  }

  Widget _buildPersonalityStarter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What matters more to you?',
          style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _matters.map((matter) => _buildChoiceChip(matter, _selectedMatter == matter, (selected) {
            setState(() { _selectedMatter = matter; });
          })).toList(),
        ),
      ],
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, Function(bool) onSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: AppTheme.primaryMaroon.withOpacity(0.15),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryMaroon : AppTheme.textDark,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryMaroon : Colors.transparent,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      pressElevation: 0,
      shadowColor: Colors.black.withOpacity(0.1),
    );
  }

  Widget _buildConsentCheckbox() {
    return Row(
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: _hasGenuineIntent,
            onChanged: (val) {
              setState(() { _hasGenuineIntent = val ?? false; });
            },
            activeColor: AppTheme.primaryMaroon,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'I’m here with genuine intent.',
            style: TextStyle(color: AppTheme.textDark, fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Already have an account? ', style: TextStyle(color: AppTheme.textDark, fontSize: 15)),
        GestureDetector(
          onTap: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
          child: const Text(
            'Login',
            style: TextStyle(
              color: AppTheme.primaryMaroon,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}
