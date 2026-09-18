// lib/presentation/screens/stats/stats_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsState();
}

class _StatsState extends State<StatsScreen> {
  final _repo = BudgetRepository();
  StreamSubscription<void>? _updatesSub;
  Map<String, double> _spending = {}, _summary = {};
  List<Map<String, dynamic>> _weekly = [];
  bool _loading = true;
  late DateTime _sel;
  int _touched = -1;

  @override
  void initState() {
    super.initState();
    _sel = DateTime.now();
    _load();
    _updatesSub = _repo.dataUpdates.listen((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _updatesSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final r = await Future.wait([
      _repo.getCategorySpending(month: _sel.month, year: _sel.year),
      _repo.getMonthlySummary(month: _sel.month, year: _sel.year),
      _repo.getWeeklySpending(month: _sel.month, year: _sel.year),
    ]);
    if (!mounted) return;
    setState(() {
      _spending = r[0] as Map<String, double>;
      _summary = r[1] as Map<String, double>;
      _weekly = r[2] as List<Map<String, dynamic>>;
      _loading = false;
    });
  }

  void _prev() {
    setState(() => _sel = DateTime(_sel.year, _sel.month - 1));
    _load();
  }

  void _next() {
    final n = DateTime.now();
    if (_sel.year == n.year && _sel.month == n.month) return;
    setState(() => _sel = DateTime(_sel.year, _sel.month + 1));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCur = _sel.year == now.year && _sel.month == now.month;
    final fmt = NumberFormat('#,##0.00');
    final entries = _spending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold(0.0, (s, e) => s + e.value);
    const colors = AppColors.chart;
    final maxW = _weekly.isEmpty
        ? 1.0
        : _weekly
            .map((e) => e['amount'] as double)
            .reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(
          title: const Text('Statistics'), automaticallyImplyLeading: false),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                // Month nav
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                        color: context.surfColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.divColor)),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                              icon: const Icon(Icons.chevron_left_rounded),
                              onPressed: _prev),
                          Text(DateFormat('MMMM yyyy').format(_sel),
                              style: Theme.of(context).textTheme.titleLarge),
                          IconButton(
                              icon: Icon(Icons.chevron_right_rounded,
                                  color: isCur
                                      ? context.txtMuted
                                      : context.txtPrimary),
                              onPressed: isCur ? null : _next),
                        ])),
                const SizedBox(height: 16),

                // Summary cards
                Row(children: [
                  Expanded(
                      child: _SCard(
                          label: 'Income',
                          value: '₱${fmt.format(_summary['income'] ?? 0)}',
                          icon: Icons.trending_up_rounded,
                          color: AppColors.income)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _SCard(
                          label: 'Expense',
                          value: '₱${fmt.format(_summary['expense'] ?? 0)}',
                          icon: Icons.trending_down_rounded,
                          color: AppColors.expense)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                      child: _SCard(
                          label: 'Balance',
                          value:
                              '${(_summary['balance'] ?? 0) >= 0 ? '+' : '-'}₱${fmt.format((_summary['balance'] ?? 0).abs())}',
                          icon: Icons.account_balance_rounded,
                          color: (_summary['balance'] ?? 0) >= 0
                              ? AppColors.income
                              : AppColors.expense)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _SCard(
                          label: 'Savings Rate',
                          value:
                              '${(_summary['savings_rate'] ?? 0).toStringAsFixed(1)}%',
                          icon: Icons.savings_rounded,
                          color: AppColors.primary)),
                ]),
                const SizedBox(height: 20),

                // Weekly bar chart
                Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: context.surfColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.divColor)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Weekly Expenses',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 20),
                          SizedBox(
                              height: 150,
                              child: BarChart(BarChartData(
                                maxY: maxW > 0 ? maxW * 1.3 : 100,
                                gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    getDrawingHorizontalLine: (_) => FlLine(
                                        color: context.divColor,
                                        strokeWidth: 1)),
                                borderData: FlBorderData(show: false),
                                titlesData: FlTitlesData(
                                    leftTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 24,
                                            getTitlesWidget: (v, _) {
                                              final idx = v.toInt();
                                              final label =
                                                  (idx >= 0 && idx < 4)
                                                      ? [
                                                          'W1',
                                                          'W2',
                                                          'W3',
                                                          'W4'
                                                        ][idx]
                                                      : '';
                                              return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 8),
                                                  child: Text(label,
                                                      style: TextStyle(
                                                          color:
                                                              context.txtMuted,
                                                          fontSize: 12)));
                                            }))),
                                barGroups: List.generate(
                                    _weekly.length,
                                    (i) => BarChartGroupData(x: i, barRods: [
                                          BarChartRodData(
                                              toY: _weekly[i]['amount']
                                                  as double,
                                              width: 32,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              color: AppColors.primary),
                                        ])),
                                barTouchData: BarTouchData(
                                    touchTooltipData: BarTouchTooltipData(
                                        getTooltipColor: (_) => context.isDark
                                            ? AppColors.darkSurfaceAlt
                                            : AppColors.textPrimary,
                                        getTooltipItem: (g, _, rod, __) =>
                                            BarTooltipItem(
                                                '₱${NumberFormat('#,##0').format(rod.toY)}',
                                                const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 12)))),
                              ))),
                        ])),
                const SizedBox(height: 20),

                // Pie chart
                if (entries.isNotEmpty)
                  Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: context.surfColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.divColor)),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Expense Breakdown',
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 20),
                            SizedBox(
                                height: 200,
                                child: PieChart(PieChartData(
                                    pieTouchData: PieTouchData(
                                        touchCallback: (_, res) => setState(
                                            () => _touched = res?.touchedSection
                                                    ?.touchedSectionIndex ??
                                                -1)),
                                    sections:
                                        List.generate(entries.length, (i) {
                                      final t = i == _touched;
                                      final pct = total > 0
                                          ? entries[i].value / total * 100
                                          : 0;
                                      return PieChartSectionData(
                                          value: entries[i].value,
                                          color: colors[i % colors.length],
                                          radius: t ? 88 : 72,
                                          title: '${pct.toStringAsFixed(0)}%',
                                          titleStyle: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white));
                                    }),
                                    centerSpaceRadius: 44,
                                    sectionsSpace: 2))),
                            const SizedBox(height: 14),
                            ...List.generate(
                                entries.length,
                                (i) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(children: [
                                      Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                              color: colors[i % colors.length],
                                              borderRadius:
                                                  BorderRadius.circular(3))),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: Text(entries[i].key,
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color: context.txtPrimary))),
                                      Text(
                                          '₱${NumberFormat('#,##0').format(entries[i].value)}',
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: context.txtPrimary)),
                                    ]))),
                          ]))
                else
                  Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                          color: context.surfColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.divColor)),
                      child: const EmptyState(
                          icon: Icons.pie_chart_outline_rounded,
                          title: 'No data yet',
                          subtitle:
                              'Add expense transactions to see breakdown')),
                const SizedBox(height: 100),
              ])),
    );
  }
}

class _SCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _SCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: context.surfColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.divColor)),
        child: Row(children: [
          Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: context.isDark ? 0.15 : 0.10),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 3),
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ])),
        ]),
      );
}
