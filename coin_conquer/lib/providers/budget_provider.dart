import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../database/database_helper.dart';

class BudgetProvider extends ChangeNotifier {
  List<Budget> _budgets = [];

  List<Budget> get budgets => _budgets;

  Future<void> loadBudgets(String month) async {
    final db = DatabaseHelper.instance;
    _budgets = await db.getBudgets(month);
    notifyListeners();
  }

  Future<void> saveBudget(Budget budget) async {
    final db = DatabaseHelper.instance;
    await db.saveBudget(budget);
    await loadBudgets(budget.month);
  }

  Budget? getBudgetForCategory(int categoryId, String month) {
    try {
      return _budgets.firstWhere((b) => b.categoryId == categoryId && b.month == month);
    } catch (_) {
      return null;
    }
  }
}
