import 'package:flutter/material.dart';
import '../../core/theme.dart';

class SendGiftScreen extends StatefulWidget {
  const SendGiftScreen({super.key});

  @override
  State<SendGiftScreen> createState() => _SendGiftScreenState();
}

class _SendGiftScreenState extends State<SendGiftScreen> {
  int _selectedGiftIndex = -1;

  final List<Map<String, dynamic>> _availableGifts = [
    {'emoji': '🌹', 'name': 'Rose', 'price': 10, 'rating': 4.8},
    {'emoji': '🍫', 'name': 'Chocolate', 'price': 20, 'rating': 4.9},
    {'emoji': '🎁', 'name': 'Teddy', 'price': 50, 'rating': 4.7},
    {'emoji': '💎', 'name': 'Diamond', 'price': 100, 'rating': 5.0},
    {'emoji': '☕', 'name': 'Coffee', 'price': 15, 'rating': 4.6},
    {'emoji': '🥂', 'name': 'Cheers', 'price': 30, 'rating': 4.8},
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
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
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
              _buildTargetProfile(),
              const SizedBox(height: 32),
              const Text(
                'Select a Gift',
                style: TextStyle(
                  color: Color(0xFF2C2C2E),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              _buildGiftGrid(),
              const SizedBox(height: 32),
              _buildMessageSection(),
              const SizedBox(height: 48),
              _buildSendButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetProfile() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundImage: AssetImage('assets/image/connection.jpg'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sending to',
                  style: TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Alex, 28',
                  style: TextStyle(
                    color: Color(0xFF2C2C2E),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFDECEC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Balance: ₹1,245',
              style: TextStyle(
                color: AppTheme.primaryMaroon,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
          onTap: () {
            setState(() {
              _selectedGiftIndex = index;
            });
          },
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
                Text(
                  gift['emoji'],
                  style: const TextStyle(fontSize: 40),
                ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '₹${gift['price']}',
                      style: TextStyle(
                        color: isSelected ? AppTheme.primaryMaroon : const Color(0xFF8E8E93),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 14),
                    const SizedBox(width: 2),
                    Text(
                      gift['rating'].toString(),
                      style: const TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add a message (optional)',
          style: TextStyle(
            color: Color(0xFF2C2C2E),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Type your message here...',
            hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF7F7F8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildSendButton() {
    final bool canSend = _selectedGiftIndex != -1;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: canSend ? AppTheme.primaryMaroon : const Color(0xFFEBEBEB),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: canSend ? 4 : 0,
          shadowColor: canSend ? AppTheme.primaryMaroon.withValues(alpha: 0.3) : Colors.transparent,
        ),
        onPressed: canSend ? () => _handleSendGift() : null,
        child: Text(
          canSend ? 'Send Gift (₹${_availableGifts[_selectedGiftIndex]['price']})' : 'Select a Gift to Send',
          style: TextStyle(
            color: canSend ? Colors.white : const Color(0xFF8E8E93),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  void _handleSendGift() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Confirm Gift', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Are you sure you want to send ${_availableGifts[_selectedGiftIndex]['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF8E8E93), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryMaroon,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close screen
              
              // Show success message globally
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Text('🎉', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      const Text('Gift sent successfully', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  backgroundColor: const Color(0xFF34C759),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              );
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
