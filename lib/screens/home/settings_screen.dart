import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/ui_helpers.dart';
import '../../core/auth_service.dart';
import '../auth/login_screen.dart';
import 'subscription_screen.dart';
import 'personal_info_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Local state for toggles
  bool _isPrivateProfile = false;
  bool _showOnlineStatus = true;
  bool _readReceipts = true;
  bool _pushNotifications = true;
  bool _emailUpdates = false;
  bool _newMatches = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() {
    final metadata = _authService.currentUser?.userMetadata;
    if (metadata != null) {
      setState(() {
        _isPrivateProfile = metadata['pref_private_profile'] ?? false;
        _showOnlineStatus = metadata['pref_show_online'] ?? true;
        _readReceipts = metadata['pref_read_receipts'] ?? true;
        _pushNotifications = metadata['pref_push_notifs'] ?? true;
        _emailUpdates = metadata['pref_email_updates'] ?? false;
        _newMatches = metadata['pref_new_matches'] ?? true;
      });
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Account?',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C2C2E)),
        ),
        content: const Text(
          'This action is permanent and cannot be undone. Your profile, matches, and all data will be lost forever.',
          style: TextStyle(color: Color(0xFF6B6B6B), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B6B6B))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete Forever',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 1. Delete profile row from database
      await Supabase.instance.client
          .from('profiles')
          .delete()
          .eq('id', _authService.currentUser!.id);

      // 2. Sign out (Supabase free tier doesn't allow client-side auth.users deletion,
      //    but profile data is wiped. Use admin RPC if available.)
      try {
        await Supabase.instance.client.rpc('delete_user_account');
      } catch (_) {
        // RPC may not exist yet — profile is already deleted above
      }

      await _authService.signOut();
    } catch (e) {
      debugPrint('Delete account error: $e');
      // Still sign out to remove local session
      try { await _authService.signOut(); } catch (_) {}
    }

    // Always redirect to login after attempt
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _updatePreference(String key, bool value, Function(bool) updateState) async {
    setState(() {
      updateState(value);
      _isLoading = true;
    });

    try {
      final metadata = Map<String, dynamic>.from(_authService.currentUser?.userMetadata ?? {});
      metadata[key] = value;
      await _authService.updateProfile(metadata);
    } catch (e) {
      if (mounted) UIHelpers.showSnackBar(context, 'Failed to save preference');
      setState(() {
        updateState(!value);
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFAFA),
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  const Text(
                    'Preferences',
                    style: TextStyle(
                      color: Color(0xFF2C2C2E),
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Manage your account settings and privacy\npreferences.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF6B6B6B),
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            _buildSection(
              context,
              icon: Icons.security_rounded,
              title: 'Privacy & Security',
              children: [
                _buildSwitchItem(
                  'Private Profile',
                  'Only approved followers can see your posts.',
                  _isPrivateProfile,
                  (v) => _updatePreference('pref_private_profile', v, (val) => _isPrivateProfile = val),
                ),
                _buildSwitchItem(
                  'Show Online Status',
                  'Let others know when you\'re active.',
                  _showOnlineStatus,
                  (v) => _updatePreference('pref_show_online', v, (val) => _showOnlineStatus = val),
                ),
                _buildSwitchItem(
                  'Read Receipts',
                  'Show when you\'ve read messages.',
                  _readReceipts,
                  (v) => _updatePreference('pref_read_receipts', v, (val) => _readReceipts = val),
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              icon: Icons.notifications_rounded,
              title: 'Notifications',
              children: [
                _buildSwitchItem(
                  'Push Notifications',
                  '',
                  _pushNotifications,
                  (v) => _updatePreference('pref_push_notifs', v, (val) => _pushNotifications = val),
                ),
                _buildSwitchItem(
                  'Email Updates',
                  '',
                  _emailUpdates,
                  (v) => _updatePreference('pref_email_updates', v, (val) => _emailUpdates = val),
                ),
                _buildSwitchItem(
                  'New Matches',
                  '',
                  _newMatches,
                  (v) => _updatePreference('pref_new_matches', v, (val) => _newMatches = val),
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              icon: Icons.person_rounded,
              title: 'Account',
              children: [
                _buildLinkItem('Personal Information'),
                _buildLinkItem('Subscription'),
                _buildDeleteAccountButton(),
              ],
            ),
            const SizedBox(height: 48),
            _buildLogoutButton(context),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final authService = AuthService();
    return GestureDetector(
      onTap: () async {
        await authService.signOut();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFDECEC),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFF9D4C5E), size: 24),
            SizedBox(width: 12),
            Text(
              'Logout',
              style: TextStyle(color: Color(0xFF9D4C5E), fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Color(0xFFF2F2F7), shape: BoxShape.circle),
          child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF7D4249), size: 16),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Settings',
        style: TextStyle(color: Color(0xFF2C2C2E), fontWeight: FontWeight.w800, fontSize: 20),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required IconData icon, required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(48),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: Color(0xFFFDECEC), shape: BoxShape.circle),
                child: Icon(icon, color: const Color(0xFF9D4C5E), size: 20),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(color: Color(0xFF2C2C2E), fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchItem(String title, String subtitle, bool value, ValueChanged<bool> onChanged, {bool isLast = false}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Color(0xFF2C2C2E), fontWeight: FontWeight.w800, fontSize: 17),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13, height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF9D4C5E),
              activeTrackColor: const Color(0xFF9D4C5E).withOpacity(0.5),
            ),
          ],
        ),
        if (!isLast) const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDeleteAccountButton() {
    return Column(
      children: [
        const SizedBox(height: 24),
        InkWell(
          onTap: _deleteAccount,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF9D4C5E),
                      ),
                    )
                  : const Text(
                      'Delete Account',
                      style: TextStyle(
                        color: Color(0xFF9D4C5E),
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                      ),
                    ),
              const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFF9D4C5E),
                size: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLinkItem(String title, {bool isDestructive = false, bool isLast = false}) {
    return InkWell(
      onTap: () {
        if (title == 'Subscription') {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const SubscriptionScreen()));
        } else if (title == 'Personal Information') {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const PersonalInfoScreen()));
        } else {
          UIHelpers.showFeatureComingSoon(context);
        }
      },
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isDestructive ? const Color(0xFF9D4C5E) : const Color(0xFF2C2C2E),
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),
              Icon(
                isDestructive ? Icons.delete_outline_rounded : Icons.arrow_forward_ios_rounded,
                color: isDestructive ? const Color(0xFF9D4C5E) : const Color(0xFFD1D1D6),
                size: 18,
              ),
            ],
          ),
          if (!isLast) const SizedBox(height: 24),
        ],
      ),
    );
  }
}
