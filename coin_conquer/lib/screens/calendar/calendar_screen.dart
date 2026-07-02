import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/balance_provider.dart';
import '../../theme/colors.dart';
import '../../utils/formatters.dart';
import 'package:coin_conquer/utils/date_utils.dart' as app_date;
import '../../models/transaction.dart';
import '../../database/database_helper.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> {
  late DateTime _currentMonth;
  DateTime? _selectedDate;
  Map<String, double> _dailyHours = {};
  double _monthlyHours = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadData();
  }

  void loadData() async {
    if (!mounted) return;
    final txProvider = context.read<TransactionProvider>();
    final monthKey = app_date.DateUtils.currentMonth();
    final startDate = app_date.DateUtils.monthStart(monthKey);
    final endDate = app_date.DateUtils.monthEnd(monthKey);

    txProvider.loadMonthlySummary(startDate, endDate);
    txProvider.loadDatesWithTransactions(monthKey);
    txProvider.loadRecentTransactions(limit: 10);

    final db = DatabaseHelper.instance;
    final dailyHours = await db.getDailyHours(monthKey);
    final monthlyHours = await db.getMonthlyHours(monthKey);

    if (_selectedDate != null) {
      _loadDayTransactions(_selectedDate!);
    }

    if (mounted) {
      setState(() {
        _dailyHours = dailyHours;
        _monthlyHours = monthlyHours;
      });
    }
  }

  void _loadDayTransactions(DateTime date) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    context.read<TransactionProvider>().loadTransactions(startDate: dateStr, endDate: dateStr);
  }

  void _previousMonth() {
    setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1));
    loadData();
  }

  void _nextMonth() {
    setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1));
    loadData();
  }

  void _onDateSelected(DateTime date) {
    setState(() => _selectedDate = date);
    _loadDayTransactions(date);
  }

  Future<void> _deleteTransaction(Transaction t) async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('删除记录'),
        content: Text('确定要删除这条${t.type == 'income' ? '收入' : '支出'}记录吗？'),
        actions: [
          CupertinoDialogAction(child: const Text('取消'), onPressed: () => Navigator.pop(ctx, false)),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('删除'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final txProvider = context.read<TransactionProvider>();
      final balanceProvider = context.read<BalanceProvider>();
      final db = DatabaseHelper.instance;
      balanceProvider.removeTransaction(t.type, t.amount);
      await db.deleteWorkSessionsByDateAndAmount(t.date, t.amount);
      await txProvider.deleteTransaction(t.id!);
      loadData();
    }
  }

  Future<void> _editNote(Transaction t) async {
    final controller = TextEditingController(text: t.note ?? '');
    final result = await showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('修改备注', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: controller,
              placeholder: '输入备注...',
              padding: const EdgeInsets.all(12),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                child: const Text('保存'),
                onPressed: () => Navigator.pop(ctx, controller.text),
              ),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      final txProvider = context.read<TransactionProvider>();
      final db = DatabaseHelper.instance;
      final updated = t.copyWith(
        note: result.isNotEmpty ? result : null,
      );
      await txProvider.updateTransaction(updated);
      await db.updateWorkSessionNoteByMatch(t.date, t.amount, result.isNotEmpty ? result : null);
      loadData();
    }
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('硬币征服者'),
        centerTitle: true,
        backgroundColor: AppColors.background,
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, txProvider, child) {
          return RefreshIndicator(
            onRefresh: () async => loadData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildMonthSummary(txProvider),
                  _buildCalendarHeader(),
                  _buildCalendarGrid(txProvider),
                  const SizedBox(height: 8),
                  _buildDayDetail(txProvider),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthSummary(TransactionProvider txProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: _summaryCard('收入', txProvider.monthlyIncome, AppColors.income),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryCard('支出', txProvider.monthlyExpense, AppColors.expense),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            '¥${Formatters.formatAmountCompact(amount)}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.chevron_left, size: 22, color: AppColors.primary),
            onPressed: _previousMonth,
          ),
          Column(
            children: [
              Text(
                '${_currentMonth.year}年${_currentMonth.month}月',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              if (_monthlyHours > 0)
                Text(
                  '总工时 ${_monthlyHours.toStringAsFixed(1)}h',
                  style: const TextStyle(fontSize: 11, color: AppColors.primary),
                ),
            ],
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.chevron_right, size: 22, color: AppColors.primary),
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(TransactionProvider txProvider) {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final firstWeekday = firstDay.weekday % 7;

    final List<Widget> dayWidgets = [];

    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    for (final day in weekdays) {
      dayWidgets.add(Center(
        child: Text(day, style: TextStyle(
          fontSize: 12,
          color: (day == '六' || day == '日') ? AppColors.expense : AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        )),
      ));
    }

    for (int i = 0; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox());
    }

    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final isToday = dateStr == todayStr;
      final isSelected = _selectedDate != null &&
          date.year == _selectedDate!.year &&
          date.month == _selectedDate!.month &&
          date.day == _selectedDate!.day;
      final isFuture = date.isAfter(DateTime(today.year, today.month, today.day));
      final hasData = txProvider.datesWithTransactions.contains(dateStr);
      final hours = _dailyHours[dateStr];
      final hasHours = hours != null && hours > 0;

      dayWidgets.add(
        GestureDetector(
          onTap: isFuture ? null : () => _onDateSelected(date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : (isToday ? AppColors.primary.withValues(alpha: 0.12) : null),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected
                        ? Colors.white
                        : isFuture
                            ? const Color(0xFFC7C7CC)
                            : (isToday ? AppColors.primary : AppColors.textPrimary),
                  ),
                ),
                if (hasHours)
                  Text(
                    '${hours.toStringAsFixed(1)}h',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white70 : AppColors.primary,
                    ),
                  )
                else if (hasData)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.1,
        children: dayWidgets,
      ),
    );
  }

  Widget _buildDayDetail(TransactionProvider txProvider) {
    if (_selectedDate == null) return const SizedBox.shrink();

    final dateStr = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
    final dayTransactions = txProvider.transactions
        .where((t) => t.date == dateStr)
        .toList();

    double dayIncome = 0;
    double dayExpense = 0;
    for (final t in dayTransactions) {
      if (t.type == 'income') {
        dayIncome += t.amount;
      } else {
        dayExpense += t.amount;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_selectedDate!.month}月${_selectedDate!.day}日',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 12),
                Text(
                  '收 ¥${Formatters.formatAmountCompact(dayIncome)}',
                  style: const TextStyle(fontSize: 13, color: AppColors.income, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 12),
                Text(
                  '支 ¥${Formatters.formatAmountCompact(dayExpense)}',
                  style: const TextStyle(fontSize: 13, color: AppColors.expense, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          if (dayTransactions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('当天没有记录', style: TextStyle(color: AppColors.textSecondary))),
            )
          else
            ...dayTransactions.map((t) {
              final catProvider = context.read<CategoryProvider>();
              final cat = catProvider.getCategoryById(t.categoryId);
              final color = Color(int.parse(cat?.color ?? '0xFF007AFF'));

              return GestureDetector(
                onTap: () => _editNote(t),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.separator, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_getCategoryIcon(cat?.icon ?? 'other'), size: 20, color: color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.customName ?? cat?.name ?? '未分类',
                              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                            ),
                            if (t.note != null && t.note!.isNotEmpty)
                              Text(t.note!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Text(
                        Formatters.formatAmountSigned(t.type, t.amount),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: t.type == 'income' ? AppColors.income : AppColors.expense,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _deleteTransaction(t),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(CupertinoIcons.delete, size: 18, color: AppColors.expense),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String icon) {
    switch (icon) {
      case 'food': return CupertinoIcons.cart;
      case 'transport': return CupertinoIcons.car;
      case 'clothing': return CupertinoIcons.bag;
      case 'entertainment': return CupertinoIcons.game_controller;
      case 'education': return CupertinoIcons.book;
      case 'work': return CupertinoIcons.briefcase;
      case 'medical': return CupertinoIcons.heart;
      case 'social': return CupertinoIcons.gift;
      case 'salary': return CupertinoIcons.money_dollar_circle;
      case 'parttime': return CupertinoIcons.time;
      case 'investment': return CupertinoIcons.chart_bar;
      default: return CupertinoIcons.circle;
    }
  }
}
