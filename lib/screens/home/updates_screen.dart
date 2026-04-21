import 'package:flutter/material.dart';
import 'package:trish_app/core/theme.dart';
import 'package:trish_app/core/constants.dart';
import 'package:trish_app/core/ui_helpers.dart';
import 'package:trish_app/widgets/skeleton_loader.dart';
import 'package:trish_app/widgets/skeleton_factory.dart'; // v2: Refresh cache
import 'package:trish_app/screens/home/main_navigation_screen.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate initial loading
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _isLoading = false);
    });
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
    // For demo purposes, we'll assume there is content. 
    // To show empty state, return _buildEmptyState()
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      children: [
        _buildUpdateItem(
          context,
          title: 'New Match!',
          subtitle: 'You and David liked each other.',
          time: 'Just now',
          imageUrl: AppConstants.defaultAvatar1,
          isUnread: true,
          indicatorColor: const Color(0xFF9D4C5E),
        ),
        _buildUpdateItem(
          context,
          title: 'Elena',
          subtitle: '"That sounds like a perfect plan for Thursday! What...',
          time: '2m',
          imageUrl: AppConstants.defaultAvatar2,
          isUnread: true,
          indicatorColor: const Color(0xFF9D4C5E),
        ),
        _buildUpdateItem(
          context,
          title: 'A token of affection',
          subtitle: 'Marcus sent you a virtual bouquet.',
          time: '1h',
          icon: Icons.local_florist_rounded,
          iconBg: const Color(0xFFFFE5D9),
          indicatorColor: const Color(0xFF7D4249),
        ),
        _buildUpdateItem(
          context,
          title: 'Upcoming Date',
          subtitle: 'Coffee with Sam at Blue Bottle is tomorrow at 10 AM.',
          time: '4h',
          icon: Icons.calendar_today_rounded,
          iconBg: const Color(0xFFE5E6FF),
        ),
        _buildUpdateItem(
          context,
          title: 'James',
          subtitle: 'Loved that article...',
          time: 'Yesterday',
          imageUrl: AppConstants.defaultAvatar3,
        ),
      ],
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
          Text(
            'TRISH',
            style: TextStyle(
              color: AppTheme.primaryMaroon,
              fontWeight: FontWeight.w800,
              fontSize: 20,
              letterSpacing: 0.5,
            ),
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
    return Padding(
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
    Color? indicatorColor,
  }) {
    return GestureDetector(
      onTap: () => UIHelpers.showSnackBar(context, 'Details for: $title'),
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
