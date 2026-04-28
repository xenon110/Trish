import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'updates_screen.dart';
import 'blind_mode_screen.dart';
import 'wallet_screen.dart';
import 'profile_screen.dart';
import '../blocked/blocked_screen.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../core/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  late final RealtimeChannel _giftChannel;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const UpdatesScreen(),
    const BlindModeScreen(),
    const WalletScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkBlockedStatus();
    // Run silently in background — creates matches for 50%+ compatible profiles
    _authService.checkCompatibilityMatches();
    _checkMissedGifts();
    _listenForIncomingGifts();
  }

  Future<void> _checkMissedGifts() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final data = await Supabase.instance.client
          .from('physical_gifts')
          .select()
          .eq('recipient_id', userId)
          .eq('status', 'Awaiting Acceptance');
      
      for (var gift in data) {
        _showGiftPopup(gift);
      }
    } catch (e) {
      debugPrint('Error checking missed gifts: $e');
    }
  }

  void _listenForIncomingGifts() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _giftChannel = Supabase.instance.client
        .channel('public:physical_gifts')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'physical_gifts',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'recipient_id', value: userId),
          callback: (payload) {
            final newGift = payload.newRecord;
            if (newGift['status'] == 'Awaiting Acceptance') {
              _showGiftPopup(newGift);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'physical_gifts',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'sender_id', value: userId),
          callback: (payload) {
            final updatedGift = payload.newRecord;
            if (updatedGift['status'] == 'Pending Payment') {
              _showPaymentPopup(updatedGift);
            }
          },
        )
        .subscribe();
  }

  void _showPaymentPopup(Map<String, dynamic> gift) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Complete Payment', style: TextStyle(fontWeight: FontWeight.w800)),
          content: Text('The recipient has accepted your gift of ${gift['gift_item']}! Please complete the payment of ₹${gift['price']} to process the order.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _processPayment(gift['id']);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryMaroon, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Pay Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processPayment(String giftId) async {
    // Here you would integrate Razorpay or Wallet deduction
    try {
      await Supabase.instance.client.from('physical_gifts').update({'status': 'Accepted'}).eq('id', giftId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Successful! The gift is now being processed.'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showGiftPopup(Map<String, dynamic> gift) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Text('🎁', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 8),
              const Expanded(child: Text('New Gift Received!', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Someone sent you a ${gift['gift_item']}!', style: const TextStyle(fontSize: 16)),
              if (gift['personal_message'] != null && gift['personal_message'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.primaryMaroon.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                  child: Text('"${gift['personal_message']}"', style: const TextStyle(fontStyle: FontStyle.italic)),
                ),
              ],
              const SizedBox(height: 20),
              const Text('Do you want to accept this gift?', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateGiftStatus(gift['id'], 'Rejected');
              },
              child: const Text('Reject', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showAddressDialog(gift);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryMaroon,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Accept Gift', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showAddressDialog(Map<String, dynamic> gift) {
    final addressController = TextEditingController();
    final pinController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Delivery Details', style: TextStyle(fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please provide your details to receive the physical gift. This will be kept secure.'),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  maxLines: 2,
                  decoration: InputDecoration(hintText: 'Full Address', filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(hintText: 'Pincode', filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(hintText: 'Phone Number', filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (addressController.text.trim().isEmpty || pinController.text.trim().isEmpty || phoneController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                  return;
                }
                Navigator.pop(context);
                _acceptGiftAndSaveAddress(gift['id'], addressController.text, pinController.text, phoneController.text);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryMaroon, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateGiftStatus(String giftId, String status) async {
    await Supabase.instance.client.from('physical_gifts').update({'status': status}).eq('id', giftId);
  }

  Future<void> _acceptGiftAndSaveAddress(String giftId, String address, String pin, String phone) async {
    try {
      await Supabase.instance.client.from('physical_gifts').update({
        'status': 'Pending Payment',
        'delivery_address': address,
        'pincode': pin,
        'recipient_phone': phone,
      }).eq('id', giftId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address saved! The sender will be notified to complete the payment.'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _checkBlockedStatus() async {
    final profile = await _authService.getCurrentProfile();
    if (profile != null && profile.isBlocked && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const BlockedScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(_giftChannel);
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  void jumpToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
