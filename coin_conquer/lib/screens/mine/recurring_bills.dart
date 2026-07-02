import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/recurring_rule.dart';
import '../../providers/recurring_provider.dart';
import '../../providers/category_provider.dart';
import '../../theme/colors.dart';
import '../../utils/formatters.dart';

class RecurringBillsScreen extends StatefulWidget {
  const RecurringBillsScreen({super.key});

  @override
  State<RecurringBillsScreen> createState() => _RecurringBillsScreenState();
}

class _RecurringBillsScreenState extends State<RecurringBillsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<RecurringProvider>().loadRules();
  }

  Future<void> _showAddDialog() async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String type = 'expense';
    int? categoryId;
    String interval = 'monthly';
    int reminderEnabled = 0;

    final catProvider = context.read<CategoryProvider>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final categories = type == 'income'
              ? catProvider.incomeCategories
              : catProvider.expenseCategories;

          if (categoryId == null && categories.isNotEmpty) {
            categoryId = categories.first.id;
          }

          return AlertDialog(
            title: const Text('添加周期性账单'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'expense', label: Text('支出')),
                      ButtonSegment(value: 'income', label: Text('收入')),
                    ],
                    selected: {type},
                    onSelectionChanged: (s) {
                      setDialogState(() {
                        type = s.first;
                        categoryId = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: '金额',
                      prefixText: '¥',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: categoryId,
                    decoration: const InputDecoration(
                      labelText: '分类',
                      border: OutlineInputBorder(),
                    ),
                    items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (v) => setDialogState(() => categoryId = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: interval,
                    decoration: const InputDecoration(labelText: '周期', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'monthly', child: Text('每月')),
                      DropdownMenuItem(value: 'quarterly', child: Text('每季度')),
                      DropdownMenuItem(value: 'yearly', child: Text('每年')),
                    ],
                    onChanged: (v) => setDialogState(() => interval = v ?? 'monthly'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: reminderEnabled,
                    decoration: const InputDecoration(labelText: '处理方式', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('自动生成记录')),
                      DropdownMenuItem(value: 1, child: Text('提醒手动确认')),
                    ],
                    onChanged: (v) => setDialogState(() => reminderEnabled = v ?? 0),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(labelText: '备注(可选)', border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
              FilledButton(
                onPressed: () {
                  if (amountCtrl.text.isNotEmpty && categoryId != null) {
                    Navigator.pop(ctx, true);
                  }
                },
                child: const Text('添加'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && categoryId != null) {
      final now = DateTime.now();
      final nextDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final provider = context.read<RecurringProvider>();
      await provider.addRule(RecurringRule(
        amount: double.parse(amountCtrl.text),
        type: type,
        categoryId: categoryId!,
        note: noteCtrl.text.isNotEmpty ? noteCtrl.text : null,
        interval: interval,
        nextDate: nextDate,
        reminderEnabled: reminderEnabled,
      ));
    }

    amountCtrl.dispose();
    noteCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('周期性账单'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: Consumer<RecurringProvider>(
        builder: (context, provider, child) {
          if (provider.rules.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.repeat, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('还没有周期性账单', style: TextStyle(color: Colors.grey.shade500)),
                  const SizedBox(height: 8),
                  Text('点击右下角 + 添加', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.rules.length,
            itemBuilder: (context, index) {
              final rule = provider.rules[index];
              final catProvider = context.read<CategoryProvider>();
              final cat = catProvider.getCategoryById(rule.categoryId);

              final intervalLabel = {
                'monthly': '每月',
                'quarterly': '每季度',
                'yearly': '每年',
              }[rule.interval] ?? rule.interval;

              return Card(
                child: ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color(int.parse(cat?.color ?? '0xFF6366F1')).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.repeat, color: AppColors.primary),
                  ),
                  title: Text(
                    cat?.name ?? '未分类',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '¥${Formatters.formatAmount(rule.amount)} / $intervalLabel ${rule.reminderEnabled == 1 ? '(提醒确认)' : '(自动生成)'}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.expense),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('删除周期账单'),
                          content: const Text('确定要删除吗？'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
                          ],
                        ),
                      );
                      if (confirm == true && rule.id != null) {
                        await provider.deleteRule(rule.id!);
                      }
                    },
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
