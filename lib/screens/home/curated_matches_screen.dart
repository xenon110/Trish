import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:trish_app/core/theme.dart';
import 'package:trish_app/core/constants.dart';
import 'package:trish_app/core/ui_helpers.dart';
import 'package:trish_app/widgets/bottom_nav_bar.dart';
import 'package:trish_app/widgets/skeleton_loader.dart';
import 'package:trish_app/widgets/skeleton_factory.dart'; // v2: Refresh cache
import 'package:trish_app/screens/home/interaction_chat_screen.dart';
import 'package:trish_app/screens/home/main_navigation_screen.dart';

class CuratedMatchesScreen extends StatefulWidget {
  const CuratedMatchesScreen({super.key});

  @override
  State<CuratedMatchesScreen> createState() => _CuratedMatchesScreenState();
}

class _CuratedMatchesScreenState extends State<CuratedMatchesScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFAFA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isLoading ? _buildLoadingState() : _buildContent(),
              ),
            ),
            BottomNavBar(
              currentIndex: 0,
              onTap: (idx) => UIHelpers.showSnackBar(context, 'Navigation to tab $idx from here is disabled.'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: List.generate(2, (index) => SkeletonFactory.skeletonCard(height: 300)),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Text(
            'Curated for You',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: const Color(0xFF2C2C2E),
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'We think you\'ll vibe with these matches.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF6B6B6B),
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 32),
          _buildMatchCard(
            context,
            name: 'Elias, 28',
            matchPercentage: '94%',
            vibe: 'Deep\nConnection',
            tags: ['Creative', 'Early Bird', 'Coffee Snob'],
            imageUrl: AppConstants.placeholderSuitMan,
          ),
          const SizedBox(height: 24),
          _buildMatchCard(
            context,
            name: 'Maya, 26',
            matchPercentage: '88%',
            vibe: 'Fun & Casual',
            tags: ['Adventurous', 'Foodie', 'Dog Lover'],
            imageUrl: AppConstants.defaultAvatar2,
          ),
          const SizedBox(height: 24),
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
                onPressed: () => Navigator.of(context).pop(),
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
            icon: Icon(Icons.notifications, color: AppTheme.primaryMaroon.withOpacity(0.85), size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(
    BuildContext context, {
    required String name,
    required String matchPercentage,
    required String vibe,
    required List<String> tags,
    required String imageUrl,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                    child: Container(
                      color: Colors.black.withOpacity(0.05),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Hero(
                  tag: 'vibe_icon_$vibe',
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.favorite, color: Color(0xFF9D4C5E), size: 16),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite, color: Color(0xFF9D4C5E), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        matchPercentage,
                        style: const TextStyle(
                          color: Color(0xFF9D4C5E),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'vibe_title_$vibe',
                  child: Material(
                    color: Colors.transparent,
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.map((tag) => _buildTag(tag)).toList(),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE5D9),
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: const Center(
                            child: Text(
                              'Skip',
                              style: TextStyle(
                                color: Color(0xFF7D4249),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const InteractionChatScreen()),
                          );
                        },
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF9D4C5E), Color(0xFFE89A9A)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF9D4C5E).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Start Interaction',
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF666666),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
