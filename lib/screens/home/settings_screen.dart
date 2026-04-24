import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/ui_helpers.dart';
import '../../core/auth_service.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Local state for toggles
  bool _isPrivateProfile = true;
  bool _showOnlineStatus = false;
  bool _readReceipts = true;
  bool _pushNotifications = true;
  bool _emailUpdates = false;
  bool _newMatches = true;

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
                  (v) => setState(() => _isPrivateProfile = v),
                ),
                _buildSwitchItem(
                  'Show Online Status',
                  'Let others know when you\'re active.',
                  _showOnlineStatus,
                  (v) => setState(() => _showOnlineStatus = v),
                ),
                _buildSwitchItem(
                  'Read Receipts',
                  'Show when you\'ve read messages.',
                  _readReceipts,
                  (v) => setState(() => _readReceipts = v),
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
                  (v) => setState(() => _pushNotifications = v),
                ),
                _buildSwitchItem(
                  'Email Updates',
                  '',
                  _emailUpdates,
                  (v) => setState(() => _emailUpdates = v),
                ),
                _buildSwitchItem(
                  'New Matches',
                  '',
                  _newMatches,
                  (v) => setState(() => _newMatches = v),
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
                _buildLinkItem('Delete Account', isDestructive: true, isLast: true),
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

  Widget _buildLinkItem(String title, {bool isDestructive = false, bool isLast = false}) {
    return InkWell(
      onTap: () => UIHelpers.showFeatureComingSoon(context),
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
