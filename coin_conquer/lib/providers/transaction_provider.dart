import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../database/database_helper.dart';

class TransactionProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  List<Transaction> _recentTransactions = [];
  double _monthlyIncome = 0;
  double _monthlyExpense = 0;
  Set<String> _datesWithTransactions = {};

  List<Transaction> get transactions => _transactions;
  List<Transaction> get recentTransactions => _recentTransactions;
  double get monthlyIncome => _monthlyIncome;
  double get monthlyExpense => _monthlyExpense;
  double get monthlyBalance => _monthlyIncome - _monthlyExpense;
  Set<String> get datesWithTransactions => _datesWithTransactions;

  Future<void> loadTransactions({
    String? type,
    String? startDate,
    String? endDate,
    int? limit,
  }) async {
    final db = DatabaseHelper.instance;
    _transactions = await db.getTransactions(
      type: type,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
    notifyListeners();
  }

  Future<void> loadRecentTransactions({int limit = 10}) async {
    final db = DatabaseHelper.instance;
    _recentTransactions = await db.getTransactions(limit: limit);
    notifyListeners();
  }

  Future<void> loadMonthlySummary(String startDate, String endDate) async {
    final db = DatabaseHelper.instance;
    _monthlyIncome = await db.getTotalIncome(startDate, endDate);
    _monthlyExpense = await db.getTotalExpense(startDate, endDate);
    notifyListeners();
  }

  Future<void> loadDatesWithTransactions(String yearMonth) async {
    final db = DatabaseHelper.instance;
    _datesWithTransactions = await db.getDatesWithTransactions(yearMonth);
    notifyListeners();
  }

  Future<int> addTransaction(Transaction transaction) async {
    final db = DatabaseHelper.instance;
    final id = await db.insertTransaction(transaction);
    await loadRecentTransactions();
    return id;
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final db = DatabaseHelper.instance;
    await db.updateTransaction(transaction);
    await loadRecentTransactions();
  }

  Future<void> deleteTransaction(int id) async {
    final db = DatabaseHelper.instance;
    await db.deleteTransaction(id);
    await loadRecentTransactions();
  }
}
