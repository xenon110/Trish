import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/gift_service.dart';
import 'gift_history_screen.dart';
import '../../core/auth_service.dart';
import '../../models/user_profile.dart';

class AddGiftScreen extends StatefulWidget {
  const AddGiftScreen({super.key});

  @override
  State<AddGiftScreen> createState() => _AddGiftScreenState();
}

class _AddGiftScreenState extends State<AddGiftScreen> {
  final AuthService _authService = AuthService();
  final List<Map<String, dynamic>> _availableGifts = [
    {'emoji': '🌹', 'name': 'Rose', 'price': 10},
    {'emoji': '🎁', 'name': 'Gift Box', 'price': 50},
    {'emoji': '🍫', 'name': 'Chocolate', 'price': 30},
    {'emoji': '💎', 'name': 'Diamond', 'price': 100},
    {'emoji': '🧸', 'name': 'Teddy Bear', 'price': 80},
    {'emoji': '☕', 'name': 'Coffee', 'price': 20},
  ];
  int _selectedGiftIndex = -1;
  UserProfile? _selectedUser;
  final TextEditingController _messageController = TextEditingController();
  List<UserProfile> _availableUsers = [];
  bool _isUsersLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _authService.getProfiles();
      if (mounted) {
        setState(() {
          _availableUsers = users;
          _isUsersLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUsersLoading = false);
      }
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
        title: const Text(
          'Send a Gift',
          style: TextStyle(
            color: Color(0xFF2C2C2E),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('1. Select a Gift'),
              const SizedBox(height: 16),
              _buildGiftGrid(),
              const SizedBox(height: 32),
              _buildSectionTitle('2. Select Recipient'),
              const SizedBox(height: 16),
              _buildUserSelector(),
              const SizedBox(height: 32),
              _buildSectionTitle('3. Message (Optional)'),
              const SizedBox(height: 16),
              _buildMessageInput(),
              const SizedBox(height: 48),
              _buildSendAction(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF2C2C2E),
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildGiftGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _availableGifts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final gift = _availableGifts[index];
        final isSelected = _selectedGiftIndex == index;

        return GestureDetector(
          onTap: () => setState(() => _selectedGiftIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFDF0F2) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isSelected ? AppTheme.primaryMaroon : Colors.transparent,
                width: isSelected ? 2 : 0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected 
                      ? AppTheme.primaryMaroon.withOpacity(0.2) 
                      : Colors.black.withOpacity(0.04),
                  blurRadius: isSelected ? 20 : 15,
                  spreadRadius: isSelected ? 2 : 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (index == 1 || index == 3) // Add "Hot" badge to a few items
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFDC830), Color(0xFFF37335)]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'HOT',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedScale(
                      scale: isSelected ? 1.15 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.elasticOut,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : const Color(0xFFF7F7F8),
                          shape: BoxShape.circle,
                          boxShadow: isSelected ? [
                            BoxShadow(color: AppTheme.primaryMaroon.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)
                          ] : [],
                        ),
                        child: Text(gift['emoji'], style: const TextStyle(fontSize: 42)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      gift['name'],
                      style: TextStyle(
                        color: const Color(0xFF2C2C2E),
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryMaroon : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '₹${gift['price']}',
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF8E8E93),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isSelected)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Icon(Icons.check_circle_rounded, color: AppTheme.primaryMaroon, size: 20),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserSelector() {
    return GestureDetector(
      onTap: _showUserBottomSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            if (_selectedUser != null) ...[
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryMaroon, width: 2),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(_selectedUser!.avatarUrl ?? AppConstants.defaultAvatar1),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sending to', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(
                    _selectedUser!.fullName,
                    style: const TextStyle(color: Color(0xFF2C2C2E), fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFFDECEC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_search_rounded, color: Color(0xFF9D4C5E), size: 24),
              ),
              const SizedBox(width: 16),
              const Text(
                'Tap to select recipient',
                style: TextStyle(color: Color(0xFF2C2C2E), fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0xFFF7F7F8), shape: BoxShape.circle),
              child: const Icon(Icons.keyboard_arrow_right_rounded, color: Color(0xFF8E8E93), size: 20),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(color: const Color(0xFFEBEBEB), borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 24),
              const Text('Select User', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search user...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFFF7F7F8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _isUsersLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _availableUsers.isEmpty
                        ? const Center(child: Text('No users found'))
                        : ListView.builder(
                            itemCount: _availableUsers.length,
                            itemBuilder: (context, index) {
                              final user = _availableUsers[index];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundImage: NetworkImage(user.avatarUrl ?? AppConstants.defaultAvatar1),
                                ),
                                title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(user.goal ?? 'No goal set'),
                                onTap: () {
                                  setState(() => _selectedUser = user);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _messageController,
        maxLines: 3,
        style: const TextStyle(color: Color(0xFF2C2C2E), fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Add a personal note...',
          hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildSendAction() {
    final bool isReady = _selectedGiftIndex != -1 && _selectedUser != null;

    return GestureDetector(
      onTap: isReady ? _showConfirmationDialog : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isReady 
                ? [AppTheme.primaryMaroon, const Color(0xFFE56A7C)]
                : [const Color(0xFFEBEBEB), const Color(0xFFD1D1D6)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: isReady ? [
            BoxShadow(
              color: AppTheme.primaryMaroon.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ] : [],
        ),
        child: Center(
          child: Text(
            isReady ? 'Send Gift (₹${_availableGifts[_selectedGiftIndex]['price']})' : 'Select Gift & User',
            style: TextStyle(
              color: isReady ? Colors.white : const Color(0xFF8E8E93), 
              fontSize: 18, 
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  void _showConfirmationDialog() {
    final gift = _availableGifts[_selectedGiftIndex];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Confirm Gift', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Send ${gift['emoji']} ${gift['name']} to ${_selectedUser!.fullName} for ₹${gift['price']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _processGifting();
            },
            child: Text('Confirm', style: TextStyle(color: AppTheme.primaryMaroon, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _processGifting() {
    final gift = _availableGifts[_selectedGiftIndex];
    final tx = GiftTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      icon: gift['emoji'],
      title: 'Sent ${gift['name']} to ${_selectedUser!.fullName}',
      amount: gift['price'],
      type: 'Sent',
      timestamp: 'Just now',
      userName: _selectedUser!.fullName,
      userImage: _selectedUser!.avatarUrl ?? AppConstants.defaultAvatar1,
      message: _messageController.text,
    );

    GiftService().addTransaction(tx);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Gift Sent Successfully 🎉', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF34C759),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const GiftHistoryScreen()));
  }
}
