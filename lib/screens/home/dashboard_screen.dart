import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:trish_app/core/auth_service.dart';
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
import 'package:trish_app/core/discovery_service.dart';
import 'package:trish_app/models/user_profile.dart';
import 'package:trish_app/screens/auth/login_screen.dart';
import 'package:trish_app/screens/home/global_moments_screen.dart';
import 'package:trish_app/core/matching_service.dart';
import 'package:trish_app/screens/home/match_found_overlay.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final CardSwiperController _swiperController = CardSwiperController();
  final AuthService _authService = AuthService();
  final DiscoveryService _discoveryService = DiscoveryService();
  final MatchingService _matchingService = MatchingService();
  
  List<UserProfile> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    try {
      final profiles = await _discoveryService.getDiscoveryProfiles();
      setState(() {
        _profiles = profiles;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        UIHelpers.showSnackBar(context, 'Error loading profiles: $e');
      }
    }
  }

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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _profiles.isEmpty
                      ? _buildEmptyState()
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                          child: CardSwiper(
                            controller: _swiperController,
                            cardsCount: _profiles.length,
                            onSwipe: _onSwipe,
                            numberOfCardsDisplayed: _profiles.length > 1 ? 2 : 1,
                            isLoop: false,
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
    final profile = _profiles[previousIndex];
    final bool isLike = direction == CardSwiperDirection.right;

    if (isLike) {
      _matchingService.sendLike(profile.id).then((matchId) {
        if (matchId != null && mounted) {
          final currentUserMetadata = _authService.currentUser?.userMetadata;
          final currentUserAvatar = currentUserMetadata?['avatar_url'] ?? '';

          Navigator.push(
            context,
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (context) => MatchFoundOverlay(
                matchedProfile: profile,
                currentUserAvatar: currentUserAvatar,
                matchId: matchId,
              ),
            ),
          );
        }
      });
    }

    if (currentIndex == null || currentIndex >= _profiles.length) {
      // End of deck, maybe load more?
    }

    return true;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 80, color: AppTheme.primaryMaroon.withValues(alpha: 0.2)),
          const SizedBox(height: 24),
          const Text(
            'No more profiles nearby',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2E),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Check back later for new connections!',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _loadProfiles,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryMaroon,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Refresh', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showMatchDialog(UserProfile profile) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "IT'S A MATCH!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFE56A7C),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundImage: AssetImage('assets/image/connection.jpg'), // Current user
                  ),
                  const SizedBox(width: -15),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_rounded, color: Color(0xFFE56A7C), size: 32),
                  ),
                  const SizedBox(width: -15),
                  CircleAvatar(
                    radius: 45,
                    backgroundImage: profile.avatarUrl != null 
                        ? NetworkImage(profile.avatarUrl!) 
                        : const NetworkImage(AppConstants.defaultAvatar2) as ImageProvider,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                "You and ${profile.fullName} liked each other.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2C2C2E),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryMaroon,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text(
                    'Say Hello',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Keep Swiping',
                  style: TextStyle(color: Color(0xFF8E8E93), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const GlobalMomentsScreen()));
                },
                icon: Icon(Icons.auto_awesome_motion_rounded, color: AppTheme.primaryMaroon.withValues(alpha: 0.85), size: 28),
              ),
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
                    Text(
                      _authService.currentUser?.userMetadata?['full_name'] ?? 'User',
                      style: const TextStyle(
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
          _buildMenuTile(context, 'Logout', Icons.logout_rounded, isDestructive: true, onTap: () async {
            await _authService.signOut();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            }
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

  Widget _buildProfileCard(UserProfile profile) {
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
              child: profile.avatarUrl != null
                  ? Image.network(
                      profile.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300]),
                    )
                  : Image.network(
                      AppConstants.defaultAvatar1,
                      fit: BoxFit.cover,
                    ),
            ),
            // Report Button
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => _showReportDialog(profile),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flag_rounded, color: Colors.white70, size: 20),
                ),
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
                          '${profile.fullName}, ${profile.age}',
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
                  if (profile.interests.isNotEmpty)
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
                            profile.interests.first,
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

  void _showReportDialog(UserProfile profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Report User',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF2C2C2E)),
              ),
              const SizedBox(height: 8),
              Text(
                'Why are you reporting ${profile.fullName.split(' ').first}?',
                style: const TextStyle(fontSize: 16, color: Color(0xFF8E8E93)),
              ),
              const SizedBox(height: 24),
              _buildReportOption(profile, 'Fake Profile / Spam'),
              _buildReportOption(profile, 'Inappropriate Content'),
              _buildReportOption(profile, 'Harassment'),
              _buildReportOption(profile, 'Underage'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF8E8E93), fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportOption(UserProfile profile, String reason) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(reason, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      onTap: () async {
        Navigator.pop(context);
        try {
          // Use the profile ID directly instead of trying to find the index
          await Supabase.instance.client.from('reports').insert({
            'reporter_id': _authService.currentUser?.id,
            'reported_id': profile.id,
            'reason': reason,
          });
          
          if (mounted) {
            UIHelpers.showSnackBar(context, 'Report submitted. Thank you for keeping Trish safe.');
            _swiperController.swipe(CardSwiperDirection.left);
          }
        } catch (e) {
          if (mounted) UIHelpers.showSnackBar(context, 'Error submitting report: $e');
        }
      },
    );
  }
}
