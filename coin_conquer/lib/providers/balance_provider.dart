import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BalanceProvider extends ChangeNotifier {
  double _balance = 0;
  bool _loaded = false;

  double get balance => _balance;
  bool get loaded => _loaded;

  Future<void> loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    _balance = prefs.getDouble('current_balance') ?? 0;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setBalance(double amount) async {
    _balance = double.parse(amount.toStringAsFixed(2));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('current_balance', _balance);
    notifyListeners();
  }

  void addIncome(double amount) {
    _balance = double.parse((_balance + amount).toStringAsFixed(2));
    _persist();
    notifyListeners();
  }

  void addExpense(double amount) {
    _balance = double.parse((_balance - amount).toStringAsFixed(2));
    _persist();
    notifyListeners();
  }

  void removeTransaction(String type, double amount) {
    if (type == 'income') {
      _balance = double.parse((_balance - amount).toStringAsFixed(2));
    } else {
      _balance = double.parse((_balance + amount).toStringAsFixed(2));
    }
    _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('current_balance', _balance);
  }
}
