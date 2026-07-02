import 'package:flutter/material.dart';
import '../models/recurring_rule.dart';
import '../database/database_helper.dart';

class RecurringProvider extends ChangeNotifier {
  List<RecurringRule> _rules = [];

  List<RecurringRule> get rules => _rules;
  List<RecurringRule> get activeRules => _rules.where((r) => r.isActive == 1).toList();

  Future<void> loadRules() async {
    final db = DatabaseHelper.instance;
    _rules = await db.getRecurringRules();
    notifyListeners();
  }

  Future<int> addRule(RecurringRule rule) async {
    final db = DatabaseHelper.instance;
    final id = await db.insertRecurringRule(rule);
    await loadRules();
    return id;
  }

  Future<void> updateRule(RecurringRule rule) async {
    final db = DatabaseHelper.instance;
    await db.updateRecurringRule(rule);
    await loadRules();
  }

  Future<void> deleteRule(int id) async {
    final db = DatabaseHelper.instance;
    await db.deleteRecurringRule(id);
    await loadRules();
  }
}
