
import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../core/theme.dart';
import 'interaction_chat_screen.dart';

class MatchFoundOverlay extends StatelessWidget {
  final UserProfile matchedProfile;
  final String currentUserAvatar;
  final String matchId;

  const MatchFoundOverlay({
    super.key,
    required this.matchedProfile,
    required this.currentUserAvatar,
    required this.matchId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Headline
              const Text(
                "It's a Match!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "You and ${matchedProfile.fullName} liked each other",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 48),

              // Avatars Row
              Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildAvatar(currentUserAvatar),
                      const SizedBox(width: 20),
                      _buildAvatar(matchedProfile.avatarUrl ?? ''),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFFE56A7C),
                      size: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 64),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to chat
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InteractionChatScreen(
                          matchId: matchId,
                          targetProfile: matchedProfile,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryMaroon,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "Send a Message",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Keep Swiping",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String url) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        image: DecorationImage(
          image: url.startsWith('http')
              ? NetworkImage(url)
              : const AssetImage('assets/image/connection.jpg') as ImageProvider,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
