import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/constants.dart';
import '../../core/ui_helpers.dart';
import 'package:trish_app/screens/home/main_navigation_screen.dart';
import 'add_gift_screen.dart';
import 'gift_history_screen.dart';
import 'received_gifts_screen.dart';
import 'full_transaction_history_screen.dart';

class TopGift {
  final String emoji;
  final String name;
  final int price;
  final double rating;
  TopGift(this.emoji, this.name, this.price, this.rating);
}

class GiftActivity {
  final String userImage;
  final String userName;
  final String giftEmoji;
  final String message;
  final String time;
  final bool isReceived;

  GiftActivity({
    required this.userImage,
    required this.userName,
    required this.giftEmoji,
    required this.message,
    required this.time,
    required this.isReceived,
  });
}

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildBalanceCard(context),
              const SizedBox(height: 24),
              _buildActionOptions(context),
              const SizedBox(height: 36),
              _buildTopGiftsSection(context),
              const SizedBox(height: 36),
              _buildRecentGiftsActivity(context),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
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
                  backgroundImage: AssetImage('assets/image/connection.jpg'),
                ),
              ),
            ],
          ),
          const Text(
            'GIFTS',
            style: TextStyle(
              color: Color(0xFF2C2C2E),
              fontWeight: FontWeight.w800,
              fontSize: 20,
              letterSpacing: 0.5,
            ),
          ),
          Icon(Icons.card_giftcard_rounded, color: AppTheme.primaryMaroon.withValues(alpha: 0.85), size: 28),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFFDFBFB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'TOTAL GIFT BALANCE',
            style: TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹',
                style: TextStyle(
                  color: Color(0xFF2C2C2E),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 4),
              Text(
                '1,245.50',
                style: TextStyle(
                  color: Color(0xFF2C2C2E),
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPrimaryButton(
                context,
                'Send Gift',
                Icons.card_giftcard,
                AppTheme.primaryMaroon,
                Colors.white,
                () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AddGiftScreen()));
                },
              ),
              const SizedBox(width: 16),
              _buildPrimaryButton(
                context,
                'Received',
                Icons.mark_email_read_outlined,
                const Color(0xFFF2F2F7),
                const Color(0xFF2C2C2E),
                () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const GiftHistoryScreen()));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(BuildContext context, String text, IconData icon, Color bgColor, Color textColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionOptions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            context,
            'Add Gift',
            Icons.add_circle_outline,
            const Color(0xFFFFE5D9),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddGiftScreen())),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionCard(
            context,
            'Gift History',
            Icons.history_rounded,
            const Color(0xFFE5E6FF),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GiftHistoryScreen())),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, String label, IconData icon, Color iconBgColor, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () => UIHelpers.showFeatureComingSoon(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF2C2C2E), size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF2C2C2E),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopGiftsSection(BuildContext context) {
    final gifts = [
      TopGift('🌹', 'Rose', 10, 4.8),
      TopGift('🍫', 'Chocolate', 25, 4.9),
      TopGift('🎁', 'Teddy', 50, 4.7),
      TopGift('💎', 'Diamond', 100, 5.0),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Gifts',
          style: TextStyle(
            color: Color(0xFF2C2C2E),
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: gifts.map((gift) => _buildGiftCard(context, gift)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildGiftCard(BuildContext context, TopGift gift) {
    return GestureDetector(
      onTap: () => UIHelpers.showFeatureComingSoon(context),
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFFFF9F9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withValues(alpha: 0.04),
              blurRadius: 15,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: Colors.pink.shade50.withValues(alpha: 0.5), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              gift.emoji,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 12),
            Text(
              gift.name,
              style: const TextStyle(
                color: Color(0xFF2C2C2E),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '₹${gift.price}',
                  style: TextStyle(
                    color: AppTheme.primaryMaroon,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 14),
                    const SizedBox(width: 2),
                    Text(
                      gift.rating.toString(),
                      style: const TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentGiftsActivity(BuildContext context) {
    final activities = [
      GiftActivity(
        userImage: AppConstants.defaultAvatar2,
        userName: 'Sarah',
        giftEmoji: '🌹',
        message: 'Thanks for the lovely date!',
        time: '2 min ago',
        isReceived: true,
      ),
      GiftActivity(
        userImage: AppConstants.defaultAvatar3,
        userName: 'Mike',
        giftEmoji: '🍫',
        message: 'Sent a sweet treat',
        time: '1 hr ago',
        isReceived: false,
      ),
      GiftActivity(
        userImage: AppConstants.defaultAvatar2,
        userName: 'Emma',
        giftEmoji: '🎁',
        message: 'Happy Birthday!',
        time: 'Yesterday',
        isReceived: true,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Gifts Activity',
              style: TextStyle(
                color: Color(0xFF2C2C2E),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const GiftHistoryScreen()));
              },
              child: Text(
                'See All',
                style: TextStyle(
                  color: AppTheme.primaryMaroon,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...activities.map((activity) => _buildActivityTile(activity)),
      ],
    );
  }

  Widget _buildActivityTile(GiftActivity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundImage: NetworkImage(activity.userImage),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    activity.giftEmoji,
                    style: const TextStyle(fontSize: 12),
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
                Row(
                  children: [
                    Text(
                      activity.isReceived ? 'From ' : 'To ',
                      style: const TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      activity.userName,
                      style: const TextStyle(
                        color: Color(0xFF2C2C2E),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  activity.message,
                  style: const TextStyle(
                    color: Color(0xFF555555),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            activity.time,
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
