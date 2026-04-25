import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/ui_helpers.dart';
import '../../core/chat_service.dart';
import '../../models/chat_message.dart';
import '../../models/user_profile.dart';
import 'package:flutter/services.dart';
import 'interaction_chat_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/discovery_service.dart';
import 'package:trish_app/screens/home/main_navigation_screen.dart';

class BlindModeScreen extends StatefulWidget {
  final String? matchId;
  final UserProfile? targetProfile;

  const BlindModeScreen({
    super.key,
    this.matchId,
    this.targetProfile,
  });

  @override
  State<BlindModeScreen> createState() => _BlindModeScreenState();
}

class _BlindModeScreenState extends State<BlindModeScreen> with TickerProviderStateMixin {
  late AnimationController _orbController;
  late AnimationController _radarRotationController;
  late AnimationController _radarPulseController;
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  
  String? _matchId;
  UserProfile? _targetProfile;
  bool _isLoading = true;
  bool _isAiMode = false;

  String _currentInsight = "Tap to feel the vibe";
  double _connectionProgress = 0.0;
  bool _isUnlocking = false;
  bool _hasUnlocked = false;
  
  final int _requiredMessages = 10;
  
  late List<String> _insights = ["Tap to feel the vibe"];

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    
    _radarRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    
    _radarPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    _matchId = widget.matchId;
    _targetProfile = widget.targetProfile;

