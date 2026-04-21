import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';

class MyGiftsScreen extends StatelessWidget {
  const MyGiftsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
            'My Gifts',
            style: TextStyle(
              color: Color(0xFF2C2C2E),
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            indicator: BoxDecoration(
              color: AppTheme.primaryMaroon,
              borderRadius: BorderRadius.circular(24),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFF8E8E93),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Received'),
              Tab(text: 'Sent'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ReceivedGiftsView(),
            _SentGiftsView(),
          ],
        ),
      ),
    );
  }
}

class _ReceivedGiftsView extends StatelessWidget {
  const _ReceivedGiftsView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildActivityItem('🌹 Rose', 'From Ankit', '2 min ago', isPositive: true),
        _buildActivityItem('🎁 Teddy', 'From Priya', '1 hr ago', isPositive: true),
        _buildActivityItem('🍫 Chocolate', 'From Rahul', 'Yesterday', isPositive: true),
      ],
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String time, {bool isPositive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFFDECEC),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_rounded, color: Color(0xFF9D4C5E), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Color(0xFF2C2C2E), fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SentGiftsView extends StatelessWidget {
  const _SentGiftsView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildActivityItem('💎 Diamond', 'To Sarah', 'Yesterday'),
        _buildActivityItem('☕ Coffee', 'To Mike', 'Oct 12, 2023'),
      ],
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFF2F2F7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.send_rounded, color: Color(0xFF2C2C2E), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Color(0xFF2C2C2E), fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
