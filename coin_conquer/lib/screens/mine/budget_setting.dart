import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/budget.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../theme/colors.dart';
import 'package:coin_conquer/utils/date_utils.dart' as app_date;

class BudgetSettingScreen extends StatefulWidget {
  const BudgetSettingScreen({super.key});

  @override
  State<BudgetSettingScreen> createState() => _BudgetSettingScreenState();
}

class _BudgetSettingScreenState extends State<BudgetSettingScreen> {
  String _selectedMonth = app_date.DateUtils.currentMonth();
  final Map<int, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveBudget(int categoryId, String text) async {
    final amount = double.tryParse(text);
    if (amount == null || amount <= 0) return;

    final provider = context.read<BudgetProvider>();
    await provider.saveBudget(Budget(
      categoryId: categoryId,
      amount: amount,
      month: _selectedMonth,
    ));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('预算已设置')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('预算设置'),
        centerTitle: true,
      ),
      body: Consumer2<CategoryProvider, BudgetProvider>(
        builder: (context, catProvider, budgetProvider, child) {
          final categories = catProvider.expenseCategories;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Center(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          initialDatePickerMode: DatePickerMode.year,
                        );
                        if (picked != null) {
                          final newMonth = '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
                          setState(() => _selectedMonth = newMonth);
                          budgetProvider.loadBudgets(newMonth);
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          app_date.DateUtils.formatMonthDisplay(_selectedMonth),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              final cat = categories[index - 1];
              final budget = budgetProvider.getBudgetForCategory(cat.id!, _selectedMonth);

              if (!_controllers.containsKey(cat.id)) {
                _controllers[cat.id!] = TextEditingController(
                  text: budget?.amount.toString() ?? '',
                );
              }

              final controller = _controllers[cat.id!]!;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(int.parse(cat.color)).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            cat.name[0],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(int.parse(cat.color)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(cat.name, style: const TextStyle(fontSize: 15)),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: controller,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            prefixText: '¥',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            isDense: true,
                          ),
                          onSubmitted: (v) => _saveBudget(cat.id!, v),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.check, color: AppColors.primary, size: 20),
                        onPressed: () => _saveBudget(cat.id!, controller.text),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
