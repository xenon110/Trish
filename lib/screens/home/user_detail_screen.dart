import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import 'match_found_overlay.dart';

class UserDetailScreen extends StatefulWidget {
  final UserProfile profile;

  const UserDetailScreen({super.key, required this.profile});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  static const _maroon = AppTheme.primaryMaroon;

  void _handleSwipe(bool isLike) {
    Navigator.pop(context, isLike);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final firstName = p.fullName.split(' ').first;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F0EB),
      body: CustomScrollView(
        slivers: [
          // ── Hero Image ───────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 450,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  p.avatarUrl != null
                      ? Image.network(p.avatarUrl!, fit: BoxFit.cover)
                      : Container(color: _maroon.withOpacity(0.1), child: const Icon(Icons.person, size: 100, color: _maroon)),
                  // Bottom gradient
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.transparent, Colors.black.withOpacity(0.8)],
                          stops: const [0, 0.6, 1],
                        ),
                      ),
                    ),
                  ),
                  // Name Overlay
                  Positioned(
                    left: 24, right: 24, bottom: 32,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${p.fullName}, ${p.age}',
                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                            ),
                            if (p.isVerified) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.verified, color: Colors.blueAccent, size: 24),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white70, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              [
                                p.location, 
                                if (p.hometown != null && p.hometown!.isNotEmpty && p.location != p.hometown) 'from ${p.hometown}'
                              ].join(' · '), 
                              style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)
                            ),
                          ],
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
              const SizedBox(height: 24),

              // Bio
              if (p.bio?.isNotEmpty ?? false)
                _section(
                  title: 'About $firstName',
                  child: Text(p.bio!, style: const TextStyle(fontSize: 15, height: 1.7, color: Color(0xFF444444))),
                ),

              // Interests
              if (p.interests.isNotEmpty)
                _section(
                  title: 'Interests',
                  child: Wrap(
                    spacing: 8, runSpacing: 10,
                    children: p.interests.map((i) => _interestChip(i)).toList(),
                  ),
                ),

              // Career & Education
              if ((p.job?.isNotEmpty ?? false) || (p.education?.isNotEmpty ?? false))
                _section(
                  title: 'Career & Education',
                  child: Column(
                    children: [
                      if (p.job?.isNotEmpty ?? false) _infoTile(Icons.work_outline_rounded, 'Job', p.job!),
                      if ((p.job?.isNotEmpty ?? false) && (p.education?.isNotEmpty ?? false)) const SizedBox(height: 10),
                      if (p.education?.isNotEmpty ?? false) _infoTile(Icons.school_outlined, 'Education', p.education!),
                    ],
                  ),
                ),

              // Lifestyle
              if ((p.drinking?.isNotEmpty ?? false) || (p.smoking?.isNotEmpty ?? false) || (p.exercise?.isNotEmpty ?? false))
                _section(
                  title: 'Lifestyle',
                  child: Row(
                    children: [
                      if (p.drinking?.isNotEmpty ?? false)
                        Expanded(child: _lifestyleTile('Drinking', p.drinking!)),
                      if (p.smoking?.isNotEmpty ?? false)
                        Expanded(child: _lifestyleTile('Smoking', p.smoking!)),
                      if (p.exercise?.isNotEmpty ?? false)
                        Expanded(child: _lifestyleTile('Exercise', p.exercise!)),
                    ],
                  ),
                ),

              // Basics (Gender, Zodiac, etc.)
              _section(
                title: 'Basics',
                child: Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    if (p.gender?.isNotEmpty ?? false) _basicPill(p.gender!),
                    if (p.height != null) _basicPill('${p.height!.toInt()} cm'),
                    if (p.zodiac?.isNotEmpty ?? false) _basicPill(p.zodiac!),
                    if (p.relationshipType?.isNotEmpty ?? false) _basicPill(p.relationshipType!),
                    if (p.religion?.isNotEmpty ?? false) _basicPill(p.religion!),
                    if (p.politics?.isNotEmpty ?? false) _basicPill(p.politics!),
                    if (p.hometown?.isNotEmpty ?? false) _basicPill('From ${p.hometown!}'),
                    if (p.wantKids?.isNotEmpty ?? false) _basicPill(p.wantKids!),
                    if (p.haveKids?.isNotEmpty ?? false) _basicPill(p.haveKids!.contains('Yes') ? 'Has children' : 'No children'),
                  ],
                ),
              ),

              const SizedBox(height: 120), // Bottom padding for actions
            ]),
          ),
        ],
      ),
      bottomSheet: _buildActionRow(),
    );
  }

  Widget _buildActionRow() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          // Pass Button
          Expanded(
            child: GestureDetector(
              onTap: () => _handleSwipe(false),
              child: Container(
                height: 56,
                decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(18)),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.close_rounded, color: Color(0xFF8A8A8A), size: 24),
                    SizedBox(width: 8),
                    Text('Pass', style: TextStyle(color: Color(0xFF8A8A8A), fontWeight: FontWeight.w700, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Like Button
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => _handleSwipe(true),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB0506A), Color(0xFFD4788A)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: _maroon.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.favorite_rounded, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    const Text('Like', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _interestChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFFDECEC), borderRadius: BorderRadius.circular(50)),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _maroon)),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(color: const Color(0xFFF8F4F2), borderRadius: BorderRadius.circular(14)),
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
      decoration: BoxDecoration(color: const Color(0xFFF8F4F2), borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFAAAAAA))),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
      ]),
    );
  }

  Widget _basicPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(50)),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF444444))),
    );
  }
}
