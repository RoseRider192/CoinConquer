import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../database/database_helper.dart';
import '../../theme/colors.dart';

class ExportBackupScreen extends StatefulWidget {
  const ExportBackupScreen({super.key});

  @override
  State<ExportBackupScreen> createState() => _ExportBackupScreenState();
}

class _ExportBackupScreenState extends State<ExportBackupScreen> {
  bool _isExporting = false;

  Future<void> _exportJson() async {
    setState(() => _isExporting = true);

    try {
      final db = DatabaseHelper.instance;
      final data = await db.exportAllData();

      final timestamp = DateTime.now();
      final fileName = 'CoinConquer_backup_'
          '${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}'
          '${timestamp.day.toString().padLeft(2, '0')}_'
          '${timestamp.hour.toString().padLeft(2, '0')}'
          '${timestamp.minute.toString().padLeft(2, '0')}'
          '.json';

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));

      final fileSize = (await file.length()) / 1024;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('备份成功：$fileName (${fileSize.toStringAsFixed(1)} KB)')),
        );
      }

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'CoinConquer 数据备份',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('导出数据备份'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.save_alt, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text(
              '导出数据备份(JSON)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '将包含所有收入支出记录、兼职信息、工时记录、预算和周期性账单的完整数据导出为JSON文件，可用于换手机后导入恢复。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _exportJson,
                icon: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.share),
                label: Text(_isExporting ? '导出中...' : '导出并分享'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '点击后将生成备份文件并通过系统分享功能发送',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
