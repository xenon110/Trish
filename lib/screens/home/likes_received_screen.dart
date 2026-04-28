import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/auth_service.dart';
import '../../models/user_profile.dart';
import 'interaction_chat_screen.dart';

class LikesReceivedScreen extends StatefulWidget {
  const LikesReceivedScreen({super.key});

  @override
  State<LikesReceivedScreen> createState() => _LikesReceivedScreenState();
}

class _LikesReceivedScreenState extends State<LikesReceivedScreen> {
  final AuthService _auth = AuthService();
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _likes = [];
  bool _isLoading = true;
  RealtimeChannel? _channel;
  static const _maroon = AppTheme.primaryMaroon;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  void _subscribeRealtime() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    _channel = _supabase
        .channel('likes_list_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'likes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'liked_id',
            value: userId,
          ),
          callback: (_) => _load(),
        )
        .subscribe();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await _auth.getLikesReceived();
      setState(() { _likes = data; _isLoading = false; });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F0EB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text('People Who Liked You', style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w800, fontSize: 17)),
            if (!_isLoading)
              Text('${_likes.length} like${_likes.length == 1 ? '' : 's'}', style: const TextStyle(color: _maroon, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _maroon))
          : _likes.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _maroon,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _likes.length,
                    itemBuilder: (_, i) {
                      final item = _likes[i];
                      final profile = item['profiles'] as Map? ?? {};
                      
                      // Skip if profiles is empty AND we don't even have a liker_id (unlikely)
                      final likerId = (item['liker_id'] ?? profile['id'] ?? '') as String;
                      if (likerId.isEmpty) return const SizedBox.shrink();

                      // If we have profile info, check if blocked
                      if (profile['is_blocked'] == true) return const SizedBox.shrink();

                      return _LikerCard(
                        likerId: likerId,
                        profile: profile,
                        auth: _auth,
                        onAction: _load,
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 100, height: 100,
          decoration: const BoxDecoration(color: Color(0xFFFDECEC), shape: BoxShape.circle),
          child: const Icon(Icons.favorite_rounded, color: _maroon, size: 48),
        ),
        const SizedBox(height: 24),
        const Text('No likes yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
        const SizedBox(height: 8),
        const Text('When someone likes your profile,\nthey\'ll appear here.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Color(0xFF8A8A8A), height: 1.5)),
      ]),
    );
  }
}

// ── Individual liker card ────────────────────────────────────────

class _LikerCard extends StatefulWidget {
  final String likerId;
  final Map profile;
  final AuthService auth;
  final VoidCallback onAction;

  const _LikerCard({required this.likerId, required this.profile, required this.auth, required this.onAction});

  @override
  State<_LikerCard> createState() => _LikerCardState();
}

class _LikerCardState extends State<_LikerCard> {
  bool _isActing = false;
  static const _maroon = AppTheme.primaryMaroon;

  void _viewProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProfilePreviewSheet(
        profile: widget.profile,
        likerId: widget.likerId,
        auth: widget.auth,
        onLiked: (matchId) async {
          Navigator.pop(ctx);
          widget.onAction();
          if (matchId != null && mounted) {
            _showMatchPopup(matchId);
          }
        },
        onDisliked: () {
          Navigator.pop(ctx);
          widget.onAction();
        },
      ),
    );
  }

  void _showMatchPopup(String matchId) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(color: Color(0xFFFDECEC), shape: BoxShape.circle),
              child: const Icon(Icons.favorite_rounded, color: _maroon, size: 40),
            ),
            const SizedBox(height: 20),
            const Text("It's a Match! 🎉", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
            const SizedBox(height: 8),
            Text(
              'You and ${widget.profile['full_name']?.toString().split(' ').first ?? 'them'} liked each other!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Color(0xFF666666), height: 1.4),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  // Navigate to Chat
                  final targetProfile = UserProfile.fromJson(Map<String, dynamic>.from(widget.profile));
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InteractionChatScreen(
                        matchId: matchId,
                        targetProfile: targetProfile,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _maroon,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Start Chatting', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Maybe later', style: TextStyle(color: Color(0xFF9E9E9E))),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawName = (widget.profile['full_name'] ?? '') as String;
    final likerIdShort = widget.likerId.length > 8 ? 'User ${widget.likerId.substring(0, 8)}' : 'User ${widget.likerId}';
    final name = rawName.isNotEmpty ? rawName : likerIdShort;
    final firstName = name.split(' ').first;
    final age = widget.profile['age'];
    final location = (widget.profile['location'] ?? '') as String;
    final avatarUrl = widget.profile['avatar_url'];
    final job = (widget.profile['job'] ?? '') as String;

    return GestureDetector(
      onTap: _viewProfile,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          // Photo
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(22)),
            child: SizedBox(
              width: 100, height: 110,
              child: avatarUrl != null
                  ? Image.network(avatarUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.person, size: 40, color: Colors.grey)))
                  : Container(color: const Color(0xFFFDECEC), child: const Icon(Icons.person, size: 40, color: _maroon)),
            ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(firstName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                  if (age != null) ...[
                    const SizedBox(width: 6),
                    Text(age.toString(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: Color(0xFF8A8A8A))),
                  ],
                ]),
                if (job.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(job, style: const TextStyle(fontSize: 13, color: Color(0xFF666666), fontWeight: FontWeight.w500)),
                ],
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFFAAAAAA)),
                    const SizedBox(width: 3),
                    Text(location, style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA))),
                  ]),
                ],
              ]),
            ),
          ),
          // Quick actions
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: _isActing
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: _maroon))
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    // Dislike
                    GestureDetector(
                      onTap: () async {
                        setState(() => _isActing = true);
                        await widget.auth.dislikeUser(widget.likerId);
                        widget.onAction();
                      },
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: const Color(0xFFF5F5F5), shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, color: Color(0xFFAAAAAA), size: 22),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Like
                    GestureDetector(
                      onTap: () async {
                        setState(() => _isActing = true);
                        final matchId = await widget.auth.likeUser(widget.likerId);
                        if (mounted) setState(() => _isActing = false);
                        widget.onAction();
                        if (matchId != null && mounted) _showMatchPopup(matchId);
                      },
                      child: Container(
                        width: 40, height: 40,
                        decoration: const BoxDecoration(color: Color(0xFFFDECEC), shape: BoxShape.circle),
                        child: const Icon(Icons.favorite_rounded, color: _maroon, size: 22),
                      ),
                    ),
                  ]),
          ),
        ]),
      ),
    );
  }
}

