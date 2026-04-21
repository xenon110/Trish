import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/gift_service.dart';
import 'gift_details_screen.dart';
import 'received_gifts_screen.dart'; // For ReceivedGiftModel mapping

class GiftHistoryScreen extends StatefulWidget {
  const GiftHistoryScreen({super.key});

  @override
  State<GiftHistoryScreen> createState() => _GiftHistoryScreenState();
}

class _GiftHistoryScreenState extends State<GiftHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      body: ValueListenableBuilder<List<GiftTransaction>>(
        valueListenable: GiftService().transactionsNotifier,
        builder: (context, transactions, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildTransactionList(transactions),
              _buildTransactionList(transactions.where((t) => t.type == 'Sent').toList()),
              _buildTransactionList(transactions.where((t) => t.type == 'Received').toList()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTransactionList(List<GiftTransaction> txs) {
    if (txs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 64, color: const Color(0xFFEBEBEB)),
            const SizedBox(height: 16),
            const Text(
              'No transactions yet',
              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: txs.length,
      itemBuilder: (context, index) {
        final tx = txs[index];
        final isSent = tx.type == 'Sent';
        final statusColor = isSent ? const Color(0xFFFF3B30) : const Color(0xFF34C759);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
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
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text(tx.icon, style: const TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.title,
                          style: const TextStyle(color: Color(0xFF2C2C2E), fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tx.type,
                                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              tx.timestamp,
                              style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${isSent ? '-' : '+'}₹${tx.amount}',
                    style: TextStyle(color: statusColor, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF2F2F7)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isSent)
                    TextButton(
                      onPressed: () => _showThankYouSheet(context),
                      child: Text('Say Thank You', style: TextStyle(color: AppTheme.primaryMaroon, fontWeight: FontWeight.bold)),
                    ),
                  TextButton(
                    onPressed: () {
                      // Map to detail screen model
                      final model = ReceivedGiftModel(
                        senderName: tx.userName ?? 'User',
                        senderImage: tx.userImage ?? '',
                        giftEmoji: tx.icon,
                        giftName: tx.icon == '🌹' ? 'Rose' : tx.icon == '🍫' ? 'Chocolate' : tx.icon == '🎁' ? 'Teddy' : 'Gift',
                        message: tx.message ?? '',
                        time: tx.timestamp,
                        amount: tx.amount,
                      );
                      Navigator.push(context, MaterialPageRoute(builder: (context) => GiftDetailsScreen(gift: model)));
                    },
                    child: const Text('See Details', style: TextStyle(color: Color(0xFF8E8E93), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
