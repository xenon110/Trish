import 'package:flutter/material.dart';
import '../../core/theme.dart';

class NotificationItem {
  final String message;
  final String timestamp;
  final String emoji;
  final Color iconBg;

  NotificationItem({
    required this.message,
    required this.timestamp,
    required this.emoji,
    required this.iconBg,
  });
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<NotificationItem> notifications = [
      NotificationItem(
        message: 'You received a 🌹 Rose from Ankit',
        timestamp: '2 min ago',
        emoji: '🌹',
        iconBg: const Color(0xFFFDECEC),
      ),
      NotificationItem(
        message: 'Priya sent you a 🎁 Gift',
        timestamp: '1 hr ago',
        emoji: '🎁',
        iconBg: const Color(0xFFE5E6FF),
      ),
      NotificationItem(
        message: 'Your balance has been updated',
        timestamp: 'Yesterday',
        emoji: '💳',
        iconBg: const Color(0xFFE8F5E9),
      ),
      NotificationItem(
        message: 'New top gifts available',
        timestamp: 'Oct 12, 2023',
        emoji: '✨',
        iconBg: const Color(0xFFFFF9C4),
      ),
    ];

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
          'Notifications',
          style: TextStyle(
            color: Color(0xFF2C2C2E),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final item = notifications[index];
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
                    decoration: BoxDecoration(
                      color: item.iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        item.emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.message,
                          style: const TextStyle(
                            color: Color(0xFF2C2C2E),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.timestamp,
                          style: const TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
