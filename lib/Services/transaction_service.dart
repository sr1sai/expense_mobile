import 'package:flutter/foundation.dart';
import '../models/transaction.dart';

enum TransactionType { debit, credit }

extension TransactionTypeX on TransactionType {
  String get label => this == TransactionType.debit ? 'Debit' : 'Credit';
}

/// Mock service for fetching transactions.
/// Replace implementation with real API integration when backend is ready.
class TransactionService {
  Future<List<Transaction>> fetchTransactions() async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 400));

      final now = DateTime.now();
      // Generate a varied list for recent months
      final List<Transaction> items = List.generate(60, (i) {
        final date = now.subtract(Duration(days: i));
        final bool isCredit = i % 3 == 0;
        final double amount = ((i * 17) % 250 + 10).toDouble();
        final targets = [
          'Grocery Mart',
          'Rent',
          'Salary',
          'Coffee Co.',
          'Gym',
          'Utilities',
          'Book Store',
          'Friend',
        ];
        final accounts = [
          'Checking',
          'Savings',
          'Credit Card',
          'Cash Wallet',
          'Business',
        ];
        return Transaction(
          id: 'tx_$i',
          userId: 'user_1',
          type: isCredit ? 'credit' : 'debit',
          amount: amount,
          account: accounts[i % accounts.length],
          target: targets[i % targets.length],
          time: DateTime(
            date.year,
            date.month,
            date.day,
            (i * 3) % 24,
            (i * 7) % 60,
          ),
        );
      });
      return items;
    } catch (e) {
      debugPrint('TransactionService.fetchTransactions error: $e');
      return [];
    }
  }
}
