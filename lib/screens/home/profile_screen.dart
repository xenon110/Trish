import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import 'settings_screen.dart';
import '../auth/login_screen.dart';
import 'main_navigation_screen.dart';
import 'my_wallet_screen.dart';
import 'edit_profile_screen.dart';
import 'moments_screen.dart';
import 'likes_received_screen.dart';
import '../../core/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _myMoments = [];
  int _likeCount = 0;
  RealtimeChannel? _likesChannel;
  static const _maroon = AppTheme.primaryMaroon;

  @override
  void initState() {
    super.initState();
    _loadMoments();
    _subscribeToLikes();
  }

  @override
  void dispose() {
    _likesChannel?.unsubscribe();
    super.dispose();
  }

  /// Subscribe to realtime inserts/deletes on the likes table
  /// so the badge count updates instantly without polling.
  void _subscribeToLikes() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Initial load
    _refreshLikeCount(userId);

    // Realtime channel
    _likesChannel = _supabase
        .channel('likes_for_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'likes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'liked_id',
            value: userId,
          ),
          callback: (_) => _refreshLikeCount(userId),
        )
        .subscribe();
  }

  Future<void> _refreshLikeCount(String userId) async {
    try {
      final res = await _supabase
          .from('likes')
          .select('id')
          .eq('liked_id', userId);
      if (mounted) setState(() => _likeCount = (res as List).length);
    } catch (_) {}
  }

  Future<void> _loadMoments() async {
    try {
      final all = await _authService.getMyMoments();
      if (mounted) setState(() => _myMoments = all);
    } catch (_) {}
  }

  void _goEdit() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final meta = _authService.currentUser?.userMetadata ?? {};
    final fullName = meta['full_name'] ?? 'Your Name';
    final firstName = fullName.split(' ').first;
    final bio = meta['bio'] ?? '';
    final age = meta['age'];
    final location = meta['location'] ?? '';
    final gender = meta['gender'] ?? '';
    final avatarUrl = meta['avatar_url'];
    final job = meta['job'] ?? '';
    final education = meta['education'] ?? '';
    final relationshipType = meta['relationship_type'] ?? '';
    final zodiac = meta['zodiac'] ?? '';
    final religion = meta['religion'] ?? '';
    final hometown = meta['hometown'] ?? '';
    final height = meta['height']?.toString() ?? '';
    final exercise = meta['exercise'] ?? '';
    final drinking = meta['drinking'] ?? '';
    final smoking = meta['smoking'] ?? '';
    final wantKids = meta['want_kids'] ?? '';
    final haveKids = meta['have_kids'] ?? '';
    final politics = meta['politics'] ?? '';
    final interestedIn = meta['interested_in'] ?? '';
    final promptsList = meta['prompts'] as List? ?? [];

    List<String> interests = [];
    if (meta['interests'] is List) {
      interests = List<String>.from(meta['interests'])
          .map((s) => s.replaceAll(RegExp(r'[\u{1F300}-\u{1FAFF}\s]+', unicode: true), '').trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (interests.isEmpty) interests = List<String>.from(meta['interests']);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F0EB),
      body: CustomScrollView(
        slivers: [

          // ── Hero ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 290,
            pinned: true,
            stretch: false,
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            actions: [
              _appBarBtn(Icons.edit_rounded, _goEdit),
              _appBarBtn(Icons.settings_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Photo
                  avatarUrl != null
                      ? Image.network(avatarUrl, fit: BoxFit.cover)
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF9B3A52), Color(0xFFD97085)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(child: Icon(Icons.person_rounded, size: 80, color: Colors.white30)),
                        ),
                  // Bottom gradient
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.transparent, Colors.black.withOpacity(0.72)],
                          stops: const [0, 0.45, 1],
                        ),
                      ),
                    ),
                  ),
                  // Name / info
                  Positioned(
                    left: 16, right: 16, bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              firstName,
                              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                            ),
                            if (age != null) ...[
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(age.toString(), style: const TextStyle(color: Colors.white70, fontSize: 20, fontWeight: FontWeight.w300)),
                              ),
                            ],
                          ],
                        ),
                        if (job.isNotEmpty || location.isNotEmpty || hometown.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (job.isNotEmpty) job, 
                              if (location.isNotEmpty) location,
                              if (hometown.isNotEmpty && location != hometown) 'from $hometown'
                            ].join(' · '),
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                        const SizedBox(height: 10),
                        // Action buttons row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(children: [
                            _heroBtn(Icons.edit_rounded, 'Edit Profile', _goEdit),
                            const SizedBox(width: 8),
                            _heroBtn(Icons.photo_library_rounded, 'Moments', () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const MomentsScreen()));
                              _loadMoments();
                            }),
                            const SizedBox(width: 8),
                            _heroBtn(Icons.share_rounded, 'Share', () {}),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────────────
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 20),

              // About
              _section(
                title: 'About Me',
                onAdd: _goEdit,
                child: bio.isNotEmpty
                    ? Text(bio, style: const TextStyle(fontSize: 15, height: 1.7, color: Color(0xFF444444), fontWeight: FontWeight.w400))
                    : _emptyHint('Add a bio to introduce yourself'),
              ),

              // Basics
              if (gender.isNotEmpty || zodiac.isNotEmpty || relationshipType.isNotEmpty || interestedIn.isNotEmpty || religion.isNotEmpty || height.isNotEmpty || wantKids.isNotEmpty || haveKids.isNotEmpty || politics.isNotEmpty || hometown.isNotEmpty)
                _section(
                  title: 'Basics',
                  onAdd: _goEdit,
                  child: Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      if (gender.isNotEmpty) _basicPill(gender),
                      if (height.isNotEmpty) _basicPill('$height cm'),
                      if (zodiac.isNotEmpty) _basicPill(zodiac),
                      if (relationshipType.isNotEmpty) _basicPill(relationshipType),
                      if (interestedIn.isNotEmpty) _basicPill('Interested in $interestedIn'),
                      if (religion.isNotEmpty) _basicPill(religion),
                      if (politics.isNotEmpty) _basicPill(politics),
                      if (hometown.isNotEmpty) _basicPill('From $hometown'),
                      if (wantKids.isNotEmpty) _basicPill(wantKids),
                      if (haveKids.isNotEmpty) _basicPill(haveKids.contains('Yes') ? 'Has children' : 'No children'),
                    ],
                  ),
                ),

              // Interests
              _section(
                title: 'Interests',
                onAdd: _goEdit,
                child: interests.isEmpty
                    ? _emptyHint('Add interests to match better')
                    : Wrap(
                        spacing: 8, runSpacing: 10,
                        children: interests.map((i) => _interestChip(i)).toList(),
                      ),
              ),

              // Prompts
              if (promptsList.isNotEmpty)
                ...promptsList
                    .where((p) => (p['answer'] ?? '').toString().isNotEmpty)
                    .map((p) => _promptCard(p['question'] ?? '', p['answer'] ?? '')),

              // Career
              _section(
                title: 'Career & Education',
                onAdd: _goEdit,
                child: (job.isEmpty && education.isEmpty)
                    ? _emptyHint('Add your job and school')
                    : Column(
                        children: [
                          if (job.isNotEmpty) _infoTile(Icons.work_outline_rounded, 'Job', job),
                          if (job.isNotEmpty && education.isNotEmpty) const SizedBox(height: 10),
                          if (education.isNotEmpty) _infoTile(Icons.school_outlined, 'Education', education),
                        ],
                      ),
              ),

              // Lifestyle
              if (drinking.isNotEmpty || smoking.isNotEmpty || exercise.isNotEmpty)
                _section(
                  title: 'Lifestyle',
                  onAdd: _goEdit,
                  child: Row(
                    children: [
                      if (drinking.isNotEmpty)
                        Expanded(child: _lifestyleTile('Drinking', drinking)),
                      if (smoking.isNotEmpty)
                        Expanded(child: _lifestyleTile('Smoking', smoking)),
                      if (exercise.isNotEmpty)
                        Expanded(child: _lifestyleTile('Exercise', exercise)),
                    ],
                  ),
                ),

              // Moments
              _section(
                title: 'My Moments',
                onAdd: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const MomentsScreen()));
                  _loadMoments();
                },
                child: _myMoments.isEmpty
                    ? _emptyHint('Share your first photo moment')
                    : SizedBox(
                        height: 220,
                        child: GridView.builder(
                          scrollDirection: Axis.horizontal,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                          itemCount: _myMoments.length,
                          itemBuilder: (_, i) {
                            final m = _myMoments[i];
                            final isPublic = m['visibility'] == 'public';
                            return Stack(fit: StackFit.expand, children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(m['image_url'], fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(color: Colors.grey[200])),
                              ),
                              Positioned(
                                top: 6, right: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isPublic ? 'Public' : 'Private',
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ]);
                          },
                        ),
                      ),
              ),

              // Menu Row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                child: Row(children: [
                  _menuTile(Icons.account_balance_wallet_outlined, 'Wallet', const Color(0xFF5B7BFE), 0, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MyWalletScreen()));
                  }),
                  const SizedBox(width: 10),
                  _menuTile(Icons.favorite_outline_rounded, 'Likes', const Color(0xFFFF5F7E), _likeCount, () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const LikesReceivedScreen()));
                    final uid = _supabase.auth.currentUser?.id;
                    if (uid != null) _refreshLikeCount(uid);
                  }),
                  const SizedBox(width: 10),
                  _menuTile(Icons.card_giftcard_outlined, 'Gifts', const Color(0xFFFF9F43), 0, () {}),
                  const SizedBox(width: 10),
                  _menuTile(Icons.settings_outlined, 'Settings', const Color(0xFF26C6DA), 0, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  }),
                ]),
              ),

              // Logout
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
                child: GestureDetector(
                  onTap: () async {
                    await _authService.signOut();
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDECEC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded, color: Color(0xFFC0392B), size: 18),
                        SizedBox(width: 8),
                        Text('Log Out', style: TextStyle(color: Color(0xFFC0392B), fontWeight: FontWeight.w700, fontSize: 15)),
                      ],
                    ),
                  ),
                ),
              ),

            ]),
          ),
        ],
      ),
    );
  }

  // ── Section card ──────────────────────────────────────────────

  Widget _section({required String title, required Widget child, required VoidCallback onAdd}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
            child: Row(
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                const Spacer(),
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDECEC),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_rounded, color: _maroon, size: 16),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: child,
          ),
        ],
      ),
    );
  }

  // ── Small widgets ────────────────────────────────────────────

  Widget _emptyHint(String text) {
    return Row(children: [
      const Icon(Icons.add_circle_outline_rounded, size: 16, color: Color(0xFFCCCCCC)),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 14, fontWeight: FontWeight.w400)),
    ]);
  }

  Widget _basicPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF444444))),
    );
  }

  Widget _interestChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _maroon)),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4F2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: const Color(0xFFAAAAAA)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFAAAAAA))),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
        ]),
      ]),
    );
  }

  Widget _lifestyleTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4F2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFAAAAAA))),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
      ]),
    );
  }

  Widget _promptCard(String question, String answer) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          decoration: const BoxDecoration(
            color: Color(0xFFFDECEC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Text(question, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _maroon)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Text(answer, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF222222), height: 1.5)),
        ),
      ]),
    );
  }

  Widget _menuTile(IconData icon, String label, Color color, [int badge = 0, VoidCallback? onTap]) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (badge > 0)
                  Positioned(
                    top: -4, right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: _maroon, borderRadius: BorderRadius.circular(10)),
                      child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 7),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
          ]),
        ),
      ),
    );
  }

  Widget _heroBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: Colors.white38),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _appBarBtn(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF444444), size: 20),
        onPressed: onTap,
      ),
    );
  }
}