// ── Profile Preview Bottom Sheet ─────────────────────────────────

class _ProfilePreviewSheet extends StatelessWidget {
  final Map profile;
  final String likerId;
  final AuthService auth;
  final Function(String? matchId) onLiked;
  final VoidCallback onDisliked;

  static const _maroon = AppTheme.primaryMaroon;

  const _ProfilePreviewSheet({
    required this.profile,
    required this.likerId,
    required this.auth,
    required this.onLiked,
    required this.onDisliked,
  });

  @override
  Widget build(BuildContext context) {
    final name = (profile['full_name'] ?? 'Unknown') as String;
    final age = profile['age'];
    final location = (profile['location'] ?? '') as String;
    final avatarUrl = profile['avatar_url'];
    final bio = (profile['bio'] ?? '') as String;
    final job = (profile['job'] ?? '') as String;

    List<String> interests = [];
    if (profile['interests'] is List) {
      interests = List<String>.from(profile['interests']);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(children: [
          // Handle
          const SizedBox(height: 12),
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)))),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              controller: sc,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Photo
                Stack(children: [
                  avatarUrl != null
                      ? Image.network(avatarUrl, height: 340, width: double.infinity, fit: BoxFit.cover)
                      : Container(
                          height: 340, width: double.infinity,
                          color: const Color(0xFFFDECEC),
                          child: const Icon(Icons.person, size: 80, color: _maroon),
                        ),
                  // Name overlay
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.72)],
                        ),
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(name.split(' ').first, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                        if (age != null) ...[
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(age.toString(), style: const TextStyle(color: Colors.white70, fontSize: 22, fontWeight: FontWeight.w300)),
                          ),
                        ],
                      ]),
                    ),
                  ),
                ]),

                // Details
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (job.isNotEmpty || location.isNotEmpty)
                      Row(children: [
                        if (job.isNotEmpty) ...[const Icon(Icons.work_outline_rounded, size: 15, color: Color(0xFFAAAAAA)), const SizedBox(width: 5), Text(job, style: const TextStyle(fontSize: 14, color: Color(0xFF666666)))],
                        if (job.isNotEmpty && location.isNotEmpty) const Text('  ·  ', style: TextStyle(color: Color(0xFFCCCCCC))),
                        if (location.isNotEmpty) ...[const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFFAAAAAA)), const SizedBox(width: 3), Text(location, style: const TextStyle(fontSize: 14, color: Color(0xFF666666)))],
                      ]),
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(bio, style: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF444444))),
                    ],
                    if (interests.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text('Interests', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF8A8A8A), letterSpacing: 0.5)),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 8, children: interests.take(8).map((i) =>
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(color: const Color(0xFFFDECEC), borderRadius: BorderRadius.circular(50)),
                          child: Text(i, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _maroon)),
                        )
                      ).toList()),
                    ],
                    const SizedBox(height: 100), // space for buttons
                  ]),
                ),
              ]),
            ),
          ),

          // Action buttons — fixed at bottom
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -4))],
            ),
            child: Row(children: [
              // Dislike
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await auth.dislikeUser(likerId);
                    onDisliked();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(18)),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.close_rounded, color: Color(0xFF8A8A8A), size: 22),
                      SizedBox(width: 8),
                      Text('Pass', style: TextStyle(color: Color(0xFF8A8A8A), fontWeight: FontWeight.w700, fontSize: 15)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Like
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () async {
                    final matchId = await auth.likeUser(likerId);
                    onLiked(matchId);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFB0506A), Color(0xFFD4788A)], begin: Alignment.centerLeft, end: Alignment.centerRight),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: _maroon.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6))],
                    ),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.favorite_rounded, color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text('Like Back', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