    if (_matchId == null || _targetProfile == null) {
      _loadBlindMatch();
    } else {
      _initInsights();
      _isLoading = false;
    }
  }

  void _initInsights() {
    if (_targetProfile == null) return;
    _insights = [
      "Looking for: ${_targetProfile!.goal ?? 'A genuine connection'}",
      "Vibe check: ${_targetProfile!.matter ?? 'Chill and authentic'}",
      if (_targetProfile!.hobby != null) "Passionate about ${_targetProfile!.hobby}",
      "Location: ${_targetProfile!.location ?? 'Nearby'}",
    ];
  }

  Future<void> _loadBlindMatch() async {
    setState(() => _isLoading = true);
    
    try {
      // 1. Try to find an existing active blind match
      final matches = await _chatService.getMatches();
      final activeBlindMatches = matches.where((m) => m.isBlind && !m.isUnlocked).toList();
      
      if (activeBlindMatches.isNotEmpty) {
        setState(() {
          _matchId = activeBlindMatches.first.id;
          _targetProfile = activeBlindMatches.first.otherUser;
          _hasUnlocked = activeBlindMatches.first.currentUserUnlocked;
          _initInsights();
          _isLoading = false;
        });
        return;
      }

      // 2. Fetch a new profile using DiscoveryService
      final discoveryService = DiscoveryService();
      final profiles = await discoveryService.getBlindDiscoveryProfiles();
      
      if (profiles.isNotEmpty) {
        final newTarget = profiles.first;
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        
        if (currentUserId != null) {
          final ids = [currentUserId, newTarget.id]..sort();
          final response = await Supabase.instance.client.from('matches').upsert({
            'user1_id': ids[0],
            'user2_id': ids[1],
            'is_blind': true,
          }).select('id').single();
          
          if (mounted) {
            setState(() {
              _matchId = response['id'];
              _targetProfile = newTarget;
              _initInsights();
              _isLoading = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      print('Error loading blind match: $e');
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _orbController.dispose();
    _radarRotationController.dispose();
    _radarPulseController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onOrbTap() {
    setState(() {
      _currentInsight = _insights[math.Random().nextInt(_insights.length)];
    });
  }

  void _sendMessage([String? text]) {
    final content = text ?? _messageController.text.trim();
    if (content.isNotEmpty && _matchId != null) {
      _messageController.clear();
      _chatService.sendMessage(_matchId!, content).catchError((e) {
        if (mounted) UIHelpers.showSnackBar(context, 'Failed to send message: $e');
      });
    }
  }

  Future<void> _unlockIdentity() async {
    if (_connectionProgress < 1.0 || _matchId == null || _targetProfile == null) return;
    
    setState(() => _isUnlocking = true);
    try {
      final isFullyUnlocked = await _chatService.unlockMatch(_matchId!);
      if (mounted) {
        if (isFullyUnlocked) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => InteractionChatScreen(
                matchId: _matchId!,
                targetProfile: _targetProfile!,
              ),
            ),
          );
        } else {
          setState(() {
            _hasUnlocked = true;
            _isUnlocking = false;
          });
        }
      }
    } catch (e) {
      if (mounted) UIHelpers.showSnackBar(context, 'Error unlocking: $e');
      setState(() => _isUnlocking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFCFAFA),
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryMaroon)),
      );
    }

    if (_matchId == null || _targetProfile == null) {
      return _buildPremiumEmptyState();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFCFAFA),
      body: SafeArea(
        child: StreamBuilder<List<ChatMessage>>(
          stream: _chatService.getMessagesStream(_matchId!),
          builder: (context, snapshot) {
            final messages = snapshot.data ?? [];
            _connectionProgress = (messages.length / _requiredMessages).clamp(0.0, 1.0);
            
            return Column(
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
                        if (messages.isNotEmpty) _buildRecentMessages(messages)
                        else _buildPromptSection(),
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
            );
          }
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryMaroon),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.findAncestorStateOfType<MainNavigationScreenState>()?.jumpToTab(0);
              }
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Icon(Icons.notifications, color: AppTheme.primaryMaroon.withOpacity(0.85), size: 28),
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
    final interests = _targetProfile?.interests ?? [];
    if (interests.isEmpty) {
       return _buildTrait("Prefers to keep things mysterious");
    }
    
    return Column(
      children: interests.take(3).map((interest) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildTrait(interest),
        );
      }).toList(),
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
            "Start the conversation!",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF2C2C2E),
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Messages build connection and unlock photos.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMessages(List<ChatMessage> messages) {
    // Show only the last 2 messages for a sleek preview
    final recentMessages = messages.take(2).toList().reversed.toList();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Column(
        children: [
          const Text(
            "Recent Exchange",
            style: TextStyle(
              color: Color(0xFF2C2C2E),
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          ...recentMessages.map((msg) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: msg.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Flexible(
                  child: _buildResponse(msg.isMe ? "Me" : "Them", msg.content, msg.isMe),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildResponse(String user, String text, bool isMe) {
    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          user,
          style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe ? AppTheme.primaryMaroon.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isMe ? Colors.transparent : const Color(0xFFE5E5E5)),
          ),
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFF2C2C2E), fontSize: 13, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionMeter() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _connectionProgress,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.buttonGradient,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMeterStage("Curious", _connectionProgress >= 0.2),
            _buildMeterStage("Vibing", _connectionProgress >= 0.5),
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
    if (_hasUnlocked) {
      return Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFFE6E6E6),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Center(
          child: Text(
            "Waiting for other user to unlock... ⏳",
            style: TextStyle(
              color: Color(0xFF8E8E93), 
              fontWeight: FontWeight.bold, 
              fontSize: 15
            ),
          ),
        ),
      );
    }

    final bool canUnlock = _connectionProgress >= 1.0;
    
    return InkWell(
      onTap: canUnlock ? _unlockIdentity : () {
        UIHelpers.showSnackBar(context, 'Exchange more messages to unlock!');
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: canUnlock ? AppTheme.buttonGradient : null,
          color: canUnlock ? null : const Color(0xFFE6E6E6),
          borderRadius: BorderRadius.circular(30),
          boxShadow: canUnlock ? [
            BoxShadow(
              color: AppTheme.primaryMaroon.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Center(
          child: _isUnlocking 
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(
              canUnlock ? "Unlock Identity 🔓" : "Keep Chatting to Unlock",
              style: TextStyle(
                color: canUnlock ? Colors.white : const Color(0xFF8E8E93), 
                fontWeight: FontWeight.bold, 
                fontSize: 16
              ),
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
                _buildPromptChip("Tell me a secret 🤫"),
                const SizedBox(width: 8),
                _buildPromptChip("Favorite movie? 🍿"),
                const SizedBox(width: 8),
                _buildPromptChip("Morning or Night? 🦉"),
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
                  child: Center(
                    child: TextField(
                      controller: _messageController,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Type a message to fill the meter...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _sendMessage(),
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

  Widget _buildPromptChip(String text) {
    return InkWell(
      onTap: () {
        _messageController.text = text;
        _sendMessage();
      },
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

  // --- Premium Empty State UI ---

  Widget _buildPremiumEmptyState() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F0C29),
              Color(0xFF302B63),
              Color(0xFF0F0C29),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildCustomDarkHeader(),
              const SizedBox(height: 24),
              _buildModeToggle(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _isAiMode ? _buildAiConnect() : _buildRadarSearch(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDarkHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.findAncestorStateOfType<MainNavigationScreenState>()?.jumpToTab(0);
              }
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const Icon(Icons.notifications, color: Colors.white70, size: 28),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: _isAiMode ? MediaQuery.of(context).size.width / 2 - 40 - 4 : 4,
            right: _isAiMode ? 4 : MediaQuery.of(context).size.width / 2 - 40 - 4,
            top: 4,
            bottom: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isAiMode = false);
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: Text(
                        'Blind Mode',
                        style: TextStyle(
                          color: _isAiMode ? Colors.white54 : Colors.white,
                          fontWeight: _isAiMode ? FontWeight.w500 : FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isAiMode = true);
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: Text(
                        'AI Connect',
                        style: TextStyle(
                          color: _isAiMode ? Colors.white : Colors.white54,
                          fontWeight: _isAiMode ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadarSearch() {
    return Column(
      key: const ValueKey('radar'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            // Temporarily speed up radar on tap
            _radarRotationController.duration = const Duration(seconds: 1);
            _radarRotationController.forward(from: _radarRotationController.value).whenComplete(() {
              _radarRotationController.duration = const Duration(seconds: 3);
              _radarRotationController.repeat();
            });
          },
          child: SizedBox(
            width: 300,
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulsing outer rings
                AnimatedBuilder(
                  animation: _radarPulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_radarPulseController.value * 0.5),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(
                              0.3 * (1 - _radarPulseController.value),
                            ),
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Static inner rings
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white12, width: 1),
                  ),
                ),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white12, width: 1),
                  ),
                ),
                // Rotating radar sweep
                AnimatedBuilder(
                  animation: _radarRotationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _radarRotationController.value * 2 * math.pi,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              Colors.transparent,
                              const Color(0xFF9D4C5E).withOpacity(0.1),
                              const Color(0xFF9D4C5E).withOpacity(0.6),
                            ],
                            stops: const [0.5, 0.9, 1.0],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Center point
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 60),
        const Text(
          "Scanning for someone interesting 👀",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Hang tight or try AI Connect while we search",
          style: TextStyle(
            color: Colors.white54,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildAiConnect() {
    return Column(
      key: const ValueKey('ai_connect'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _orbController,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.95 + (_orbController.value * 0.1),
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFB5C6FF),
                      const Color(0xFF4C6B9D),
                      Colors.transparent,
                    ],
                    stops: const [0.2, 0.7, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4C6B9D).withOpacity(0.4),
                      blurRadius: 40 * _orbController.value + 20,
                      spreadRadius: 10 * _orbController.value,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 60),
        const Text(
          "I'm here if you want to chat ✧",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: InkWell(
            onTap: () => UIHelpers.showFeatureComingSoon(context),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  "Start a conversation",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
