import 'package:flutter/material.dart';
import 'constants.dart';

class GiftTransaction {
  final String id;
  final String icon;
  final String title;
  final int amount;
  final String type; // 'Sent', 'Received'
  final String timestamp;
  final String? userName;
  final String? userImage;
  final String? message;

  GiftTransaction({
    required this.id,
    required this.icon,
    required this.title,
    required this.amount,
    required this.type,
    required this.timestamp,
    this.userName,
    this.userImage,
    this.message,
  });
}

class GiftService {
  static final GiftService _instance = GiftService._internal();
  factory GiftService() => _instance;
  GiftService._internal();

  final ValueNotifier<List<GiftTransaction>> transactionsNotifier = ValueNotifier<List<GiftTransaction>>([
    // Initial Dummy Data (Received)
    GiftTransaction(
      id: '1',
      icon: '🎁',
      title: 'Received Gift from Priya',
      amount: 50,
      type: 'Received',
      timestamp: '1 hr ago',
      userName: 'Priya Singh',
      userImage: AppConstants.defaultAvatar2,
      message: 'Just a little something for you.',
    ),
    GiftTransaction(
      id: '2',
      icon: '💎',
      title: 'Received Diamond from Sarah',
      amount: 150,
      type: 'Received',
      timestamp: 'Oct 12',
      userName: 'Sarah Jenkins',
      userImage: AppConstants.defaultAvatar3,
      message: 'You deserve the best.',
    ),
  ]);

  List<GiftTransaction> get transactions => transactionsNotifier.value;

  void addTransaction(GiftTransaction tx) {
    transactionsNotifier.value = [tx, ...transactionsNotifier.value];
  }
}
