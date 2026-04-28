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
import 'package:trish_app/screens/home/notifications_screen.dart';
import '../../core/auth_service.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  final ChatService _chatService = ChatService();
  bool _isLoading = true;
  List<ChatMatch> _matches = [];
  String _selectedFilter = 'All';
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() => _isLoading = true);
    try {
      final matches = await _chatService.getMatches();
      final unreadNotifs = await AuthService().getUnreadNotificationCount();
      setState(() {
        _matches = matches;
        _unreadNotificationCount = unreadNotifs;
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
              child: StreamBuilder<List<ChatMatch>>(
                stream: _chatService.getMatchesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && _matches.isEmpty) {
                    return _buildLoadingState();
                  }
                  
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.hasData) {
                    _matches = snapshot.data!;
                  }

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _matches.isEmpty ? _buildEmptyState() : _buildContent(),
                  );
                },
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

  /// Returns matches filtered by the selected chip.
  /// 'Unread'  = matches that have unread messages.
  /// 'All'     = every match.
  List<ChatMatch> get _filteredMatches {
    if (_selectedFilter == 'Unread') {
      return _matches.where((m) => m.unreadCount > 0).toList();
    }
    if (_selectedFilter == 'Blind') {
      return _matches.where((m) => m.isBlind && !m.isUnlocked).toList();
    }
    // For 'All', we can exclude blind matches if we want, or keep them.
    // The user said "where the separate chat will be", so maybe exclude from All?
    // Let's exclude them from All to keep them separate.
    if (_selectedFilter == 'All') {
      return _matches.where((m) => !m.isBlind || m.isUnlocked).toList();
    }
    return _matches;
  }

  Widget _buildContent() {
    final filtered = _filteredMatches;

    return RefreshIndicator(
      onRefresh: _loadMatches,
      color: AppTheme.primaryMaroon,
      child: CustomScrollView(
        slivers: [
          // --- New Matches row (only visible on 'All') ---
          if (_selectedFilter == 'All')
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
                ],
              ),
            ),
            
          // --- Start New Blind Match (only visible on 'Blind') ---
          if (_selectedFilter == 'Blind')
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BlindModeScreen()),
                    ).then((_) => _loadMatches());
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F0C29),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Find New Blind Match', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // --- Section label ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
              child: Text(
                _selectedFilter == 'Unread' ? 'Waiting for a reply' : 'Messages',
                style: const TextStyle(
                  color: Color(0xFF2C2C2E),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          // --- Empty-filter state ---
          if (filtered.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  'No unread matches right now 🎉',
                  style: TextStyle(color: Color(0xFF8E8E93), fontSize: 15),
                ),
              ),
            )
          else
            // --- Conversation list ---
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final match = filtered[index];
                    final isBlindMatch = match.isBlind && !match.isUnlocked;
                    final displayTime = DateFormat.jm().format(
                        match.lastMessageAt ?? match.createdAt);

                    return _buildUpdateItem(
                      context,
                      title: isBlindMatch ? 'Blind Match' : match.otherUser.fullName,
                      subtitle: match.lastMessage ?? 'You matched! Say hi 👋',
                      time: displayTime,
                      imageUrl: isBlindMatch ? null : match.otherUser.avatarUrl,
                      icon: isBlindMatch ? Icons.visibility_off : null,
                      isOnline: match.otherUser.isOnline,
                      isUnread: match.unreadCount > 0,
                      unreadCount: match.unreadCount,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => isBlindMatch
                                ? BlindModeScreen(
                                    matchId: match.id,
                                    targetProfile: match.otherUser)
                                : InteractionChatScreen(
                                    matchId: match.id,
                                    targetProfile: match.otherUser,
                                  ),
                          ),
                        ).then((_) => _loadMatches());
                      },
                    );
                  },
                  childCount: filtered.length,
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
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
              _loadMatches(); // Refresh count after coming back
            },
            icon: Stack(
              children: [
                Icon(Icons.notifications, color: AppTheme.primaryMaroon.withOpacity(0.85), size: 28),
                if (_unreadNotificationCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$_unreadNotificationCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
          _buildFilterChip(context, 'All'),
          const SizedBox(width: 12),
          _buildFilterChip(context, 'Unread'),
          const SizedBox(width: 12),
          _buildFilterChip(context, 'Blind'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label) {
    final isSelected = _selectedFilter == label;
    // Show badge count on 'Unread' chip
    final unreadTotal = label == 'Unread'
        ? _matches.where((m) => m.hasNoMessages).length
        : 0;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF2C2C2E),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            if (unreadTotal > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFE56A7C)
                      : AppTheme.primaryMaroon,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$unreadTotal',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
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
    int unreadCount = 0,
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
