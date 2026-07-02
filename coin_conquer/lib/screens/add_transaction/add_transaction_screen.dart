import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../theme/colors.dart';
import '../../models/category.dart';
import '../../models/transaction.dart';
import '../../models/work_session.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/balance_provider.dart';
import '../../database/database_helper.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  String _type = 'expense';
  Category? _selectedCategory;
  final _customNameController = TextEditingController();
  final _noteController = TextEditingController();
  final _hoursController = TextEditingController();
  final _rateController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _amountDisplay = '0';
  bool _isPartTime = false;
  bool _saving = false;

  bool get _isValid {
    final amount = double.tryParse(_amountDisplay);
    if (amount == null || amount <= 0) return false;
    if (_type == 'expense' && _selectedCategory == null) return false;
    return true;
  }

  void _onNumberPress(String value) {
    setState(() {
      if (value == '.') {
        if (!_amountDisplay.contains('.')) {
          _amountDisplay += '.';
        }
      } else if (value == 'delete') {
        if (_amountDisplay.length > 1) {
          _amountDisplay = _amountDisplay.substring(0, _amountDisplay.length - 1);
          if (_amountDisplay == '-') _amountDisplay = '0';
        } else {
          _amountDisplay = '0';
        }
      } else if (value == 'clear') {
        _amountDisplay = '0';
      } else {
        final parts = _amountDisplay.split('.');
        if (parts.length == 2 && parts[1].length >= 2) return;
        if (_amountDisplay == '0') {
          _amountDisplay = value;
        } else {
          _amountDisplay += value;
        }
      }
      _updatePartTimeAmount();
    });
  }

  void _updatePartTimeAmount() {
    if (!_isPartTime) return;
    final hours = double.tryParse(_hoursController.text) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;
    if (hours > 0 && rate > 0) {
      final total = hours * rate;
      setState(() {
        _amountDisplay = total.toStringAsFixed(2);
      });
    }
  }

  Future<void> _save() async {
    if (!_isValid || _saving) return;
    final amount = double.tryParse(_amountDisplay);
    if (amount == null || amount <= 0) return;
    if (_type == 'expense' && _selectedCategory == null) return;

    setState(() => _saving = true);

    final dateStr2 = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    final catProvider = context.read<CategoryProvider>();
    final catId = _type == 'expense'
        ? _selectedCategory!.id!
        : (_isPartTime
            ? (catProvider.incomeCategories.firstWhere((c) => c.name == '兼职', orElse: () => catProvider.incomeCategories.first).id!)
            : (_selectedCategory?.id ?? catProvider.incomeCategories.first.id!));

    final transaction = Transaction(
      amount: amount,
      type: _type,
      categoryId: catId,
      customName: _type == 'income' && _customNameController.text.isNotEmpty
          ? _customNameController.text
          : (_isPartTime ? '兼职收入' : null),
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
      date: dateStr2,
    );

    final txProvider = context.read<TransactionProvider>();
    await txProvider.addTransaction(transaction);

    final balanceProvider = context.read<BalanceProvider>();
    if (_type == 'income') {
      balanceProvider.addIncome(amount);
    } else {
      balanceProvider.addExpense(amount);
    }

    if (_isPartTime) {
      final hours = double.tryParse(_hoursController.text) ?? 0;
      final rate = double.tryParse(_rateController.text) ?? 0;
      if (hours > 0 && rate > 0) {
        final db = DatabaseHelper.instance;
        await db.insertWorkSession(WorkSession(
          jobId: 0,
          hoursWorked: hours,
          hourlyRate: rate,
          totalIncome: amount,
          date: dateStr2,
          note: _noteController.text.isNotEmpty ? _noteController.text : null,
        ));
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('记账成功'), duration: Duration(seconds: 1)),
      );
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  void dispose() {
    _customNameController.dispose();
    _noteController.dispose();
    _hoursController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('记账', style: TextStyle(color: AppColors.textPrimary)),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('取消', style: TextStyle(fontSize: 16, color: AppColors.primary)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('保存', style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _isValid ? AppColors.primary : AppColors.textSecondary,
              )),
              onPressed: _isValid && !_saving ? _save : null,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          children: [
            _buildTypeToggle(),
            const SizedBox(height: 16),
            _buildAmountDisplay(),
            const SizedBox(height: 12),
            _buildCategoryPicker(),
            if (_type == 'income') ...[
              const SizedBox(height: 12),
              _buildPartTimeToggle(),
              if (_isPartTime) ...[
                const SizedBox(height: 10),
                _buildPartTimeFields(),
              ],
              if (!_isPartTime) ...[
                const SizedBox(height: 10),
                CupertinoTextField(
                  controller: _customNameController,
                  placeholder: '收入来源名称(如：工资、奖金)',
                  padding: const EdgeInsets.all(12),
                ),
              ],
            ],
            const SizedBox(height: 10),
            CupertinoTextField(
              controller: _noteController,
              placeholder: '备注(可选)',
              padding: const EdgeInsets.all(12),
            ),
            const SizedBox(height: 10),
            _buildDateSelector(),
            const SizedBox(height: 10),
            _buildNumberPad(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() { _type = 'expense'; _selectedCategory = null; }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _type == 'expense' ? AppColors.expense : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '支出',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _type == 'expense' ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() { _type = 'income'; _selectedCategory = null; }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _type == 'income' ? AppColors.income : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '收入',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _type == 'income' ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountDisplay() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        '¥$_amountDisplay',
        style: TextStyle(
          fontSize: 46,
          fontWeight: FontWeight.w300,
          color: _type == 'income' ? AppColors.income : AppColors.expense,
          letterSpacing: -1,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCategoryPicker() {
    return Consumer<CategoryProvider>(
      builder: (context, catProvider, child) {
        final categories = _type == 'income'
            ? catProvider.incomeCategories
            : catProvider.expenseCategories;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((cat) {
            final isSelected = _selectedCategory?.id == cat.id;
            final color = Color(int.parse(cat.color));
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.12) : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? color : Colors.transparent, width: 1),
                ),
                child: Text(
                  cat.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? color : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPartTimeToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('兼职收入', style: TextStyle(fontSize: 15, color: AppColors.textPrimary)),
          CupertinoSwitch(
            value: _isPartTime,
            activeColor: AppColors.primary,
            onChanged: (v) {
              setState(() {
                _isPartTime = v;
                if (v) {
                  _amountDisplay = '0';
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPartTimeFields() {
    return Row(
      children: [
        Expanded(
          child: CupertinoTextField(
            controller: _hoursController,
            placeholder: '工时(小时)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            padding: const EdgeInsets.all(12),
            onChanged: (_) => _updatePartTimeAmount(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CupertinoTextField(
            controller: _rateController,
            placeholder: '时薪(¥/h)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefix: const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Text('¥', style: TextStyle(color: AppColors.textSecondary)),
            ),
            padding: const EdgeInsets.fromLTRB(4, 12, 12, 12),
            onChanged: (_) => _updatePartTimeAmount(),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(CupertinoIcons.calendar, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            const Text('日期', style: TextStyle(fontSize: 15, color: AppColors.textPrimary)),
            const Spacer(),
            Text(
              '${_selectedDate.month}月${_selectedDate.day}日',
              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 4),
            const Icon(CupertinoIcons.chevron_right, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    final buttons = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', 'delete'],
    ];

    return Column(
      children: buttons.map((row) {
        return Row(
          children: row.map((btn) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: _buildNumberButton(btn),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  Widget _buildNumberButton(String label) {
    String displayLabel = label;
    IconData? icon;
    Color bgColor = AppColors.surface;
    Color textColor = AppColors.textPrimary;

    if (label == 'delete') {
      icon = CupertinoIcons.delete_left;
      displayLabel = '';
    }

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _onNumberPress(label),
      color: bgColor,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: icon != null
            ? Icon(icon, size: 22, color: textColor)
            : Text(
                displayLabel,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, color: textColor),
              ),
      ),
    );
  }
}
