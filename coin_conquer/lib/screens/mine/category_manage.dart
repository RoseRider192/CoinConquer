import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart';
import '../../providers/category_provider.dart';
import '../../theme/colors.dart';

class CategoryManageScreen extends StatefulWidget {
  const CategoryManageScreen({super.key});

  @override
  State<CategoryManageScreen> createState() => _CategoryManageScreenState();
}

class _CategoryManageScreenState extends State<CategoryManageScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showAddDialog(String type) async {
    final nameCtrl = TextEditingController();
    final colors = ['0xFFEF4444', '0xFFF97316', '0xFFF59E0B', '0xFF22C55E', '0xFF06B6D4',
        '0xFF3B82F6', '0xFF6366F1', '0xFF8B5CF6', '0xFFEC4899', '0xFF78716C'];
    String selectedColor = colors[0];

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('添加${type == 'expense' ? '支出' : '收入'}分类'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: '分类名称', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: colors.map((c) {
                  final isSelected = selectedColor == c;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = c),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(int.parse(c)),
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Theme.of(ctx).colorScheme.onSurface, width: 3) : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) Navigator.pop(ctx, true);
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final provider = context.read<CategoryProvider>();
      await provider.addCategory(Category(
        name: nameCtrl.text,
        type: type,
        icon: 'custom',
        color: selectedColor,
        isDefault: 0,
      ));
    }
    nameCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分类管理'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: '支出'), Tab(text: '收入')],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(
          _tabController.index == 0 ? 'expense' : 'income',
        ),
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryList('expense'),
          _buildCategoryList('income'),
        ],
      ),
    );
  }

  Widget _buildCategoryList(String type) {
    return Consumer<CategoryProvider>(
      builder: (context, provider, child) {
        final categories = type == 'expense' ? provider.expenseCategories : provider.incomeCategories;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final color = Color(int.parse(cat.color));

            return Card(
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.circle, color: color, size: 16),
                ),
                title: Text(cat.name),
                subtitle: Text(cat.isDefault == 1 ? '预设分类' : '自定义分类', style: const TextStyle(fontSize: 12)),
                trailing: cat.isDefault == 1
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.expense),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('删除分类'),
                              content: Text('确定要删除"${cat.name}"吗？'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
                              ],
                            ),
                          );
                          if (confirm == true && cat.id != null) {
                            await provider.deleteCategory(cat.id!);
                          }
                        },
                      ),
              ),
            );
          },
        );
      },
    );
  }
}
