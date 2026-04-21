import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import 'gift_details_screen.dart';

class ReceivedGiftModel {
  final String senderName;
  final String senderImage;
  final String giftEmoji;
  final String giftName;
  final String message;
  final String time;
  final int amount;

  ReceivedGiftModel({
    required this.senderName,
    required this.senderImage,
    required this.giftEmoji,
    required this.giftName,
    required this.message,
    required this.time,
    required this.amount,
  });
}

class ReceivedGiftsScreen extends StatefulWidget {
  const ReceivedGiftsScreen({super.key});

  @override
  State<ReceivedGiftsScreen> createState() => _ReceivedGiftsScreenState();
}

class _ReceivedGiftsScreenState extends State<ReceivedGiftsScreen> {
  final List<ReceivedGiftModel> _receivedGifts = [
    ReceivedGiftModel(
      senderName: 'Ankit',
      senderImage: AppConstants.defaultAvatar2,
      giftEmoji: '🌹',
      giftName: 'Rose',
      message: 'Happy Valentine\'s Day!',
      time: '2 min ago',
      amount: 10,
    ),
    ReceivedGiftModel(
      senderName: 'Priya',
      senderImage: AppConstants.defaultAvatar3,
      giftEmoji: '🎁',
      giftName: 'Gift',
      message: 'Just a little something for you.',
      time: '1 hr ago',
      amount: 50,
    ),
    ReceivedGiftModel(
      senderName: 'Rahul',
      senderImage: AppConstants.defaultAvatar2,
      giftEmoji: '🍫',
      giftName: 'Chocolate',
      message: 'Hope you like dark chocolate!',
      time: 'Yesterday',
      amount: 20,
    ),
    ReceivedGiftModel(
      senderName: 'Sarah',
      senderImage: AppConstants.defaultAvatar3,
      giftEmoji: '💎',
      giftName: 'Diamond',
      message: 'You deserve the best.',
      time: 'Last Week',
      amount: 100,
    ),
  ];

  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryMaroon),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Text(
          'Received Gifts',
          style: TextStyle(
            color: Color(0xFF2C2C2E),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildSummaryBox(),
            ),
            _buildFilters(),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: _receivedGifts.length,
                itemBuilder: (context, index) {
                  return _buildGiftItem(_receivedGifts[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBox() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryMaroon,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryMaroon.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              const Text(
                'Total Received',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_receivedGifts.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Container(
            width: 1.5,
            height: 50,
            color: Colors.white24,
          ),
          Column(
            children: [
              const Text(
                'Value Earned',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '₹180',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final filters = ['All', 'Today', 'This Week'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2C2C2E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF2C2C2E) : const Color(0xFFEBEBEB),
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF8E8E93),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGiftItem(ReceivedGiftModel gift) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GiftDetailsScreen(gift: gift),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundImage: NetworkImage(gift.senderImage),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: Color(0xFF2C2C2E),
                            fontSize: 15,
                          ),
                          children: [
                            TextSpan(
                              text: '${gift.senderName} ',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const TextSpan(
                              text: 'sent you ',
                              style: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF8E8E93)),
                            ),
                            TextSpan(
                              text: '${gift.giftEmoji} ${gift.giftName}',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${gift.amount}',
                        style: const TextStyle(
                          color: Color(0xFF34C759),
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (gift.message.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        gift.message,
                        style: const TextStyle(
                          color: Color(0xFF6B6B6B),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    gift.time,
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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
}
