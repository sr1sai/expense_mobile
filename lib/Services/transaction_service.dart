import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../env_loader.dart';
import '../models/transaction.dart';
import 'session.dart';

enum TransactionType { debit, credit }

extension TransactionTypeX on TransactionType {
  String get label => this == TransactionType.debit ? 'Debit' : 'Credit';
}

/// Mock service for fetching transactions.
/// Replace implementation with real API integration when backend is ready.
class TransactionService {
  Future<List<Transaction>> fetchTransactions() async {
    try {
      final baseUrl = await EnvLoader.loadBaseUrl();
      final txController = await EnvLoader.getController('TransactionController');
      final getTxAction = await EnvLoader.getAction('GetTransactions');
      final userId = UserSession.currentUser?.id;
      if (userId == null || userId.isEmpty) {
        throw Exception('No logged in user');
      }
      final uri = Uri.parse('$baseUrl$txController$getTxAction')
          .replace(queryParameters: {'userId': userId});
      final response = await http.get(uri);
      debugPrint('FetchTransactions response: ${response.statusCode}');
      debugPrint('FetchTransactions body: ${response.body}');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded
              .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        if (decoded is Map<String, dynamic> && decoded['data'] is List) {
          final list = decoded['data'] as List;
          return list
              .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('TransactionService.fetchTransactions error: $e');
      return [];
    }
  }
}
