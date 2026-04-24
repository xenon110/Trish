import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/custom_button.dart';
import 'login_screen.dart';
import 'verify_email_screen.dart';
import '../../core/auth_service.dart';
import '../home/main_navigation_screen.dart';
import '../../core/ui_helpers.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  
  String _selectedGender = 'Man';
  String _selectedGoal = 'Meaningful connection';
  String _selectedMatter = 'Kindness';
  bool _hasGenuineIntent = false;
  bool _isLoading = false;

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
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim()) ?? 0;

    if (!_hasGenuineIntent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please confirm your genuine intent.')),
      );
      return;
    }

    if (email.isEmpty || password.isEmpty || name.isEmpty || _ageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    if (age < 18) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be 18 or older to use Trish.')),
      );
      return;
    }

    // Basic email validation
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _authService.signUp(
        email: email,
        password: password,
        fullName: name,
        metadata: {
          'goal': _selectedGoal,
          'matter': _selectedMatter,
          'age': age,
          'gender': _selectedGender,
        },
      );

      if (mounted) {
        // Check if user is already confirmed (e.g. if email confirmation is disabled in Supabase)
        if (response.user?.emailConfirmedAt != null) {
          UIHelpers.showSnackBar(context, 'Account created and verified!');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
            (route) => false,
          );
        } else {
          UIHelpers.showSnackBar(context, 'Verification email sent! Please check your inbox.');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => VerifyEmailScreen(email: email),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.contains('429')) {
          errorMsg = 'Too many attempts. Please try again in a few minutes.';
        } else if (errorMsg.contains('Email link is invalid')) {
          errorMsg = 'The verification link has expired. Please try resending.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                text: _isLoading ? 'Creating Account...' : 'Continue',
                onPressed: _isLoading ? () {} : _signUp,
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
        _buildTextField(label: 'Name', hint: 'Your full name', icon: Icons.person_outline, controller: _nameController),
        const SizedBox(height: 20),
        _buildTextField(label: 'Phone or Email', hint: 'Enter your phone or email', icon: Icons.email_outlined, controller: _emailController),
        const SizedBox(height: 20),
        _buildTextField(label: 'Password', hint: 'Create a password', icon: Icons.lock_outline, isPassword: true, controller: _passwordController),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildTextField(label: 'Age', hint: '18+', icon: Icons.calendar_today_outlined, controller: _ageController, keyboardType: TextInputType.number),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: _buildGenderSelection(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
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
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedGender,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryMaroon.withOpacity(0.6)),
              items: ['Man', 'Woman', 'Other'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedGender = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({required String label, required String hint, required IconData icon, bool isPassword = false, required TextEditingController controller, TextInputType keyboardType = TextInputType.text}) {
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
            controller: controller,
            obscureText: isPassword,
            keyboardType: keyboardType,
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
