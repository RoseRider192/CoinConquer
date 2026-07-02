import 'dart:convert';
import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../theme/colors.dart';
import '../../utils/date_utils.dart' as app_date;

class ImportRestoreScreen extends StatefulWidget {
  const ImportRestoreScreen({super.key});

  @override
  State<ImportRestoreScreen> createState() => _ImportRestoreScreenState();
}

class _ImportRestoreScreenState extends State<ImportRestoreScreen> {
  bool _isImporting = false;
  bool _isChecking = false;
  List<String> _conflicts = [];
  final _jsonController = TextEditingController();

  Future<void> _checkAndImport() async {
    final text = _jsonController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请粘贴备份JSON内容')),
      );
      return;
    }

    setState(() {
      _isChecking = true;
      _conflicts = [];
    });

    try {
      final data = jsonDecode(text) as Map<String, dynamic>;

      if (!data.containsKey('transactions') || !data.containsKey('categories')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无效的备份文件格式')),
          );
          setState(() => _isChecking = false);
        }
        return;
      }

      final conflicts = await _detectConflicts(data);
      setState(() {
        _conflicts = conflicts;
        _isChecking = false;
      });

      if (conflicts.isNotEmpty) {
        _showConflictDialog(data);
        return;
      }

      await _doImport(data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('JSON解析失败：$e')),
        );
        setState(() => _isChecking = false);
      }
    }
  }

  Future<List<String>> _detectConflicts(Map<String, dynamic> data) async {
    final db = DatabaseHelper.instance;
    final conflicts = <String>[];

    if (data['transactions'] == null) return conflicts;

    final importDates = <String>{};
    for (final t in (data['transactions'] as List)) {
      importDates.add(t['date'] as String);
    }

    final existingDates = <String, int>{};
    for (final date in importDates) {
      final count = await db.getTransactions(startDate: date, endDate: date);
      if (count.isNotEmpty) {
        existingDates[date] = count.length;
      }
    }

    if (existingDates.isNotEmpty) {
      final monthGroups = <String, int>{};
      for (final entry in existingDates.entries) {
        final month = entry.key.substring(0, 7);
        monthGroups[month] = (monthGroups[month] ?? 0) + entry.value;
      }
      for (final entry in monthGroups.entries) {
        conflicts.add('${app_date.DateUtils.formatMonthDisplay(entry.key)}：${entry.value}条记录重叠');
      }
    }

    return conflicts;
  }

  void _showConflictDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.expense, size: 28),
            SizedBox(width: 8),
            Text('检测到数据冲突', style: TextStyle(fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('导入的数据与现有数据在以下时间存在重叠：', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            ..._conflicts.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $c', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                )),
            const SizedBox(height: 12),
            const Text('建议先导出当前数据作为备份，再选择导入方式。',
                style: TextStyle(fontSize: 13, color: AppColors.expense)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _doImport(data);
            },
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('直接覆盖'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _exportBeforeImport();
              if (mounted) {
                _doImport(data);
              }
            },
            child: const Text('先备份再导入'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBeforeImport() async {
    try {
      final db = DatabaseHelper.instance;
      await db.exportAllData();
      final timestamp = DateTime.now();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('当前数据已备份于 ${timestamp.month}/${timestamp.day} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('备份失败：$e')),
        );
      }
    }
  }

  Future<void> _doImport(Map<String, dynamic> data) async {
    setState(() => _isImporting = true);
    try {
      final db = DatabaseHelper.instance;
      await db.importAllData(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('数据导入成功')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('导入数据恢复'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.income.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.file_upload, size: 32, color: AppColors.income),
            ),
            const SizedBox(height: 16),
            const Text(
              '导入数据恢复',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '将之前导出的JSON备份内容粘贴到下方，\n导入前会自动检测数据冲突。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _jsonController,
                maxLines: 10,
                decoration: const InputDecoration(
                  hintText: '在此粘贴备份JSON内容...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: (_isImporting || _isChecking) ? null : _checkAndImport,
                icon: _isImporting || _isChecking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check),
                label: Text(_isChecking ? '检测中...' : (_isImporting ? '导入中...' : '导入数据')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.income,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
