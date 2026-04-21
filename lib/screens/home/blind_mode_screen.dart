import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/ui_helpers.dart';
import 'package:trish_app/screens/home/main_navigation_screen.dart';

class BlindModeScreen extends StatefulWidget {
  const BlindModeScreen({super.key});

  @override
  State<BlindModeScreen> createState() => _BlindModeScreenState();
}

class _BlindModeScreenState extends State<BlindModeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _orbController;
  String _currentInsight = "Tap to feel the vibe";
  double _connectionProgress = 0.45;
  
  final List<String> _insights = [
    "They love early morning rain 🌧️",
    "Secretly a master of chess ♟️",
    "Prefers vinyl over Spotify 💿",
    "Has a dog named 'Pixel' 🐶",
  ];

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbController.dispose();
    super.dispose();
  }

  void _onOrbTap() {
    setState(() {
      _currentInsight = _insights[math.Random().nextInt(_insights.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFAFA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    _buildVibeSection(),
                    const SizedBox(height: 40),
                    _buildPersonalityTraits(),
                    const SizedBox(height: 48),
                    _buildPromptSection(),
                    const SizedBox(height: 32),
                    _buildConnectionMeter(),
                    const SizedBox(height: 40),
                    _buildUnlockButton(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            _buildChatInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryMaroon),
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      context.findAncestorStateOfType<MainNavigationScreenState>()?.jumpToTab(4);
                    },
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(AppConstants.defaultAvatar1),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const Text(
                    'No faces, just vibes',
                    style: TextStyle(
                      color: Color(0xFF2C2C2E),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 140,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _connectionProgress,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.buttonGradient,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Icon(Icons.notifications, color: AppTheme.primaryMaroon.withOpacity(0.85), size: 28),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVibeSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _onOrbTap,
          child: AnimatedBuilder(
            animation: _orbController,
            builder: (context, child) {
              return Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color.lerp(const Color(0xFFFFB5B5), const Color(0xFFB5C6FF), _orbController.value)!,
                      Color.lerp(const Color(0xFF9D4C5E), const Color(0xFF4C6B9D), _orbController.value)!.withOpacity(0.6),
                      Colors.transparent,
                    ],
                    stops: const [0.2, 0.6, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color.lerp(const Color(0xFF9D4C5E), const Color(0xFF4C6B9D), _orbController.value)!.withOpacity(0.3),
                      blurRadius: 40 * _orbController.value + 20,
                      spreadRadius: 10 * _orbController.value,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF2F2F7)),
          ),
          child: Text(
            _currentInsight,
            style: const TextStyle(
              color: Color(0xFF2C2C2E),
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalityTraits() {
    return Column(
      children: [
        _buildTrait("Obsessive deep-diver into hobbies"),
        const SizedBox(height: 12),
        _buildTrait("Unironically loves bad dad jokes"),
        const SizedBox(height: 12),
        _buildTrait("Can spend hours talking about space"),
      ],
    );
  }

  Widget _buildTrait(String trait) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(color: Color(0xFF9D4C5E), shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Text(
          trait,
          style: const TextStyle(
            color: Color(0xFF6B6B6B),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPromptSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Column(
        children: [
          const Text(
            "If you could travel anywhere tomorrow...?",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF2C2C2E),
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildResponse("Me", "A small cabin in the Swiss Alps, definitely."),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildResponse("Them", "Tokyo! I need that neon energy right now."),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildReaction(context, "Interesting"),
              const SizedBox(width: 8),
              _buildReaction(context, "Relatable"),
              const SizedBox(width: 8),
              _buildReaction(context, "That hit"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResponse(String user, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user,
          style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFF2C2C2E), fontSize: 13, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildReaction(BuildContext context, String label) {
    return InkWell(
      onTap: () => UIHelpers.showSnackBar(context, 'You reacted with: $label'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E5E5)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildConnectionMeter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMeterStage("Curious", _connectionProgress >= 0.2),
            _buildMeterStage("Vibing", _connectionProgress >= 0.6),
            _buildMeterStage("Strong Match", _connectionProgress >= 0.9),
          ],
        ),
      ],
    );
  }

  Widget _buildMeterStage(String label, bool isActive) {
    return Text(
      label,
      style: TextStyle(
        color: isActive ? const Color(0xFF9D4C5E) : const Color(0xFFC7C7CC),
        fontSize: 13,
        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
      ),
    );
  }

  Widget _buildUnlockButton() {
    return InkWell(
      onTap: () => UIHelpers.showFeatureComingSoon(context),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFFE6E6E6),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Center(
          child: Text(
            "Unlock Identity",
            style: TextStyle(color: Color(0xFF8E8E93), fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildChatInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      color: Colors.white,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPromptChip(context, "Tell me a secret 🤫"),
                const SizedBox(width: 8),
                _buildPromptChip(context, "Favorite movie? 🍿"),
                const SizedBox(width: 8),
                _buildPromptChip(context, "Morning or Night? 🦉"),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Color(0xFF8E8E93)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => UIHelpers.showSnackBar(context, 'Message sent successfully!'),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppTheme.buttonGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromptChip(BuildContext context, String text) {
    return InkWell(
      onTap: () => UIHelpers.showSnackBar(context, 'Prompt selected: $text'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Color(0xFF2C2C2E), fontSize: 13),
        ),
      ),
    );
  }
}
