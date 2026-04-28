import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../core/auth_service.dart';

class MomentsScreen extends StatefulWidget {
  const MomentsScreen({super.key});

  @override
  State<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends State<MomentsScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  late TabController _tabController;

  List<Map<String, dynamic>> _personal = [];
  List<Map<String, dynamic>> _public = [];
  bool _isLoading = true;
  bool _isUploading = false;

  static const _maroon = AppTheme.primaryMaroon;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMoments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMoments() async {
    setState(() => _isLoading = true);
    try {
      final all = await _authService.getMyMoments();
      setState(() {
        _personal = all.where((m) => m['visibility'] == 'personal').toList();
        _public = all.where((m) => m['visibility'] == 'public').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _snack('Error loading: ${e.toString()}');
    }
  }

  Future<void> _pickAndUpload(String visibility) async {
    Navigator.pop(context); // close bottom sheet
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1080,
    );
    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      final Uint8List bytes = await image.readAsBytes();
      final row = await _authService.addMoment(bytes: bytes, visibility: visibility);
      setState(() {
        if (visibility == 'personal') {
          _personal.insert(0, row);
        } else {
          _public.insert(0, row);
        }
      });
      _snack(
        visibility == 'public' ? 'Shared to public feed! 🌍' : 'Saved privately! 🔒',
        success: true,
      );
    } catch (e) {
      _snack('Upload failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteMoment(String id, String visibility) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete moment?',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: const Text('This will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _authService.deleteMoment(id);
      setState(() {
        if (visibility == 'personal') {
          _personal.removeWhere((m) => m['id'] == id);
        } else {
          _public.removeWhere((m) => m['id'] == id);
        }
      });
      _snack('Moment deleted.');
    } catch (e) {
      _snack('Error: ${e.toString()}');
    }
  }

  void _snack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: success ? const Color(0xFF34C759) : Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(height: 24),
          const Text('Add a Moment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 6),
          Text('Choose who can see this photo', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          const SizedBox(height: 28),
          _sheetOption(
            icon: Icons.lock_rounded,
            color: const Color(0xFF5B7BFE),
            title: 'Personal',
            subtitle: 'Only visible to you',
            onTap: () => _pickAndUpload('personal'),
          ),
          const SizedBox(height: 12),
          _sheetOption(
            icon: Icons.public_rounded,
            color: _maroon,
            title: 'Public',
            subtitle: 'Visible to everyone on the feed',
            onTap: () => _pickAndUpload('public'),
          ),
        ]),
      ),
    );
  }

  Widget _sheetOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
            Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          ]),
          const Spacer(),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _maroon, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('My Moments',
            style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF0E8E4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF9E9E9E),
              indicator: BoxDecoration(
                color: _maroon,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              padding: const EdgeInsets.all(4),
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: [
                Tab(
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.lock_rounded, size: 14),
                    const SizedBox(width: 6),
                    Text('Personal  (${_personal.length})'),
                  ]),
                ),
                Tab(
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.public_rounded, size: 14),
                    const SizedBox(width: 6),
                    Text('Public  (${_public.length})'),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _isUploading
          ? Container(
              width: 58, height: 58,
              decoration: const BoxDecoration(color: _maroon, shape: BoxShape.circle),
              child: const Center(
                child: SizedBox(width: 24, height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
              ),
            )
          : FloatingActionButton(
              backgroundColor: _maroon,
              elevation: 6,
              onPressed: _showAddSheet,
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _maroon))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGrid(_personal, 'personal'),
                _buildGrid(_public, 'public'),
              ],
            ),
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> moments, String visibility) {
    final isPersonal = visibility == 'personal';
    final accentColor = isPersonal ? const Color(0xFF5B7BFE) : _maroon;

    return CustomScrollView(
      slivers: [
        // Info banner
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accentColor.withOpacity(0.15)),
              ),
              child: Row(children: [
                Icon(isPersonal ? Icons.lock_rounded : Icons.public_rounded,
                    size: 16, color: accentColor),
                const SizedBox(width: 10),
                Text(
                  isPersonal
                      ? 'Only you can see these moments'
                      : 'Visible to everyone on the public feed',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: accentColor),
                ),
              ]),
            ),
          ),
        ),

        if (moments.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPersonal ? Icons.lock_outline_rounded : Icons.public_rounded,
                    size: 40, color: accentColor.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isPersonal ? 'No personal moments yet' : 'No public moments yet',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF555555)),
                ),
                const SizedBox(height: 8),
                Text(
                  isPersonal ? 'Tap + to add a private photo' : 'Tap + to share with everyone',
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
              ]),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final m = moments[index];
                  return GestureDetector(
                    onLongPress: () => _deleteMoment(m['id'], visibility),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            m['image_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                            ),
                          ),
                        ),
                        // Gradient on bottom
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Container(
                            height: 36,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Colors.black.withOpacity(0.45), Colors.transparent],
                              ),
                            ),
                          ),
                        ),
                        // Badge top-right
                        Positioned(
                          top: 6, right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.85),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isPersonal ? Icons.lock_rounded : Icons.public_rounded,
                              color: Colors.white, size: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                childCount: moments.length,
              ),
            ),
          ),
      ],
    );
  }
}
