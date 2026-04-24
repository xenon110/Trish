
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/auth_service.dart';
import '../../models/user_profile.dart';
import '../../models/moment.dart';
import '../../core/ui_helpers.dart';
import 'interaction_chat_screen.dart';

class GlobalMomentsScreen extends StatefulWidget {
  const GlobalMomentsScreen({super.key});

  @override
  State<GlobalMomentsScreen> createState() => _GlobalMomentsScreenState();
}

class _GlobalMomentsScreenState extends State<GlobalMomentsScreen> {
  final AuthService _authService = AuthService();
  List<Moment> _moments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllMoments();
  }

  Future<void> _loadAllMoments() async {
    setState(() => _isLoading = true);
    try {
      final profiles = await _authService.getProfiles();
      final List<Moment> allMoments = [];
      
      for (var profile in profiles) {
        for (var momentUrl in profile.moments) {
          allMoments.add(Moment(
            imageUrl: momentUrl,
            userId: profile.id,
            userName: profile.fullName,
            userAvatar: profile.avatarUrl,
            location: profile.location,
            createdAt: profile.locationUpdatedAt ?? DateTime.now(),
          ));
        }
      }
      
      // Shuffle for discovery feel
      allMoments.shuffle();
      
      setState(() {
        _moments = allMoments;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        UIHelpers.showSnackBar(context, 'Error loading moments: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Moments',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _moments.isEmpty
              ? _buildEmptyState()
              : PageView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: _moments.length,
                  itemBuilder: (context, index) {
                    return _buildMomentItem(_moments[index]);
                  },
                ),
    );
  }

  Widget _buildMomentItem(Moment moment) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Image
        Image.network(
          moment.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[900],
            child: const Icon(Icons.broken_image, color: Colors.white54, size: 64),
          ),
        ),
        
        // Gradient Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
                stops: const [0.0, 0.2, 0.7, 1.0],
              ),
            ),
          ),
        ),
        
        // User Info & Actions
        Positioned(
          left: 16,
          right: 16,
          bottom: 40,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: moment.userAvatar != null
                              ? NetworkImage(moment.userAvatar!)
                              : null,
                          child: moment.userAvatar == null
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              moment.userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (moment.location != null)
                              Text(
                                moment.location!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Caught a beautiful moment! ✨',
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ],
                ),
              ),
              
              // Action Buttons
              Column(
                children: [
                  _buildActionButton(
                    icon: Icons.favorite_rounded,
                    label: 'Like',
                    color: Colors.redAccent,
                    onTap: () => UIHelpers.showSnackBar(context, 'You liked this moment!'),
                  ),
                  const SizedBox(height: 20),
                  _buildActionButton(
                    icon: Icons.chat_bubble_rounded,
                    label: 'Say Hi',
                    color: Colors.blueAccent,
                    onTap: () {
                      // Navigate to chat (mock for now as we need a real match/interaction)
                      UIHelpers.showSnackBar(context, 'Opening chat with ${moment.userName}...');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome_motion_rounded, color: Colors.white24, size: 80),
          const SizedBox(height: 24),
          const Text(
            'No moments yet',
            style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Be the first to share a moment!',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
