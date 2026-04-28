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
  bool _showMatchPopup = false;
  
  final int _requiredMessages = 10;
  
  late List<String> _insights = ["Tap to feel the vibe"];

  RealtimeChannel? _matchChannel;

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

    if (_matchId != null) {
      _chatService.markMessagesAsRead(_matchId!);
      _setupMatchListener();
    }

    if (_matchId == null || _targetProfile == null) {
      _loadBlindMatch();
    } else {
      _initInsights();
      _isLoading = false;
    }
  }

  bool _isFullyUnlocked = false;

  void _setupMatchListener() {
    if (_matchId == null) return;
    _matchChannel = Supabase.instance.client
        .channel('public:matches:$_matchId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'matches',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: _matchId!),
          callback: (payload) {
            final updatedMatch = payload.newRecord;
            if (updatedMatch['is_unlocked'] == true) {
              if (mounted) {
                setState(() {
                  _isFullyUnlocked = true;
                  _hasUnlocked = true;
                });
                UIHelpers.showSnackBar(context, 'Identity Revealed! 🎉');
              }
            } else if (updatedMatch['user1_unlocked'] == true || updatedMatch['user2_unlocked'] == true) {
              // The other user unlocked
              if (mounted) {
                 final currentUserId = Supabase.instance.client.auth.currentUser?.id;
                 final isUser1 = updatedMatch['user1_id'] == currentUserId;
                 final otherUnlocked = isUser1 ? updatedMatch['user2_unlocked'] == true : updatedMatch['user1_unlocked'] == true;
                 if (otherUnlocked && !_hasUnlocked) {
                   UIHelpers.showSnackBar(context, 'The other user wants to reveal identity! 👀');
                 }
              }
            }
          },
        )
        .subscribe();
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
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      // 1. Try to find an existing active blind match
      final matches = await _chatService.getMatches();
      final activeBlindMatches = matches.where((m) => m.isBlind && !m.isUnlocked).toList();
      
      if (activeBlindMatches.isNotEmpty) {
        final activeMatch = activeBlindMatches.first;
        setState(() {
          _matchId = activeMatch.id;
          _targetProfile = activeMatch.otherUser;
          _hasUnlocked = activeMatch.currentUserUnlocked;
          _isFullyUnlocked = activeMatch.isUnlocked;
          _initInsights();
          if (activeMatch.hasNoMessages) {
             _showMatchPopup = true;
          }
          _isLoading = false;
        });
        _setupMatchListener();
        return;
      }

      // 2. JOIN THE WAITING POOL
      await Supabase.instance.client.from('blind_pool').upsert({'user_id': currentUserId});

      // 3. SEARCH THE POOL FOR SOMEONE ELSE
      final poolResponse = await Supabase.instance.client
          .from('blind_pool')
          .select('user_id, profiles(*)')
          .neq('user_id', currentUserId)
          .order('created_at', ascending: true)
          .limit(1);

      if ((poolResponse as List).isNotEmpty) {
        final otherUserData = poolResponse.first;
        final otherUserId = otherUserData['user_id'];
        final otherProfile = UserProfile.fromJson(otherUserData['profiles']);

        // Found a partner! Create the match.
        final ids = [currentUserId, otherUserId]..sort();
        final matchResponse = await Supabase.instance.client.from('matches').upsert({
          'user1_id': ids[0],
          'user2_id': ids[1],
          'is_blind': true,
          'is_unlocked': false,
          'user1_unlocked': false,
          'user2_unlocked': false,
        }, onConflict: 'user1_id,user2_id').select('id').single();

        // REMOVE BOTH FROM POOL
        await Supabase.instance.client.from('blind_pool').delete().inFilter('user_id', [currentUserId, otherUserId]);

        if (mounted) {
          setState(() {
            _matchId = matchResponse['id'];
            _targetProfile = otherProfile;
            _initInsights();
            _showMatchPopup = true;
            _isLoading = false;
          });
          _setupMatchListener();
        }
        return;
      }

      // 4. If no one found, stay on Radar and listen for incoming matches
      _setupIncomingMatchListener();
      
    } catch (e) {
      print('Error loading blind match: $e');
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _setupIncomingMatchListener() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    // Listen for when our own row gets DELETED from blind_pool
    // This means someone matched us and removed us from the waiting room!
    Supabase.instance.client
        .channel('blind_pool:waiting:$currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'blind_pool',
          callback: (payload) {
            final deletedRow = payload.oldRecord;
            // If OUR user_id row was deleted, it means we got matched!
            if (deletedRow['user_id'] == currentUserId && _matchId == null) {
              // Reload to find the newly created match and show the popup
              _loadBlindMatch();
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    // Remove from waiting pool when leaving
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId != null) {
      Supabase.instance.client.from('blind_pool').delete().eq('user_id', currentUserId).then((_) {});
    }

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
    if (_matchId == null || _targetProfile == null) return;
    
    setState(() => _isUnlocking = true);
    try {
      final isFullyUnlocked = await _chatService.unlockMatch(_matchId!);
      if (mounted) {
        if (isFullyUnlocked) {
          setState(() {
            _isFullyUnlocked = true;
            _hasUnlocked = true;
            _isUnlocking = false;
          });
          UIHelpers.showSnackBar(context, 'Identity Revealed! 🎉');
        } else {
          setState(() {
            _hasUnlocked = true;
            _isUnlocking = false;
          });
          UIHelpers.showSnackBar(context, 'Waiting for the other user to reveal...');
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

    if (_showMatchPopup) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0C29),
        body: SafeArea(
          child: _buildMatchPopup(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      body: SafeArea(
        child: StreamBuilder<List<ChatMessage>>(
          stream: _chatService.getMessagesStream(_matchId!),
          builder: (context, snapshot) {
            final messages = snapshot.data ?? [];
            
            // Calculate total words
            int totalWords = 0;
            for (var msg in messages) {
              totalWords += msg.content.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
            }
            final int wordsRemaining = (800 - totalWords).clamp(0, 800);
            
            // Simulate AI Score (starts at 50, goes up based on chat length)
            int aiScore = 50 + (totalWords / 10).floor().clamp(0, 48);
            
            return Column(
              children: [
                _buildDarkHeader(),
                _buildBlurredProfileHeader(aiScore),
                _buildWordLimitIndicator(wordsRemaining),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFFCFAFA),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: messages.isNotEmpty 
                            ? _buildFullChatList(messages) 
                            : _buildPromptSection(),
                        ),
                        _buildActionButtons(wordsRemaining == 0),
                      ],
                    ),
                  ),
                ),
                _buildChatInputArea(wordsRemaining == 0),
              ],
            );
          }
        ),
      ),
    );
  }

  Widget _buildDarkHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
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
          const Text(
            'Blind Chat',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurredProfileHeader(int aiScore) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
              image: DecorationImage(
                image: NetworkImage(_targetProfile?.avatarUrl ?? 'https://ui-avatars.com/api/?name=Anonymous'),
                fit: BoxFit.cover,
                // Simulate blur effect locally since flutter image filter can be heavy
                colorFilter: _isFullyUnlocked ? null : ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.darken),
              ),
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: null, // Just an overlay is fine for now
                child: Container(color: _isFullyUnlocked ? Colors.transparent : Colors.white.withOpacity(0.2)),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isFullyUnlocked ? (_targetProfile?.fullName ?? 'Unknown') : 'Anonymous Match',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34C759).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Color(0xFF34C759), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '$aiScore% AI Vibe Match',
                            style: const TextStyle(color: Color(0xFF34C759), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordLimitIndicator(int wordsRemaining) {
    final double progress = wordsRemaining / 800;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0).copyWith(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Session Limit', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
              Text('$wordsRemaining words left', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(2)),
            child: FractionallySizedBox(
              alignment: Alignment.centerRight,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: wordsRemaining < 100 ? const Color(0xFFFF3B30) : const Color(0xFF34C759),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
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

  Widget _buildFullChatList(List<ChatMessage> messages) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      reverse: true, // Scroll from bottom
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: msg.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!msg.isMe) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[300],
                  child: const Icon(Icons.person, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: msg.isMe ? AppTheme.primaryMaroon : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(20).copyWith(
                      bottomRight: msg.isMe ? const Radius.circular(4) : const Radius.circular(20),
                      bottomLeft: !msg.isMe ? const Radius.circular(4) : const Radius.circular(20),
                    ),
                  ),
                  child: Text(
                    msg.content,
                    style: TextStyle(
                      color: msg.isMe ? Colors.white : const Color(0xFF2C2C2E), 
                      fontSize: 14, 
                      height: 1.4
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(bool isLockedOut) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        children: [
          if (_hasUnlocked && !_isFullyUnlocked) 
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: const Color(0xFFE6E6E6), borderRadius: BorderRadius.circular(24)),
              child: const Center(child: Text("Waiting for other user to reveal... ⏳", style: TextStyle(color: Color(0xFF8E8E93), fontWeight: FontWeight.bold))),
            ),
            
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    // Permanently end chat logic
                    final matchId = _matchId;
                    if (matchId != null) {
                      await Supabase.instance.client.from('matches').delete().eq('id', matchId);
                    }
                    if (mounted) Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: const Color(0xFFFF3B30),
                    side: const BorderSide(color: Color(0xFFFF3B30), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text('End Chat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              if (!_isFullyUnlocked) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _hasUnlocked ? null : _unlockIdentity,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primaryMaroon,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: _isUnlocking 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Reveal Identity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatInputArea(bool isLockedOut) {
    if (isLockedOut) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      color: const Color(0xFFFCFAFA),
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

  Widget _buildMatchPopup() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Match Found!',
            style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1),
          ),
          const SizedBox(height: 8),
          const Text(
            'Someone matches your vibe.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 48),
          
          // Blurred Profile Card
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.5), width: 3),
                    image: DecorationImage(
                      image: NetworkImage(_targetProfile?.avatarUrl ?? 'https://ui-avatars.com/api/?name=Anonymous'),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.7), BlendMode.darken),
                    ),
                  ),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: null, // Basic overlay is used above
                      child: Container(color: Colors.white.withOpacity(0.2)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Anonymous Profile',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFF34C759), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'High Vibe Match',
                      style: const TextStyle(color: Color(0xFF34C759), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 64),
          
          // Start Chat Button
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _showMatchPopup = false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryMaroon,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 0,
              ),
              child: const Text('Start Chat', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Skip Button
          TextButton(
            onPressed: () async {
              // Delete match and go back
              if (_matchId != null) {
                await Supabase.instance.client.from('matches').delete().eq('id', _matchId!);
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Skip for now', style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.bold)),
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
