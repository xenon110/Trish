import 'package:flutter/material.dart';
import '../../core/theme.dart';

class TransactionItem {
  final String icon;
  final String title;
  final int amount;
  final String type; // 'Sent', 'Received', 'Added'
  final String timestamp;

  TransactionItem({
    required this.icon,
    required this.title,
    required this.amount,
    required this.type,
    required this.timestamp,
  });
}

class FullTransactionHistoryScreen extends StatefulWidget {
  const FullTransactionHistoryScreen({super.key});

  @override
  State<FullTransactionHistoryScreen> createState() => _FullTransactionHistoryScreenState();
}

class _FullTransactionHistoryScreenState extends State<FullTransactionHistoryScreen> {
  String _selectedFilter = 'All';

  final List<TransactionItem> _transactions = [
    TransactionItem(icon: '🌹', title: 'Sent Rose to Ankit', amount: 10, type: 'Sent', timestamp: '2 min ago'),
    TransactionItem(icon: '🎁', title: 'Received Gift from Priya', amount: 50, type: 'Received', timestamp: '1 hr ago'),
    TransactionItem(icon: '💳', title: 'Added Money to Wallet', amount: 500, type: 'Added', timestamp: '2 hrs ago'),
    TransactionItem(icon: '🍫', title: 'Sent Chocolate to Rahul', amount: 20, type: 'Sent', timestamp: 'Yesterday'),
    TransactionItem(icon: '💎', title: 'Received Diamond from Sarah', amount: 150, type: 'Received', timestamp: 'Oct 12'),
    TransactionItem(icon: '💳', title: 'Added Money to Wallet', amount: 200, type: 'Added', timestamp: 'Oct 10'),
    TransactionItem(icon: '☕', title: 'Sent Coffee to Mike', amount: 15, type: 'Sent', timestamp: 'Oct 09'),
  ];

  @override
  Widget build(BuildContext context) {
    List<TransactionItem> filteredTransactions = _transactions.where((tx) {
      if (_selectedFilter == 'All') return true;
      return tx.type == _selectedFilter;
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
          'Transactions',
          style: TextStyle(
            color: Color(0xFF2C2C2E),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilters(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                itemCount: filteredTransactions.length,
                itemBuilder: (context, index) {
                  return _buildTransactionCard(filteredTransactions[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final filters = ['All', 'Sent', 'Received', 'Added'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2C2C2E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF2C2C2E) : const Color(0xFFEBEBEB),
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF8E8E93),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTransactionCard(TransactionItem tx) {
    Color statusColor;
    String statusText = tx.type;

    if (tx.type == 'Sent') {
      statusColor = const Color(0xFFFF3B30);
    } else if (tx.type == 'Received') {
      statusColor = const Color(0xFF34C759);
    } else {
      statusColor = AppTheme.primaryMaroon; // Added
    }

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
              color: statusColor.withValues(alpha: 0.1),
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
            '${tx.type == 'Sent' ? '-' : '+'}₹${tx.amount}',
            style: TextStyle(
              color: statusColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
