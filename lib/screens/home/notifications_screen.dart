import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/auth_service.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final AuthService _auth = AuthService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final res = await _auth.getNotifications();
      setState(() {
        _notifications = res;
        _isLoading = false;
      });
      _markAllAsRead();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _markAllAsRead() async {
    for (var n in _notifications) {
      if (!(n['is_read'] ?? false)) {
        await _auth.markNotificationAsRead(n['id']);
      }
    }
  }

  String _getTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return DateFormat('MMM d, yyyy').format(dt);
  }

  String _getEmoji(String type) {
    switch (type) {
      case 'like': return '❤️';
      case 'match': return '🔥';
      case 'message': return '💬';
      case 'gift': return '🎁';
      default: return '✨';
    }
  }

  Color _getIconBg(String type) {
    switch (type) {
      case 'like': return const Color(0xFFFDECEC);
      case 'match': return const Color(0xFFE5E6FF);
      case 'gift': return const Color(0xFFFFF9C4);
      default: return const Color(0xFFF0F0F0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryMaroon),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifications', style: TextStyle(color: Color(0xFF2C2C2E), fontWeight: FontWeight.w800, fontSize: 20)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty 
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final item = _notifications[index];
                  final createdAt = DateTime.parse(item['created_at']);
                  final profile = item['profiles'];
                  final actorName = profile?['full_name'] ?? 'Someone';
                  final actorAvatar = profile?['avatar_url'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
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
                        _buildActorImage(actorAvatar, _getEmoji(item['type']), _getIconBg(item['type'])),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['content'] ?? 'New notification',
                                style: const TextStyle(color: Color(0xFF2C2C2E), fontWeight: FontWeight.w700, fontSize: 15, height: 1.3),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _getTimeAgo(createdAt),
                                style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        if (!(item['is_read'] ?? false))
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF9D4C5E), shape: BoxShape.circle)),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildActorImage(String? url, String emoji, Color bg) {
    if (url != null) {
      return Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
        ),
      );
    }
    return Container(
      width: 52, height: 52,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No notifications yet', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
