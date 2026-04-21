import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:trish_app/core/theme.dart';
import 'package:trish_app/core/constants.dart';
import 'package:trish_app/core/ui_helpers.dart';
import 'package:trish_app/screens/home/main_navigation_screen.dart';
import 'package:trish_app/screens/home/profile_screen.dart';
import 'package:trish_app/screens/home/wallet_screen.dart';
import 'package:trish_app/screens/home/my_wallet_screen.dart';
import 'package:trish_app/screens/home/gift_history_screen.dart';
import 'package:trish_app/screens/home/notifications_screen.dart';
import 'package:trish_app/screens/home/settings_screen.dart';
import 'package:trish_app/screens/home/help_support_screen.dart';
import 'package:trish_app/screens/home/invite_friends_screen.dart';

class DiscoveryProfile {
  final String id;
  final String name;
  final int age;
  final String location;
  final String hobby;
  final String imageUrl;

  DiscoveryProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.location,
    required this.hobby,
    required this.imageUrl,
  });
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final CardSwiperController _swiperController = CardSwiperController();
  
  final List<DiscoveryProfile> _profiles = [
    DiscoveryProfile(
      id: '1',
      name: 'Jessica',
      age: 24,
      location: 'New York, 2 miles away',
      hobby: 'Photography & Coffee',
      imageUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&q=80',
    ),
    DiscoveryProfile(
      id: '2',
      name: 'Michael',
      age: 27,
      location: 'Brooklyn, 5 miles away',
      hobby: 'Hiking and Outdoors',
      imageUrl: 'https://images.unsplash.com/photo-1506794778202-b844b4a07d3b?auto=format&fit=crop&q=80',
    ),
    DiscoveryProfile(
      id: '3',
      name: 'Sarah',
      age: 23,
      location: 'Queens, 1 mile away',
      hobby: 'Art Museums',
      imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80',
    ),
    DiscoveryProfile(
      id: '4',
      name: 'David',
      age: 26,
      location: 'Manhattan, 3 miles away',
      hobby: 'Live Music',
      imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFAFA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilters(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: CardSwiper(
                  controller: _swiperController,
                  cardsCount: _profiles.length,
                  onSwipe: _onSwipe,
                  numberOfCardsDisplayed: 2,
                  isLoop: true,
                  padding: EdgeInsets.zero,
                  cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                    return _buildProfileCard(_profiles[index]);
                  },
                ),
              ),
            ),
            _buildActionButtons(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    // Example handling 
    if (direction == CardSwiperDirection.right) {
      debugPrint('Liked profile ${_profiles[previousIndex].name}');
    } else if (direction == CardSwiperDirection.left) {
      debugPrint('Passed profile ${_profiles[previousIndex].name}');
    }
    return true;
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  context.findAncestorStateOfType<MainNavigationScreenState>()?.jumpToTab(4);
                },
                child: const CircleAvatar(
                  radius: 20,
                  backgroundImage: AssetImage('assets/image/connection.jpg'),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'TRISH',
                style: TextStyle(
                  color: AppTheme.primaryMaroon,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
                },
                icon: Icon(Icons.notifications_none_rounded, color: AppTheme.primaryMaroon.withValues(alpha: 0.85), size: 28),
              ),
              IconButton(
                onPressed: () => _showOverflowMenu(context),
                icon: Icon(Icons.more_vert_rounded, color: AppTheme.primaryMaroon.withValues(alpha: 0.85), size: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOverflowMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildOverflowSheet(context),
    );
  }

  Widget _buildOverflowSheet(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 24, top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFEBEBEB),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 24),
          // User Info at top
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundImage: AssetImage('assets/image/connection.jpg'),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alex (28)',
                      style: TextStyle(
                        color: Color(0xFF2C2C2E),
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      'View Profile',
                      style: TextStyle(
                        color: AppTheme.primaryMaroon,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF2F2F7), thickness: 1.5, height: 1),
          const SizedBox(height: 8),
          _buildMenuTile(context, 'Profile', Icons.person_rounded, onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
          }),
          _buildMenuTile(context, 'Wallet / Balance', Icons.account_balance_wallet_rounded, onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const MyWalletScreen()));
          }),
          _buildMenuTile(context, 'My Gifts', Icons.card_giftcard_rounded, onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const GiftHistoryScreen()));
          }),
          _buildMenuTile(context, 'Notifications', Icons.notifications_none_rounded, hasBadge: true, onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
          }),
          _buildMenuTile(context, 'Settings', Icons.settings_rounded, onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
          }),
          _buildMenuTile(context, 'Help & Support', Icons.help_outline_rounded, onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen()));
          }),
          _buildMenuTile(context, 'Invite Friends', Icons.person_add_alt_1_rounded, onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const InviteFriendsScreen()));
          }),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFF2F2F7), thickness: 1.5, height: 1),
          const SizedBox(height: 8),
          _buildMenuTile(context, 'Logout', Icons.logout_rounded, isDestructive: true, onTap: () {
            Navigator.pop(context);
            debugPrint('Logout clicked');
          }),
        ],
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, String title, IconData icon, {bool hasBadge = false, bool isDestructive = false, required VoidCallback onTap}) {
    final color = isDestructive ? const Color(0xFFE56A7C) : const Color(0xFF2C2C2E);
    
    return InkWell(
      onTap: onTap,
      splashColor: isDestructive ? const Color(0xFFE56A7C).withValues(alpha: 0.1) : AppTheme.primaryMaroon.withValues(alpha: 0.05),
      highlightColor: isDestructive ? const Color(0xFFE56A7C).withValues(alpha: 0.05) : AppTheme.primaryMaroon.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 26),
                if (hasBadge)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE56A7C),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  )
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: isDestructive ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: const Color(0xFFC7C7CC), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Nearby', true),
            const SizedBox(width: 8),
            _buildFilterChip('Age 20-30', false),
            const SizedBox(width: 8),
            _buildFilterChip('Deep Talks', false),
            const SizedBox(width: 8),
            _buildFilterChip('Verified', false),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryMaroon : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppTheme.primaryMaroon : const Color(0xFFEBEBEB),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF6B6B6B),
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildProfileCard(DiscoveryProfile profile) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          alignment: Alignment.bottomLeft,
          children: [
            // Profile Image Content
            Positioned.fill(
              child: Image.network(
                profile.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300]),
              ),
            ),
            // Soft Gradient Overlay matching instructions
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 250,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.85),
                    ],
                  ),
                ),
              ),
            ),
            // Profile Overlay Text (Name, Location, Hobby)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          '${profile.name}, ${profile.age}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.verified, color: Colors.blueAccent, size: 24),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        profile.location,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_border, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          profile.hobby,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCircularIconButton(
            icon: Icons.close_rounded,
            color: const Color(0xFFE56A7C),
            size: 64,
            iconSize: 32,
            onTap: () => _swiperController.swipe(CardSwiperDirection.left),
          ),
          _buildCircularIconButton(
            icon: Icons.favorite_rounded,
            color: const Color(0xFF4CE5A0),
            size: 64,
            iconSize: 32,
            onTap: () => _swiperController.swipe(CardSwiperDirection.right),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularIconButton({
    required IconData icon,
    required Color color,
    required double size,
    required double iconSize,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.1), width: 1),
        ),
        child: Icon(icon, color: color, size: iconSize),
      ),
    );
  }
}
