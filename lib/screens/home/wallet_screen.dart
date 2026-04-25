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

  Widget _buildBalanceCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryMaroon, const Color(0xFF5D242E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryMaroon.withOpacity(0.4),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative rings
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.1), width: 20),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL GIFT BALANCE',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD700), size: 14),
                        SizedBox(width: 4),
                        Text('Premium', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '₹',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '1,245.50',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              Row(
                children: [
                  Expanded(
                    child: _buildPrimaryButton(
                      context,
                      'Send Gift',
                      Icons.card_giftcard,
                      Colors.white,
                      AppTheme.primaryMaroon,
                      () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AddGiftScreen()));
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPrimaryButton(
                      context,
                      'Received',
                      Icons.mark_email_read_outlined,
                      Colors.white.withOpacity(0.15),
                      Colors.white,
                      () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const GiftHistoryScreen()));
                      },
                    ),
                  ),
                ],
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionOptions(BuildContext context) {
    return Column(
      children: [
        _buildActionCard(
          context,
          'Add New Gift',
          Icons.add_rounded,
          const Color(0xFFFDECEC),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddGiftScreen())),
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          context,
          'Gift History',
          Icons.history_rounded,
          const Color(0xFFFDECEC),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GiftHistoryScreen())),
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, String label, IconData icon, Color iconBgColor, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () => UIHelpers.showFeatureComingSoon(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFF2F2F7), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primaryMaroon, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF2C2C2E),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFD1D1D6), size: 16),
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
        margin: const EdgeInsets.only(right: 16, bottom: 20, top: 10),
        width: 140,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryMaroon.withOpacity(0.08),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFDF0F2),
                shape: BoxShape.circle,
              ),
              child: Text(gift.emoji, style: const TextStyle(fontSize: 36)),
            ),
            const SizedBox(height: 16),
            Text(
              gift.name,
              style: const TextStyle(
                color: Color(0xFF2C2C2E),
                fontSize: 16,
                fontWeight: FontWeight.w800,
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 12),
                      const SizedBox(width: 2),
                      Text(
                        gift.rating.toString(),
                        style: const TextStyle(
                          color: Color(0xFFD49A00),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
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
