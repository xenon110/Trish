import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/auth_service.dart';

class GlobalMomentsScreen extends StatefulWidget {
  const GlobalMomentsScreen({super.key});

  @override
  State<GlobalMomentsScreen> createState() => _GlobalMomentsScreenState();
}

class _GlobalMomentsScreenState extends State<GlobalMomentsScreen> {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _moments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await _authService.getPublicMoments();
      debugPrint('DEBUG: Loaded ${data.length} public moments');
      setState(() {
        _moments = data..shuffle();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('TRISH Reels', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _moments.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.primaryMaroon,
                  child: PageView.builder(
                    scrollDirection: Axis.vertical,
                    itemCount: _moments.length,
                    itemBuilder: (context, index) => _buildItem(_moments[index]),
                  ),
                ),
    );
  }

  Widget _buildItem(Map<String, dynamic> m) {
    final profile = m['profiles'] as Map? ?? {};
    final name = profile['full_name'] ?? 'Someone';
    final avatar = profile['avatar_url'];
    final location = profile['location'];
    final imageUrl = m['image_url'] as String;
    final caption = (m['caption'] ?? '').toString();

    return Stack(
      fit: StackFit.expand,
      children: [
        // Photo
        Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey[900],
            child: const Icon(Icons.broken_image, color: Colors.white54, size: 64),
          ),
        ),

        // Gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.35),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.85),
              ],
              stops: const [0.0, 0.2, 0.65, 1.0],
            ),
          ),
        ),

        // Bottom info
        Positioned(
          left: 20, right: 20, bottom: 50,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Left: user info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                        backgroundColor: Colors.white24,
                        child: avatar == null ? const Icon(Icons.person, color: Colors.white, size: 20) : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                          if (location != null && location.isNotEmpty)
                            Row(children: [
                              const Icon(Icons.location_on_rounded, color: Colors.white60, size: 13),
                              const SizedBox(width: 3),
                              Text(location, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                            ]),
                        ],
                      ),
                    ]),
                    if (caption.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(caption, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
                    ],
                  ],
                ),
              ),

              // Right: action buttons
              Column(children: [
                _actionBtn(Icons.favorite_rounded, 'Like', Colors.pinkAccent, () {}),
                const SizedBox(height: 20),
                _actionBtn(Icons.chat_bubble_rounded, 'Say Hi', Colors.blueAccent, () {}),
              ]),
            ],
          ),
        ),

        // Scroll hint at bottom
        const Positioned(
          bottom: 16, left: 0, right: 0,
          child: Center(
            child: Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white38, size: 28),
          ),
        ),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.auto_awesome_motion_rounded, color: Colors.white24, size: 80),
        const SizedBox(height: 24),
        const Text('No public moments yet', style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('Share a photo publicly from your Moments tab!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 14)),
      ]),
    );
  }
}
