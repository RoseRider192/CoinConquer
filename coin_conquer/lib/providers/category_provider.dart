import 'package:flutter/material.dart';
import '../models/category.dart';
import '../database/database_helper.dart';

class CategoryProvider extends ChangeNotifier {
  List<Category> _expenseCategories = [];
  List<Category> _incomeCategories = [];
  List<Category> _allCategories = [];

  List<Category> get expenseCategories => _expenseCategories;
  List<Category> get incomeCategories => _incomeCategories;
  List<Category> get allCategories => _allCategories;

  Future<void> loadCategories() async {
    final db = DatabaseHelper.instance;
    _allCategories = await db.getCategories();
    _expenseCategories = _allCategories.where((c) => c.type == 'expense').toList();
    _incomeCategories = _allCategories.where((c) => c.type == 'income').toList();
    notifyListeners();
  }

  Category? getCategoryById(int id) {
    try {
      return _allCategories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addCategory(Category category) async {
    final db = DatabaseHelper.instance;
    await db.insertCategory(category);
    await loadCategories();
  }

  Future<void> updateCategory(Category category) async {
    final db = DatabaseHelper.instance;
    await db.updateCategory(category);
    await loadCategories();
  }

  Future<void> deleteCategory(int id) async {
    final db = DatabaseHelper.instance;
    await db.deleteCategory(id);
    await loadCategories();
  }
}
