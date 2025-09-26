import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';

class TransactionService {
  static const String _key = 'pending_transactions';
  static TransactionService? _instance;

  TransactionService._();

  static TransactionService get instance {
    _instance ??= TransactionService._();
    return _instance!;
  }

  Future<List<TransactionModel>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    return jsonList.map((json) => TransactionModel.fromJson(jsonDecode(json))).toList();
  }

  Future<void> saveTransactions(List<TransactionModel> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = transactions.map((tx) => jsonEncode(tx.toJson())).toList();
    await prefs.setStringList(_key, jsonList);
  }

  Future<void> addTransaction(TransactionModel tx) async {
    final transactions = await loadTransactions();
    transactions.add(tx);
    await saveTransactions(transactions);
  }

  Future<void> updateTransactionStatus(String txHash, String status) async {
    final transactions = await loadTransactions();
    final index = transactions.indexWhere((tx) => tx.txHash == txHash);
    if (index != -1) {
      transactions[index] = TransactionModel(
        txHash: txHash,
        description: transactions[index].description,
        timestamp: transactions[index].timestamp,
        status: status,
      );
      await saveTransactions(transactions);
    }
  }

  Future<void> removeTransaction(String txHash) async {
    final transactions = await loadTransactions();
    transactions.removeWhere((tx) => tx.txHash == txHash);
    await saveTransactions(transactions);
  }
}