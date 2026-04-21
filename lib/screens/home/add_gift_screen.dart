import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/gift_service.dart';
import 'gift_history_screen.dart';

class AddGiftScreen extends StatefulWidget {
  const AddGiftScreen({super.key});

  @override
  State<AddGiftScreen> createState() => _AddGiftScreenState();
}

class _AddGiftScreenState extends State<AddGiftScreen> {
  int _selectedGiftIndex = -1;
  Map<String, String>? _selectedUser;
  final TextEditingController _messageController = TextEditingController();

  final List<Map<String, dynamic>> _availableGifts = [
    {'emoji': '🌹', 'name': 'Rose', 'price': 10, 'rating': 4.8},
    {'emoji': '🍫', 'name': 'Chocolate', 'price': 20, 'rating': 4.9},
    {'emoji': '🎁', 'name': 'Teddy', 'price': 50, 'rating': 4.7},
    {'emoji': '💎', 'name': 'Diamond', 'price': 100, 'rating': 5.0},
    {'emoji': '☕', 'name': 'Coffee', 'price': 15, 'rating': 4.6},
    {'emoji': '🥂', 'name': 'Cheers', 'price': 30, 'rating': 4.8},
  ];

  final List<Map<String, String>> _dummyUsers = [
    {'name': 'Ankit Sharma', 'image': AppConstants.defaultAvatar1},
    {'name': 'Priya Singh', 'image': AppConstants.defaultAvatar2},
    {'name': 'Rahul Verma', 'image': AppConstants.defaultAvatar3},
    {'name': 'Neha Kapoor', 'image': AppConstants.defaultAvatar2},
  ];

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
        childAspectRatio: 0.9,
      ),
      itemBuilder: (context, index) {
        final gift = _availableGifts[index];
        final isSelected = _selectedGiftIndex == index;

        return GestureDetector(
          onTap: () => setState(() => _selectedGiftIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFDECEC) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? AppTheme.primaryMaroon : const Color(0xFFF2F2F7),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                if (!isSelected)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(gift['emoji'], style: const TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                Text(
                  gift['name'],
                  style: TextStyle(
                    color: isSelected ? AppTheme.primaryMaroon : const Color(0xFF2C2C2E),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${gift['price']}',
                  style: TextStyle(
                    color: isSelected ? AppTheme.primaryMaroon : const Color(0xFF8E8E93),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEBEBEB)),
        ),
        child: Row(
          children: [
            if (_selectedUser != null) ...[
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(_selectedUser!['image']!),
              ),
              const SizedBox(width: 12),
              Text(
                _selectedUser!['name']!,
                style: const TextStyle(color: Color(0xFF2C2C2E), fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_add_rounded, color: Color(0xFF8E8E93)),
              ),
              const SizedBox(width: 12),
              const Text(
                'Choose Recipient',
                style: TextStyle(color: Color(0xFF8E8E93), fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
            const Spacer(),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF8E8E93)),
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
                child: ListView.builder(
                  itemCount: _dummyUsers.length,
                  itemBuilder: (context, index) {
                    final user = _dummyUsers[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      leading: CircleAvatar(radius: 24, backgroundImage: NetworkImage(user['image']!)),
                      title: Text(user['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
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
    return TextField(
      controller: _messageController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Write a message...',
        filled: true,
        fillColor: const Color(0xFFF7F7F8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildSendAction() {
    final bool isReady = _selectedGiftIndex != -1 && _selectedUser != null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isReady ? AppTheme.primaryMaroon : const Color(0xFFEBEBEB),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: isReady ? _showConfirmationDialog : null,
        child: Text(
          isReady ? 'Send Gift (₹${_availableGifts[_selectedGiftIndex]['price']})' : 'Select Gift & User',
          style: TextStyle(color: isReady ? Colors.white : const Color(0xFF8E8E93), fontSize: 16, fontWeight: FontWeight.w800),
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
        content: Text('Send ${gift['emoji']} ${gift['name']} to ${_selectedUser!['name']} for ₹${gift['price']}?'),
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
      title: 'Sent ${gift['name']} to ${_selectedUser!['name']}',
      amount: gift['price'],
      type: 'Sent',
      timestamp: 'Just now',
      userName: _selectedUser!['name'],
      userImage: _selectedUser!['image'],
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
