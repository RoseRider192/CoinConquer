import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../statistics/export_backup.dart';
import '../statistics/export_report.dart';
import 'import_restore.dart';
import 'budget_setting.dart';
import 'recurring_bills.dart';
import 'category_manage.dart';
import 'remind_export.dart';
import '../../theme/colors.dart';

class MineScreen extends StatelessWidget {
  const MineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('我的'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _buildSectionHeader('数据管理'),
          _buildItem(context, icon: CupertinoIcons.doc_text, title: '导出报告(PDF)', onTap: () {
            Navigator.push(context, CupertinoPageRoute(builder: (_) => const ExportReportScreen()));
          }),
          _buildItem(context, icon: CupertinoIcons.square_arrow_down, title: '导出数据备份(JSON)', onTap: () {
            Navigator.push(context, CupertinoPageRoute(builder: (_) => const ExportBackupScreen()));
          }),
          _buildItem(context, icon: CupertinoIcons.square_arrow_up, title: '导入数据恢复', onTap: () {
            Navigator.push(context, CupertinoPageRoute(builder: (_) => const ImportRestoreScreen()));
          }),
          _buildSectionHeader('功能管理'),
          _buildItem(context, icon: CupertinoIcons.money_dollar_circle, title: '预算设置', onTap: () {
            Navigator.push(context, CupertinoPageRoute(builder: (_) => const BudgetSettingScreen()));
          }),
          _buildItem(context, icon: CupertinoIcons.repeat, title: '周期性账单', onTap: () {
            Navigator.push(context, CupertinoPageRoute(builder: (_) => const RecurringBillsScreen()));
          }),
          _buildItem(context, icon: CupertinoIcons.square_grid_2x2, title: '分类管理', onTap: () {
            Navigator.push(context, CupertinoPageRoute(builder: (_) => const CategoryManageScreen()));
          }),
          _buildSectionHeader('提醒与帮助'),
          _buildItem(context, icon: CupertinoIcons.bell, title: '定期提醒导出', onTap: () {
            Navigator.push(context, CupertinoPageRoute(builder: (_) => const RemindExportScreen()));
          }),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
    );
  }

  Widget _buildItem(BuildContext context, {required IconData icon, required String title, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Material(
        color: AppColors.background,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.separator, width: 0.5))),
            child: Row(
              children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, size: 18, color: AppColors.primary)),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary))),
                const Icon(CupertinoIcons.chevron_right, size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
