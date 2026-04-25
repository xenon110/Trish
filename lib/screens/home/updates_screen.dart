import 'package:flutter/material.dart';
import 'package:trish_app/core/theme.dart';
import 'package:trish_app/core/constants.dart';
import 'package:trish_app/core/ui_helpers.dart';
import 'package:trish_app/widgets/skeleton_loader.dart';
import 'package:trish_app/widgets/skeleton_factory.dart'; // v2: Refresh cache
import 'package:trish_app/screens/home/main_navigation_screen.dart';
import 'package:trish_app/core/chat_service.dart';
import 'package:trish_app/screens/home/interaction_chat_screen.dart';
import 'package:trish_app/screens/home/blind_mode_screen.dart';
import 'package:trish_app/models/user_profile.dart';
import 'package:intl/intl.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  final ChatService _chatService = ChatService();
  bool _isLoading = true;
  List<ChatMatch> _matches = [];

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() => _isLoading = true);
    try {
      final matches = await _chatService.getMatches();
      setState(() {
        _matches = matches;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        UIHelpers.showSnackBar(context, 'Error loading updates: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFAFA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Updates',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: const Color(0xFF2C2C2E),
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your latest messages, matches,\nand little reminders.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF6B6B6B),
                          fontSize: 18,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildFilters(context),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isLoading ? _buildLoadingState() : _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      children: List.generate(5, (index) => SkeletonFactory.skeletonListTile()),
    );
  }

  Widget _buildContent() {
    if (_matches.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadMatches,
      color: AppTheme.primaryMaroon,
      child: CustomScrollView(
        slivers: [
          // 1. New Matches Section (Horizontal)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Text(
                    'New Matches',
                    style: TextStyle(
                      color: Color(0xFF2C2C2E),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _matches.length,
                    itemBuilder: (context, index) {
                      final match = _matches[index];
                      return _buildNewMatchCircle(match);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Messages',
                    style: TextStyle(
                      color: Color(0xFF2C2C2E),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Messages Section (Vertical)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final match = _matches[index];
                  final isBlindMatch = match.isBlind && !match.isUnlocked;
                  
                  return _buildUpdateItem(
                    context,
                    title: isBlindMatch ? 'Blind Match' : match.otherUser.fullName,
                    subtitle: match.lastMessage ?? 'You matched! Say hi to start the conversation.',
                    time: DateFormat.jm().format(match.createdAt),
                    imageUrl: isBlindMatch ? null : match.otherUser.avatarUrl,
                    icon: isBlindMatch ? Icons.visibility_off : null,
                    isOnline: match.otherUser.isOnline,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => isBlindMatch
                              ? BlindModeScreen(matchId: match.id, targetProfile: match.otherUser)
                              : InteractionChatScreen(
                                  matchId: match.id,
                                  targetProfile: match.otherUser,
                                ),
                        ),
                      );
                    },
                  );
                },
                childCount: _matches.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewMatchCircle(ChatMatch match) {
    final isBlindMatch = match.isBlind && !match.isUnlocked;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => isBlindMatch
                ? BlindModeScreen(matchId: match.id, targetProfile: match.otherUser)
                : InteractionChatScreen(
                    matchId: match.id,
                    targetProfile: match.otherUser,
                  ),
          ),
        );
      },
      child: Container(
        width: 85,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppTheme.primaryMaroon, const Color(0xFFE56A7C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: isBlindMatch ? const Color(0xFFC7C7CC) : Colors.white,
                    backgroundImage: isBlindMatch 
                        ? null 
                        : (match.otherUser.avatarUrl != null
                            ? NetworkImage(match.otherUser.avatarUrl!)
                            : const NetworkImage(AppConstants.defaultAvatar1) as ImageProvider),
                    child: isBlindMatch ? const Icon(Icons.visibility_off, color: Colors.white, size: 30) : null,
                  ),
                  if (match.otherUser.isOnline)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isBlindMatch ? 'Blind' : match.otherUser.fullName.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF2C2C2E),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(color: Color(0xFFFDECEC), shape: BoxShape.circle),
            child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF9D4C5E), size: 48),
          ),
          const SizedBox(height: 24),
          const Text(
            'All caught up!',
            style: TextStyle(color: Color(0xFF2C2C2E), fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check back later for new matches and\nupdates from your connections.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
          IconButton(
            onPressed: () => UIHelpers.showFeatureComingSoon(context),
            icon: Stack(
              children: [
                Icon(Icons.notifications, color: AppTheme.primaryMaroon.withOpacity(0.85), size: 28),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFCFAFA), width: 2),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          _buildFilterChip(context, 'All', true),
          const SizedBox(width: 12),
          _buildFilterChip(context, 'Matches', false),
          const SizedBox(width: 12),
          _buildFilterChip(context, 'Messages', false),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, bool isSelected) {
    return GestureDetector(
      onTap: () => UIHelpers.showSnackBar(context, 'Filter applied: $label'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF2C2C2E),
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String time,
    String? imageUrl,
    IconData? icon,
    Color? iconBg,
    bool isUnread = false,
    bool isOnline = false,
    Color? indicatorColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconBg ?? const Color(0xFFF2F2F7),
                    shape: BoxShape.circle,
                    image: imageUrl != null ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
                  ),
                  child: icon != null ? Icon(icon, color: const Color(0xFF7D4249), size: 24) : null,
                ),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                    ),
                  ),
              ],
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
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isUnread ? const Color(0xFF9D4C5E) : const Color(0xFF8E8E93),
                      fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isUnread) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: indicatorColor ?? const Color(0xFF9D4C5E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  time,
                  style: TextStyle(
                    color: isUnread ? const Color(0xFF9D4C5E) : const Color(0xFF8E8E93),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
