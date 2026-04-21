import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'gift_history_screen.dart';
import 'add_gift_screen.dart';

class WalletTransaction {
  final String icon;
  final String title;
  final int amount;
  final bool isSent;
  final String timestamp;

  WalletTransaction({
    required this.icon,
    required this.title,
    required this.amount,
    required this.isSent,
    required this.timestamp,
  });
}

class MyWalletScreen extends StatefulWidget {
  const MyWalletScreen({super.key});

  @override
  State<MyWalletScreen> createState() => _MyWalletScreenState();
}

class _MyWalletScreenState extends State<MyWalletScreen> {
  String _selectedFilter = 'All';

  final List<WalletTransaction> _transactions = [
    WalletTransaction(
      icon: '🌹',
      title: 'Sent Rose to Ankit',
      amount: 10,
      isSent: true,
      timestamp: '2 min ago',
    ),
    WalletTransaction(
      icon: '🎁',
      title: 'Received Gift from Priya',
      amount: 50,
      isSent: false,
      timestamp: '1 hr ago',
    ),
    WalletTransaction(
      icon: '🍫',
      title: 'Sent Chocolate to Rahul',
      amount: 20,
      isSent: true,
      timestamp: 'Yesterday',
    ),
    WalletTransaction(
      icon: '💎',
      title: 'Received Diamond from Sarah',
      amount: 150,
      isSent: false,
      timestamp: 'Oct 12',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    List<WalletTransaction> filteredTransactions = _transactions.where((tx) {
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Sent') return tx.isSent;
      if (_selectedFilter == 'Received') return !tx.isSent;
      return true;
    }).toList();

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
          'Wallet / Balance',
          style: TextStyle(
            color: Color(0xFF2C2C2E),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primaryMaroon.withValues(alpha: 0.85), size: 28),
          ),
        ],
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBalanceOverview(context),
              const SizedBox(height: 32),
              _buildAddMoneySection(context),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Gift Transactions',
                    style: TextStyle(
                      color: Color(0xFF2C2C2E),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const GiftHistoryScreen()));
                    },
                    child: Text(
                      'See All',
                      style: TextStyle(
                        color: AppTheme.primaryMaroon,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...filteredTransactions.map((tx) => _buildTransactionCard(tx)),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceOverview(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFFDFBFB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'TOTAL BALANCE',
            style: TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹ ',
                style: TextStyle(
                  color: Color(0xFF2C2C2E),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '1,250',
                style: TextStyle(
                  color: Color(0xFF2C2C2E),
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFF2F2F7), thickness: 1.5),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn('Received', '₹ 800', Icons.call_received_rounded, const Color(0xFF34C759)),
              Container(width: 1.5, height: 40, color: const Color(0xFFF2F2F7)),
              _buildStatColumn('Sent', '₹ 450', Icons.call_made_rounded, const Color(0xFFFF3B30)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              'Total Gifts $label',
              style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(color: Color(0xFF2C2C2E), fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _buildAddMoneySection(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showAddMoneyBottomSheet(context),
        icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
        label: const Text(
          'Add Money',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryMaroon,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 4,
          shadowColor: AppTheme.primaryMaroon.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  void _showAddMoneyBottomSheet(BuildContext context) {
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
            children: [
              Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBEBEB),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Add Money',
                style: TextStyle(color: Color(0xFF2C2C2E), fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 24),
              TextField(
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '₹ 0',
                  hintStyle: const TextStyle(color: Color(0xFFC7C7CC)),
                  filled: true,
                  fillColor: const Color(0xFFF7F7F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickAmount(context, '₹ 50'),
                  _buildQuickAmount(context, '₹ 100'),
                  _buildQuickAmount(context, '₹ 200'),
                  _buildQuickAmount(context, '₹ 500'),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Top-up successful!', style: TextStyle(fontWeight: FontWeight.bold)),
                        backgroundColor: const Color(0xFF34C759),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryMaroon,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Confirm', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickAmount(BuildContext context, String amount) {
    return GestureDetector(
      onTap: () {
        // Just UI updating concept
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEBEBEB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          amount,
          style: const TextStyle(color: Color(0xFF2C2C2E), fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF8E8E93), size: 20),
          isDense: true,
          style: const TextStyle(color: Color(0xFF2C2C2E), fontWeight: FontWeight.w700, fontSize: 14),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedFilter = newValue;
              });
            }
          },
          items: <String>['All', 'Sent', 'Received'].map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(WalletTransaction tx) {
    final statusColor = tx.isSent ? const Color(0xFFFF3B30) : const Color(0xFF34C759);
    final statusText = tx.isSent ? 'Sent' : 'Received';

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
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: tx.isSent ? const Color(0xFFFDECEC) : const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(tx.icon, style: const TextStyle(fontSize: 22)),
            ),
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
                        statusText,
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
            '₹${tx.amount}',
            style: TextStyle(
              color: statusColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
