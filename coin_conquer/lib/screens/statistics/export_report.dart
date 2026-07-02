import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../theme/colors.dart';
import '../../utils/formatters.dart';
import 'package:coin_conquer/utils/date_utils.dart' as app_date;

class ExportReportScreen extends StatefulWidget {
  const ExportReportScreen({super.key});

  @override
  State<ExportReportScreen> createState() => _ExportReportScreenState();
}

class _ExportReportScreenState extends State<ExportReportScreen> {
  String _reportType = 'monthly';
  String _selectedYear = DateTime.now().year.toString();
  String _selectedMonth = app_date.DateUtils.currentMonth();
  bool _exporting = false;

  Future<void> _exportPDF() async {
    setState(() => _exporting = true);
    try {
      final db = DatabaseHelper.instance;

      String startDate, endDate, title;
      if (_reportType == 'monthly') {
        startDate = app_date.DateUtils.monthStart(_selectedMonth);
        endDate = app_date.DateUtils.monthEnd(_selectedMonth);
        title = app_date.DateUtils.formatMonthDisplay(_selectedMonth);
      } else {
        startDate = app_date.DateUtils.yearStart(_selectedYear);
        endDate = app_date.DateUtils.yearEnd(_selectedYear);
        title = '$_selectedYear年';
      }

      final totalIncome = await db.getTotalIncome(startDate, endDate);
      final totalExpense = await db.getTotalExpense(startDate, endDate);
      final expenseSummary = await db.getCategorySummary('expense', startDate, endDate);
      final incomeSummary = await db.getCategorySummary('income', startDate, endDate);

      final pdf = pw.Document();

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('硬币征服者', style: const pw.TextStyle(fontSize: 20))),
          pw.Header(level: 1, child: pw.Text('$title 收支报告', style: const pw.TextStyle(fontSize: 14))),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _ps('总收入', totalIncome, PdfColors.green),
                _ps('总支出', totalExpense, PdfColors.red),
                _ps('结余', totalIncome - totalExpense, (totalIncome - totalExpense) >= 0 ? PdfColors.green : PdfColors.red),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Header(level: 2, child: pw.Text('支出明细', style: const pw.TextStyle(fontSize: 13))),
          pw.SizedBox(height: 6),
          _pdfTable(expenseSummary, totalExpense),
          pw.SizedBox(height: 16),
          pw.Header(level: 2, child: pw.Text('收入明细', style: const pw.TextStyle(fontSize: 13))),
          pw.SizedBox(height: 6),
          _pdfTable(incomeSummary, totalIncome),
          pw.SizedBox(height: 16),
          pw.Text('导出时间：${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 9)),
        ],
      ));

      final dir = await getApplicationDocumentsDirectory();
      final fileName = _reportType == 'monthly'
          ? '硬币征服者_${_selectedMonth}_报告.pdf'
          : '硬币征服者_${_selectedYear}_报告.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('报告已生成：$fileName')));
        await Share.shareXFiles([XFile(file.path)], subject: fileName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导出失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  pw.Widget _ps(String label, double amount, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 2),
        pw.Text('¥${Formatters.formatAmount(amount)}', style: pw.TextStyle(fontSize: 13, color: color)),
      ],
    );
  }

  pw.Widget _pdfTable(List<Map<String, dynamic>> data, double total) {
    if (data.isEmpty) return pw.Text('暂无数据', style: const pw.TextStyle(fontSize: 11));

    final rows = <pw.TableRow>[];
    rows.add(pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('分类', style: const pw.TextStyle(fontSize: 11))),
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('金额', style: const pw.TextStyle(fontSize: 11))),
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('占比', style: const pw.TextStyle(fontSize: 11))),
      ],
    ));

    for (final d in data) {
      final amount = (d['total'] as num).toDouble();
      final pct = total > 0 ? (amount / total * 100).toStringAsFixed(1) : '0.0';
      rows.add(pw.TableRow(children: [
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(d['name'] as String? ?? '', style: const pw.TextStyle(fontSize: 11))),
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('¥${Formatters.formatAmount(amount)}', style: const pw.TextStyle(fontSize: 11))),
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('$pct%', style: const pw.TextStyle(fontSize: 11))),
      ]));
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(1.5), 2: const pw.FlexColumnWidth(1)},
      children: rows,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('导出报告')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
              child: const Icon(CupertinoIcons.doc_text, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text('导出报告', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('生成PDF格式的收支报告', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'monthly', label: Text('月度报告')),
                ButtonSegment(value: 'yearly', label: Text('年度报告')),
              ],
              selected: {_reportType},
              onSelectionChanged: (s) => setState(() => _reportType = s.first),
            ),
            const SizedBox(height: 16),
            if (_reportType == 'monthly') _monthSelector() else _yearSelector(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 48,
              child: CupertinoButton.filled(
                child: _exporting ? const CupertinoActivityIndicator(color: Colors.white) : const Text('导出PDF'),
                onPressed: _exporting ? null : _exportPDF,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthSelector() {
    final parts = _selectedMonth.split('-');
    final y = int.tryParse(parts[0]) ?? DateTime.now().year;
    final m = int.tryParse(parts[1]) ?? DateTime.now().month;
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context, initialDate: DateTime(y, m),
          firstDate: DateTime(2020), lastDate: DateTime.now(),
          initialDatePickerMode: DatePickerMode.year,
        );
        if (picked != null) {
          setState(() => _selectedMonth = '${picked.year}-${picked.month.toString().padLeft(2, '0')}');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(app_date.DateUtils.formatMonthDisplay(_selectedMonth),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary)),
          const SizedBox(width: 8),
          const Icon(CupertinoIcons.chevron_down, size: 16, color: AppColors.primary),
        ]),
      ),
    );
  }

  Widget _yearSelector() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context, initialDate: DateTime(int.tryParse(_selectedYear) ?? DateTime.now().year),
          firstDate: DateTime(2020), lastDate: DateTime.now(),
          initialDatePickerMode: DatePickerMode.year,
        );
        if (picked != null) setState(() => _selectedYear = picked.year.toString());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('${_selectedYear}年', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary)),
          const SizedBox(width: 8),
          const Icon(CupertinoIcons.chevron_down, size: 16, color: AppColors.primary),
        ]),
      ),
    );
  }
}
