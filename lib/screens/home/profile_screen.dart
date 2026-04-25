import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import 'settings_screen.dart';
import '../auth/login_screen.dart';
import '../../core/ui_helpers.dart';
import 'main_navigation_screen.dart';
import 'my_wallet_screen.dart';
import 'edit_profile_screen.dart';
import 'moments_screen.dart';
import '../../core/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final metadata = user?.userMetadata;
    
    final fullName = metadata?['full_name'] ?? 'User';
    final firstName = fullName.split(' ').first;
    final bio = metadata?['bio'] ?? 'Tell us about yourself in your profile settings.';
    
    List<String> interests = [];
    final interestsData = metadata?['interests'];
    if (interestsData is List) {
      interests = List<String>.from(interestsData);
    } else {
      interests = ['Photography', 'Dogs', 'Coffee'];
    }

    List<String> moments = [];
    final momentsData = metadata?['moments'];
    if (momentsData is List) {
      moments = List<String>.from(momentsData);
    }

    final age = metadata?['age'] ?? 18;
    final location = metadata?['location'] ?? 'Unknown';
    final gender = metadata?['gender'] ?? 'Man';
    final hobby = metadata?['hobby'] ?? 'Photography';
    final avatarUrl = metadata?['avatar_url'];
    final goal = metadata?['goal'] ?? 'Meaningful connection';

    return Scaffold(
      backgroundColor: const Color(0xFFFCFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              _buildHeader(context, avatarUrl),
              const SizedBox(height: 32),
              _buildProfileCard(fullName, interests, age, location, gender, hobby, avatarUrl),
              const SizedBox(height: 32),
              _buildAboutSection(firstName, bio),
              const SizedBox(height: 32),
              _buildGallerySection(context, moments),
              const SizedBox(height: 32),
              _buildVibeSection(goal),
              const SizedBox(height: 32),
              _buildStrengthCard(moments.length),
              const SizedBox(height: 24),
              _buildMenuItem(context, Icons.edit_note_rounded, 'Edit Profile', 'Update photos, bio, and interests'),
              _buildMenuItem(context, Icons.account_balance_wallet_rounded, 'Wallet', 'Manage balance and transactions'),
              _buildMenuItem(context, Icons.favorite_rounded, 'Matches', 'View your connections and likes', badge: '3 New'),
              _buildMenuItem(context, Icons.card_giftcard_rounded, 'Gift', 'Manage tokens and premium features'),
              _buildMenuItem(context, Icons.settings_rounded, 'Settings', 'Preferences, privacy, and account', isLast: true),
              const SizedBox(height: 32),
              _buildLogoutButton(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String? avatarUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          Icon(Icons.notifications, color: AppTheme.primaryMaroon.withOpacity(0.85), size: 28),
        ],
      ),
    );
  }

  Widget _buildProfileCard(String fullName, List<String> interests, dynamic age, String location, String gender, String hobby, String? avatarUrl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(48),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryMaroon.withOpacity(0.08),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Glowing ring around avatar
              Container(
                width: 136,
                height: 136,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE56A7C), Color(0xFF9D4C5E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFE56A7C).withOpacity(0.4), blurRadius: 20, spreadRadius: 2),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: avatarUrl != null 
                      ? NetworkImage(avatarUrl) 
                      : const AssetImage('assets/image/connection.jpg') as ImageProvider,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryMaroon,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(color: AppTheme.primaryMaroon.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '$fullName, $age',
            style: const TextStyle(color: Color(0xFF2C2C2E), fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
          const SizedBox(height: 6),
          Text(
            '$gender • $hobby',
            style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildTag(location, isPrimary: true),
              ...interests.take(2).map((interest) => _buildTag(interest)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isPrimary ? AppTheme.primaryMaroon.withOpacity(0.1) : const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isPrimary ? AppTheme.primaryMaroon.withOpacity(0.2) : Colors.transparent),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isPrimary ? AppTheme.primaryMaroon : const Color(0xFF6B6B6B), 
          fontSize: 13, 
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStrengthCard(int momentsCount) {
    double progress = (momentsCount / 6).clamp(0.0, 1.0);
    int percentage = (progress * 100).toInt();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryMaroon.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: progress == 0 ? 0.05 : progress,
                  strokeWidth: 6,
                  backgroundColor: const Color(0xFFFDECEC),
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMaroon),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(color: AppTheme.primaryMaroon, fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile Strength',
                  style: TextStyle(color: Color(0xFF2C2C2E), fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  percentage < 100 
                      ? 'Add more moments to reach 100% and get more matches!' 
                      : 'Your profile is looking great!',
                  style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13, fontWeight: FontWeight.w500, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, String subtitle, {String? badge, bool isLast = false}) {
    return GestureDetector(
      onTap: () async {
        if (title == 'Settings') {
          await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
          setState(() {});
        } else if (title == 'Wallet') {
          await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MyWalletScreen()));
          setState(() {});
        } else if (title == 'Edit Profile') {
          await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const EditProfileScreen()));
          setState(() {});
        } else if (title == 'Gift') {
          context.findAncestorStateOfType<MainNavigationScreenState>()?.jumpToTab(3);
        } else if (title == 'Matches') {
          context.findAncestorStateOfType<MainNavigationScreenState>()?.jumpToTab(1);
        } else {
          UIHelpers.showFeatureComingSoon(context);
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFF2F2F7), width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFDECEC),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFFDECEC), blurRadius: 10, spreadRadius: 1),
                ],
              ),
              child: Icon(icon, color: AppTheme.primaryMaroon, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(color: Color(0xFF2C2C2E), fontWeight: FontWeight.w800, fontSize: 17),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF9D4C5E), borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            badge,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFD1D1D6), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(String firstName, String bio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About $firstName',
          style: const TextStyle(color: Color(0xFF2C2C2E), fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFF2F2F7)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryMaroon,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    bio,
                    style: const TextStyle(
                      color: Color(0xFF6B6B6B),
                      fontSize: 15,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGallerySection(BuildContext context, List<String> moments) {
    final List<String> photos = moments.isNotEmpty ? moments : [
      'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1495474472205-51f7d4c09264?auto=format&fit=crop&q=80',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Moments',
              style: TextStyle(color: Color(0xFF2C2C2E), fontSize: 20, fontWeight: FontWeight.w800),
            ),
            TextButton(
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MomentsScreen()));
                setState(() {});
              },
              child: const Text('Add More', style: TextStyle(color: Color(0xFF9D4C5E), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (moments.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Text('No moments uploaded yet.', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: photos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(photos[index], fit: BoxFit.cover),
              );
            },
          ),
      ],
    );
  }

  Widget _buildVibeSection(String goal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Core Values & Vibe',
          style: TextStyle(color: Color(0xFF2C2C2E), fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildVibeTag(goal, Icons.auto_awesome_rounded),
            _buildVibeTag('Authenticity', Icons.favorite_rounded),
            _buildVibeTag('Curiosity', Icons.explore_rounded),
          ],
        ),
      ],
    );
  }

  Widget _buildVibeTag(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF2F2F7)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF9D4C5E), size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF2C2C2E), fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await _authService.signOut();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      },
      child: Container(
        width: 160,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFDECEC),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFF9D4C5E), size: 20),
            SizedBox(width: 8),
            Text(
              'Logout',
              style: TextStyle(color: Color(0xFF9D4C5E), fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
