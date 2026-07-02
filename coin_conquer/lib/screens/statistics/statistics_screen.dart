import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/balance_provider.dart';
import '../../database/database_helper.dart';
import '../../theme/colors.dart';
import '../../utils/formatters.dart';
import '../statistics/export_report.dart';
import 'package:coin_conquer/utils/date_utils.dart' as app_date;

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedYearMonth = app_date.DateUtils.currentMonth();
  List<Map<String, dynamic>> _expenseSummary = [];
  List<Map<String, dynamic>> _incomeSummary = [];
  List<Map<String, dynamic>> _monthlyTrends = [];
  double _totalIncome = 0;
  double _totalExpense = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final db = DatabaseHelper.instance;
    final startDate = app_date.DateUtils.monthStart(_selectedYearMonth);
    final endDate = app_date.DateUtils.monthEnd(_selectedYearMonth);

    final expenseSummary = await db.getCategorySummary('expense', startDate, endDate);
    final incomeSummary = await db.getCategorySummary('income', startDate, endDate);
    final monthlyTrends = await db.getMonthlyTrends(12);
    final totalIncome = await db.getTotalIncome(startDate, endDate);
    final totalExpense = await db.getTotalExpense(startDate, endDate);

    if (mounted) {
      setState(() {
        _expenseSummary = expenseSummary;
        _incomeSummary = incomeSummary;
        _monthlyTrends = monthlyTrends;
        _totalIncome = totalIncome;
        _totalExpense = totalExpense;
      });
    }
  }

  Future<void> _editBalance() async {
    final balanceProvider = context.read<BalanceProvider>();
    final controller = TextEditingController(text: balanceProvider.balance.toStringAsFixed(2));

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
            const Text('修改余额', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('确定要修改当前余额吗？', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: controller,
              placeholder: '输入新余额',
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              prefix: const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Text('¥', style: TextStyle(color: AppColors.textSecondary)),
              ),
              padding: const EdgeInsets.fromLTRB(4, 12, 12, 12),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    child: const Text('取消'),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
                Expanded(
                  child: CupertinoButton.filled(
                    child: const Text('确认修改'),
                    onPressed: () => Navigator.pop(ctx, controller.text),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
          ],
        ),
      ),
    );

    if (result != null) {
      final amount = double.tryParse(result);
      if (amount != null && mounted) {
        await balanceProvider.setBalance(amount);
      }
    }
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('统计'),
        actions: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: const Icon(CupertinoIcons.square_arrow_up, size: 22, color: AppColors.primary),
            onPressed: () {
              Navigator.push(context, CupertinoPageRoute(builder: (_) => const ExportReportScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildBalanceCard(),
          _buildMonthSelector(),
          _buildSummaryRow(),
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [Tab(text: '分类'), Tab(text: '趋势'), Tab(text: '月度报告')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildCategoryTab(), _buildTrendTab(), _buildMonthlyReportTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Consumer<BalanceProvider>(
      builder: (context, provider, child) {
        return GestureDetector(
          onTap: _editBalance,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF5856D6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                const Text('当前余额', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Text(
                  '¥${Formatters.formatAmount(provider.balance)}',
                  style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w300, letterSpacing: -1),
                ),
                const SizedBox(height: 4),
                const Text('点击修改余额', style: TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthSelector() {
    return GestureDetector(
      onTap: () async {
        final parts = _selectedYearMonth.split('-');
        final y = int.tryParse(parts[0]) ?? DateTime.now().year;
        final m = int.tryParse(parts[1]) ?? DateTime.now().month;
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime(y, m),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          initialDatePickerMode: DatePickerMode.year,
        );
        if (picked != null) {
          final newVal = '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
          if (newVal != _selectedYearMonth) {
            setState(() => _selectedYearMonth = newVal);
            _loadData();
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.calendar, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(app_date.DateUtils.formatMonthDisplay(_selectedYearMonth),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(child: _miniCard('收入', _totalIncome, AppColors.income)),
          const SizedBox(width: 8),
          Expanded(child: _miniCard('支出', _totalExpense, AppColors.expense)),
        ],
      ),
    );
  }

  Widget _miniCard(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 3),
          Text(Formatters.formatAmountCompact(amount),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildCategoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('支出分类占比', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _expenseSummary.isEmpty ? _empty() : SizedBox(height: 200, child: _pie(_expenseSummary)),
          ..._expenseSummary.take(8).map((e) => _legendItem(e)),
          const SizedBox(height: 20),
          const Text('收入分类占比', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _incomeSummary.isEmpty ? _empty() : SizedBox(height: 200, child: _pie(_incomeSummary)),
          ..._incomeSummary.take(6).map((e) => _legendItem(e)),
        ],
      ),
    );
  }

  Widget _empty() => Container(height: 120, alignment: Alignment.center, child: const Text('暂无数据', style: TextStyle(color: AppColors.textSecondary)));

  Color _getColor(int i, String? c) => c != null ? Color(int.parse(c)) : AppColors.categoryColors[i % AppColors.categoryColors.length];

  Widget _pie(List<Map<String, dynamic>> data) {
    final nonZero = data.where((d) => (d['total'] as num).toDouble() > 0).toList();
    if (nonZero.isEmpty) return _empty();
    final total = nonZero.fold<double>(0, (s, d) => s + (d['total'] as num).toDouble());
    return PieChart(PieChartData(
      sections: nonZero.asMap().entries.map((e) {
        final pct = (e.value['total'] as num).toDouble() / total * 100;
        return PieChartSectionData(
          value: (e.value['total'] as num).toDouble(), color: _getColor(e.key, e.value['color'] as String?),
          radius: 70, title: '${pct.toStringAsFixed(0)}%',
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        );
      }).toList(),
      sectionsSpace: 2, centerSpaceRadius: 30,
    ));
  }

  Widget _legendItem(Map<String, dynamic> d) {
    final amount = (d['total'] as num).toDouble();
    final total = _expenseSummary.contains(d) ? _totalExpense : _totalIncome;
    final pct = total > 0 ? (amount / total * 100) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: _getColor(0, d['color'] as String?), shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(d['name'] as String? ?? '', style: const TextStyle(fontSize: 13))),
        Text('¥${Formatters.formatAmount(amount)}', style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 6),
        Text('${pct.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ]),
    );
  }

  Widget _buildTrendTab() {
    if (_monthlyTrends.isEmpty) return _empty();
    final spotsInc = <FlSpot>[], spotsExp = <FlSpot>[];
    final labels = <int, String>{};
    for (int i = 0; i < _monthlyTrends.length; i++) {
      final t = _monthlyTrends[i];
      spotsInc.add(FlSpot(i.toDouble(), (t['income'] as num).toDouble()));
      spotsExp.add(FlSpot(i.toDouble(), (t['expense'] as num).toDouble()));
      final p = (t['month'] as String).split('-');
      if (p.length == 2) labels[i] = '${int.parse(p[1])}月';
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('月度收支趋势', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SizedBox(height: 260, child: LineChart(LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44, getTitlesWidget: (v, _) => Text(Formatters.formatAmountCompact(v), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)))),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
              final idx = v.toInt();
              return labels.containsKey(idx) ? Padding(padding: const EdgeInsets.only(top: 4), child: Text(labels[idx]!, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary))) : const SizedBox.shrink();
            })),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(spots: spotsInc, isCurved: true, color: AppColors.income, barWidth: 2, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true, color: AppColors.income.withValues(alpha: 0.08))),
            LineChartBarData(spots: spotsExp, isCurved: true, color: AppColors.expense, barWidth: 2, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true, color: AppColors.expense.withValues(alpha: 0.08))),
          ],
        ))),
      ]),
    );
  }

  Widget _buildMonthlyReportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF5856D6)]), borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            const Text('月度报告', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 4),
            Text(app_date.DateUtils.formatMonthDisplay(_selectedYearMonth), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(children: [
              _rptItem('收入', _totalIncome, Colors.white),
              _rptItem('支出', _totalExpense, Colors.white),
              _rptItem('结余', _totalIncome - _totalExpense, (_totalIncome - _totalExpense) >= 0 ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        const Text('支出明细', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ..._expenseSummary.map((e) => _rptRow(e)),
        const SizedBox(height: 16),
        const Text('收入明细', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ..._incomeSummary.map((e) => _rptRow(e)),
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _rptItem(String l, double a, Color c) => Expanded(child: Column(children: [
    Text(l, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    const SizedBox(height: 2),
    Text(Formatters.formatAmountCompact(a), style: TextStyle(color: c, fontSize: 16, fontWeight: FontWeight.bold)),
  ]));

  Widget _rptRow(Map<String, dynamic> d) {
    final amount = (d['total'] as num).toDouble();
    final color = _getColor(0, d['color'] as String?);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), alignment: Alignment.center, child: Icon(CupertinoIcons.circle_fill, color: color, size: 12)),
        const SizedBox(width: 10),
        Expanded(child: Text(d['name'] as String? ?? '', style: const TextStyle(fontSize: 14))),
        Text('¥${Formatters.formatAmount(amount)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
