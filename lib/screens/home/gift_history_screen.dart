import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/gift_service.dart';
import 'gift_details_screen.dart';
import 'received_gifts_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../../core/ui_helpers.dart';

class GiftHistoryScreen extends StatefulWidget {
  final int initialTabIndex;
  const GiftHistoryScreen({super.key, this.initialTabIndex = 0});

  @override
  State<GiftHistoryScreen> createState() => _GiftHistoryScreenState();
}

class _GiftHistoryScreenState extends State<GiftHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          'Gift History',
          style: TextStyle(color: Color(0xFF2C2C2E), fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryMaroon,
          unselectedLabelColor: const Color(0xFF8E8E93),
          indicatorColor: AppTheme.primaryMaroon,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Sent'),
            Tab(text: 'Received'),
          ],
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('physical_gifts')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final currentUserId = Supabase.instance.client.auth.currentUser?.id;
          final allGifts = snapshot.data ?? [];
          
          final sentGifts = allGifts.where((g) => g['sender_id'] == currentUserId).toList();
          final receivedGifts = allGifts.where((g) => g['recipient_id'] == currentUserId).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildModernTransactionList(allGifts, currentUserId!),
              _buildModernTransactionList(sentGifts, currentUserId),
              _buildModernTransactionList(receivedGifts, currentUserId),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModernTransactionList(List<Map<String, dynamic>> gifts, String currentUserId) {
    if (gifts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard_rounded, size: 64, color: const Color(0xFFEBEBEB)),
            const SizedBox(height: 16),
            const Text(
              'No gift activity yet',
              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: gifts.length,
      itemBuilder: (context, index) {
        final gift = gifts[index];
        final isSent = gift['sender_id'] == currentUserId;
        final status = gift['status'] as String;
        
        Color statusColor;
        switch (status) {
          case 'Accepted': statusColor = const Color(0xFF34C759); break;
          case 'Rejected': statusColor = const Color(0xFFFF3B30); break;
          case 'Delivered': statusColor = Colors.blue; break;
          default: statusColor = const Color(0xFFFF9500);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryMaroon.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        gift['gift_item'] == 'Rose' ? '🌹' : 
                        gift['gift_item'] == 'Chocolate' ? '🍫' : 
                        gift['gift_item'] == 'Teddy' ? '🎁' : '💎', 
                        style: const TextStyle(fontSize: 24)
                      )
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${isSent ? "Sent to" : "Received"} ${gift['gift_item']}',
                          style: const TextStyle(color: Color(0xFF2C2C2E), fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '₹${gift['price']}',
                              style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (gift['personal_message'] != null && gift['personal_message'].toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '"${gift['personal_message']}"',
                    style: const TextStyle(color: Color(0xFF636366), fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF2F2F7)),
              const SizedBox(height: 12),
              
              // Action Buttons for Recipient
              if (!isSent && status == 'Awaiting Acceptance') 
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _handleGiftResponse(gift['id'], false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF3B30),
                          side: const BorderSide(color: Color(0xFFFF3B30)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showAddressForm(gift),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF34C759),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Accept', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              else
                Center(
                  child: Text(
                    isSent ? "Waiting for recipient" : "Order Processed",
                    style: const TextStyle(color: Color(0xFFC7C7CC), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleGiftResponse(String giftId, bool accepted) async {
    try {
      await Supabase.instance.client
          .from('physical_gifts')
          .update({'status': accepted ? 'Accepted' : 'Rejected'})
          .eq('id', giftId);
          
      if (mounted) {
        UIHelpers.showSnackBar(context, accepted ? 'Gift Accepted! 🎉' : 'Gift Rejected');
      }
    } catch (e) {
      if (mounted) UIHelpers.showSnackBar(context, 'Error: $e', isError: true);
    }
  }

  void _showAddressForm(Map<String, dynamic> gift) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final pincodeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Delivery Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Please provide your address for physical delivery.', style: TextStyle(color: Color(0xFF8E8E93))),
              const SizedBox(height: 24),
              _buildInput(nameController, 'Full Name', Icons.person_outline),
              const SizedBox(height: 16),
              _buildInput(phoneController, 'Mobile Number', Icons.phone_android_rounded, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildInput(addressController, 'Full Shipping Address', Icons.location_on_outlined, maxLines: 3),
              const SizedBox(height: 16),
              _buildInput(pincodeController, 'Pincode', Icons.pin_drop_outlined, keyboardType: TextInputType.number),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty || addressController.text.isEmpty) {
                      UIHelpers.showSnackBar(context, 'Please fill all details', isError: true);
                      return;
                    }
                    
                    Navigator.pop(context);
                    await Supabase.instance.client.from('physical_gifts').update({
                      'status': 'Accepted',
                      'recipient_full_name': nameController.text,
                      'recipient_phone': phoneController.text,
                      'delivery_address': addressController.text,
                      'pincode': pincodeController.text,
                    }).eq('id', gift['id']);
                    
                    if (mounted) UIHelpers.showSnackBar(context, 'Success! Your gift will be delivered soon. 🚚');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryMaroon,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Confirm Delivery Address', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryMaroon, size: 20),
        filled: true,
        fillColor: const Color(0xFFF7F7F8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  void _showThankYouSheet(BuildContext context) {
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
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 6,
                  decoration: BoxDecoration(color: const Color(0xFFEBEBEB), borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Say Thank You', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildQuickMessageChip(context, 'Thanks ❤️'),
                  const SizedBox(width: 12),
                  _buildQuickMessageChip(context, 'Loved it 😍'),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Or type your own...',
                  filled: true,
                  fillColor: const Color(0xFFF7F7F8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message sent!'), backgroundColor: Color(0xFF34C759)),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryMaroon, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  child: const Text('Send', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickMessageChip(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: AppTheme.primaryMaroon.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
      child: Text(message, style: TextStyle(color: AppTheme.primaryMaroon, fontWeight: FontWeight.bold)),
    );
  }
}
