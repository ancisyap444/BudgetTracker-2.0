// lib/presentation/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../blocs/home/home_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../transactions/add_transaction_screen.dart';
import '../activity/activity_screen.dart';
import '../stats/stats_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    // Fire the initial load. All subsequent reloads are handled
    // automatically by HomeBloc subscribing to repository.dataUpdates.
    context.read<HomeBloc>().add(HomeLoad(month: n.month, year: n.year));
  }

  Future<void> _openAdd() async {
    // No need to await a bool result — the repository will call
    // notifyDataChanged() after createTransaction(), which triggers
    // HomeBloc to reload automatically via the dataUpdates stream.
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
  }

  void _switchTab(int index) => setState(() => _tab = index);

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _DashTab(),
      const StatsScreen(),
      const SizedBox.shrink(), // placeholder — intercepted by bottom nav
      const ActivityScreen(),
      ProfileScreen(
        onReload: () {
          final now = DateTime.now();
          context
              .read<HomeBloc>()
              .add(HomeLoad(month: now.month, year: now.year));
        },
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _tab == 2 ? 0 : _tab,
        children: pages,
      ),
      bottomNavigationBar: _BottomBar(
        current: _tab,
        onTap: (i) {
          if (i == 2) {
            _openAdd();
            return;
          }
          setState(() => _tab = i);
          if (i == 0) {
            final now = DateTime.now();
            context
                .read<HomeBloc>()
                .add(HomeLoad(month: now.month, year: now.year));
          }
        },
      ),
    );
  }
}

// ─── Dashboard tab ────────────────────────────────────────────
// Now a const-constructible StatelessWidget — no callbacks required.
class _DashTab extends StatelessWidget {
  const _DashTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (ctx, st) {
        if (st is HomeLoading || st is HomeInitial) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (st is HomeError) {
          return Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: ctx.txtMuted),
              const SizedBox(height: 12),
              Text(st.msg, style: Theme.of(ctx).textTheme.bodyMedium),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: () => ctx.read<HomeBloc>().add(HomeLoad(
                      month: DateTime.now().month, year: DateTime.now().year)),
                  child: const Text('Retry')),
            ],
          ));
        }
        if (st is HomeLoaded) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ctx
                .read<HomeBloc>()
                .add(HomeLoad(month: st.month, year: st.year)),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _Greeting(st: st)),
                SliverToBoxAdapter(child: _BudgetCard(st: st)),
                SliverToBoxAdapter(child: _OverviewGrid(st: st)),
                SliverToBoxAdapter(child: _WeeklyChart(st: st)),
                SliverToBoxAdapter(child: _DonutSection(st: st)),
                SliverToBoxAdapter(child: _CategoryRows(st: st)),
                SliverToBoxAdapter(child: _RecentTransactions(st: st)),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ── Greeting ──────────────────────────────────────────────────
class _Greeting extends StatelessWidget {
  final HomeLoaded st;
  const _Greeting({required this.st});

  String _greet() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    final name = st.profile.fullName;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 14),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_greet(), style: Theme.of(context).textTheme.bodyMedium),
          Text(name, style: Theme.of(context).textTheme.headlineMedium),
        ])),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle),
          child: Center(
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16))),
        ),
      ]),
    );
  }
}

// ── Budget card ───────────────────────────────────────────────
class _BudgetCard extends StatefulWidget {
  final HomeLoaded st;
  const _BudgetCard({required this.st});
  @override
  State<_BudgetCard> createState() => _BudgetCardState();
}

class _BudgetCardState extends State<_BudgetCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budget = widget.st.profile.monthlyBudget;
    final exp = widget.st.summary['expense'] ?? 0;
    final inc = widget.st.summary['income'] ?? 0;
    final effectiveBase = budget > 0 ? budget + inc : inc;
    final remain = effectiveBase - exp;
    final progress =
        effectiveBase > 0 ? (exp / effectiveBase).clamp(0.0, 1.0) : 0.0;
    final now = DateTime.now();
    final totalDays = DateTime(widget.st.year, widget.st.month + 1, 0).day;
    final isCurrentMonth =
        widget.st.year == now.year && widget.st.month == now.month;
    final isPastMonth = widget.st.year < now.year ||
        (widget.st.year == now.year && widget.st.month < now.month);
    final daysLeftText = isPastMonth
        ? 'Month ended'
        : isCurrentMonth
            ? '${(totalDays - now.day).clamp(0, totalDays)} days left'
            : '$totalDays days left';
    final fmt = NumberFormat('#,##0.00');

    final status = progress < 0.7
        ? _BudgetStatus.safe
        : progress < 0.9
            ? _BudgetStatus.warning
            : _BudgetStatus.danger;

    final Color statusColor = switch (status) {
      _BudgetStatus.safe => Colors.white,
      _BudgetStatus.warning => Colors.orangeAccent,
      _BudgetStatus.danger => Colors.redAccent,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(colors: [
            AppColors.primary.withValues(alpha: 0.95),
            AppColors.primaryDark
          ], begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.30),
                blurRadius: 30,
                offset: const Offset(0, 14))
          ],
        ),
        child: Stack(children: [
          Positioned(
              top: -60,
              right: -60,
              child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06)))),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Monthly Budget',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              Icon(Icons.tune_rounded,
                  color: Colors.white.withValues(alpha: 0.8), size: 20),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                        budget > 0 ? '₱${fmt.format(budget)}' : 'No budget set',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    if (inc > 0)
                      Text('+₱${fmt.format(inc)} income added',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 11))
                    else
                      Text(
                          budget > 0
                              ? 'Set in profile'
                              : 'Tap profile to set budget',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12)),
                  ])),
              SizedBox(
                  width: 70,
                  height: 70,
                  child: AnimatedBuilder(
                      animation: _animation,
                      builder: (_, __) => CustomPaint(
                          painter: _RingPainter(
                              progress: progress * _animation.value,
                              color: statusColor),
                          child: Center(
                              child: Text('${(progress * 100).toInt()}%',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)))))),
            ]),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                  child:
                      _CardStat(label: 'Spent', value: '₱${fmt.format(exp)}')),
              const SizedBox(width: 12),
              Expanded(
                  child: _CardStat(
                      label: 'Remaining',
                      value:
                          '${remain < 0 ? '-' : ''}₱${fmt.format(remain.abs())}',
                      valueColor:
                          remain < 0 ? Colors.redAccent : Colors.white)),
            ]),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(daysLeftText,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12)),
              Text(status.name.toUpperCase(),
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1)),
            ]),
          ]),
        ]),
      ),
    );
  }
}

enum _BudgetStatus { safe, warning, danger }

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - stroke;
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke);
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -1.57,
        2 * 3.1416 * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}

class _CardStat extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _CardStat({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 12)),
        Text(value,
            style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
      ]);
}

// ── Overview grid ─────────────────────────────────────────────
class _OverviewGrid extends StatelessWidget {
  final HomeLoaded st;
  const _OverviewGrid({required this.st});

  @override
  Widget build(BuildContext context) {
    final exp = st.summary['expense'] ?? 0;
    final tx = (st.summary['tx_count'] ?? 0).toInt();
    final day = DateTime.now().day.clamp(1, 31);
    final daily = exp / day;

    final expTxs = st.recent.where((t) => t.isExpense).toList();
    final largest = expTxs.isEmpty
        ? null
        : expTxs.reduce((a, b) => a.amount > b.amount ? a : b);

    final spentCats = st.categories.where((c) => c.spent > 0).toList();
    final topCat = spentCats.isEmpty ? null : spentCats.first;
    final totalExp = spentCats.fold(0.0, (s, c) => s + c.spent);
    final topPct = (topCat != null && totalExp > 0)
        ? (topCat.spent / totalExp * 100).round()
        : 0;

    final fmt = NumberFormat('#,##0');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Overview', style: Theme.of(context).textTheme.headlineMedium),
          OutlinedButton.icon(
            // Navigate to Profile tab via the nearest HomeScreen ancestor.
            // Using context.findAncestorStateOfType avoids passing callbacks.
            onPressed: () => context
                .findAncestorStateOfType<_HomeScreenState>()
                ?._switchTab(4),
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Set budget', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                minimumSize: Size.zero,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20))),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: _OvCard(
                  label: 'Daily average',
                  value: '₱${fmt.format(daily)}',
                  sub: 'This month',
                  subColor: context.txtMuted)),
          const SizedBox(width: 10),
          Expanded(
              child: _OvCard(
                  label: 'Largest expense',
                  value: '₱${fmt.format(largest?.amount ?? 0)}',
                  sub: largest?.categoryName ?? 'None')),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _OvCard(
                  label: 'Transactions',
                  value: '$tx',
                  sub: 'This month',
                  subColor: context.txtMuted)),
          const SizedBox(width: 10),
          Expanded(
              child: GestureDetector(
            onTap: () => context
                .findAncestorStateOfType<_HomeScreenState>()
                ?._switchTab(3),
            child: _OvCard(
                label: 'Top category',
                value: topCat?.name ?? 'None',
                sub:
                    topCat != null ? '$topPct% of spending' : 'No expenses yet',
                subColor: topCat != null ? topCat.color : context.txtMuted),
          )),
        ]),
      ]),
    );
  }
}

class _OvCard extends StatelessWidget {
  final String label, value, sub;
  final Color? subColor;
  const _OvCard({
    required this.label,
    required this.value,
    required this.sub,
    this.subColor,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: context.surfColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.divColor)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(fontSize: 22)),
          const SizedBox(height: 3),
          Text(sub,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: subColor ?? context.txtMuted)),
        ]),
      );
}

// ── Weekly chart ──────────────────────────────────────────────
class _WeeklyChart extends StatelessWidget {
  final HomeLoaded st;
  const _WeeklyChart({required this.st});

  @override
  Widget build(BuildContext context) {
    final data = st.weekly;
    final isDark = context.isDark;
    final maxVal = data.isEmpty
        ? 1.0
        : data
            .map((e) => e['amount'] as double)
            .reduce((a, b) => a > b ? a : b);
    final maxY = maxVal > 0 ? maxVal * 1.3 : 1.0;
    final fmt = NumberFormat('#,##0');
    final barInactive =
        isDark ? const Color(0xFF2D3A6B) : const Color(0xFFD0D9FF);

    String yLabel(double v) {
      if (v == 0) return '₱0';
      if (v >= 1000) return '₱${(v / 1000).toStringAsFixed(0)}k';
      return '₱${v.toStringAsFixed(0)}';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: context.surfColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.divColor)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Weekly spending',
                style: Theme.of(context).textTheme.titleLarge),
            Text(DateFormat('MMMM').format(DateTime(st.year, st.month)),
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 20),
          SizedBox(
            height: 170,
            child: BarChart(BarChartData(
              maxY: maxY,
              gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: context.divColor, strokeWidth: 1)),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  interval: maxY / 4,
                  getTitlesWidget: (v, _) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(yLabel(v),
                          style: TextStyle(
                              color: context.txtMuted, fontSize: 10))),
                )),
                bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (v, _) {
                    final idx = v.toInt();
                    final title = (idx >= 0 && idx < 4)
                        ? ['W1', 'W2', 'W3', 'W4'][idx]
                        : '';
                    return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(title,
                            style: TextStyle(
                                color: context.txtMuted, fontSize: 12)));
                  },
                )),
              ),
              barGroups: List.generate(data.length, (i) {
                final amt = data[i]['amount'] as double;
                return BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                      toY: amt,
                      width: 30,
                      borderRadius: BorderRadius.circular(6),
                      color: amt == maxVal && maxVal > 0
                          ? AppColors.primary
                          : barInactive),
                ]);
              }),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => context.isDark
                      ? AppColors.darkSurfaceAlt
                      : AppColors.textPrimary,
                  getTooltipItem: (g, _, rod, __) => BarTooltipItem(
                      '₱${fmt.format(rod.toY)}',
                      const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ),
              ),
            )),
          ),
        ]),
      ),
    );
  }
}

// ── Donut chart ───────────────────────────────────────────────
class _DonutSection extends StatefulWidget {
  final HomeLoaded st;
  const _DonutSection({required this.st});
  @override
  State<_DonutSection> createState() => _DonutSectionState();
}

class _DonutSectionState extends State<_DonutSection> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final cats = widget.st.categories.where((c) => c.spent > 0).toList();
    final total = cats.fold(0.0, (s, c) => s + c.spent);
    const colors = AppColors.chart;
    if (cats.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: context.surfColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.divColor)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionHeader(
            title: 'Spending by category',
            action: 'View all',
            onAction: () => context
                .findAncestorStateOfType<_HomeScreenState>()
                ?._switchTab(3),
          ),
          const SizedBox(height: 20),
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            SizedBox(
                width: 150,
                height: 150,
                child: PieChart(PieChartData(
                    pieTouchData: PieTouchData(
                        touchCallback: (_, res) => setState(() => _touched =
                            res?.touchedSection?.touchedSectionIndex ?? -1)),
                    sections: List.generate(cats.length, (i) {
                      final touched = i == _touched;
                      final pct = total > 0 ? cats[i].spent / total * 100 : 0;
                      return PieChartSectionData(
                          value: cats[i].spent,
                          color: colors[i % colors.length],
                          radius: touched ? 56 : 46,
                          title: touched ? '${pct.toStringAsFixed(0)}%' : '',
                          titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white));
                    }),
                    centerSpaceRadius: 36,
                    sectionsSpace: 2))),
            const SizedBox(width: 16),
            Expanded(
              child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: List.generate(
                      cats.take(6).length,
                      (i) => Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                    color: colors[i % colors.length],
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 5),
                            Text(
                                '${cats[i].name} ${total > 0 ? (cats[i].spent / total * 100).toStringAsFixed(0) : 0}%',
                                style: TextStyle(
                                    fontSize: 11, color: context.txtSecondary)),
                          ]))),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ── Category rows ─────────────────────────────────────────────
class _CategoryRows extends StatelessWidget {
  final HomeLoaded st;
  const _CategoryRows({required this.st});

  @override
  Widget build(BuildContext context) {
    final cats = st.categories.where((c) => c.spent > 0).take(6).toList();
    final total = cats.fold(0.0, (s, c) => s + c.spent);
    final fmt = NumberFormat('#,##0');
    if (cats.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Categories', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        ...cats.map((cat) {
          final pct = total > 0 ? cat.spent / total : 0.0;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: context.surfColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.divColor)),
            child: Row(children: [
              CatCircle(icon: cat.icon, size: 44),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(cat.name,
                              style: Theme.of(context).textTheme.titleMedium),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('₱${fmt.format(cat.spent)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                                Text('${(pct * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                        color: context.txtMuted, fontSize: 11)),
                              ]),
                        ]),
                    const SizedBox(height: 8),
                    ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                            value: pct.clamp(0.0, 1.0),
                            backgroundColor: context.divColor,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(cat.color),
                            minHeight: 5)),
                  ])),
            ]),
          );
        }),
      ]),
    );
  }
}

// ── Recent transactions ───────────────────────────────────────
class _RecentTransactions extends StatelessWidget {
  final HomeLoaded st;
  const _RecentTransactions({required this.st});

  @override
  Widget build(BuildContext context) {
    final txs = st.recent.take(5).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(
          title: 'Recent transactions',
          action: 'See all',
          onAction: () => context
              .findAncestorStateOfType<_HomeScreenState>()
              ?._switchTab(3),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
              color: context.surfColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.divColor)),
          child: txs.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No transactions',
                      subtitle: 'Tap + to add your first'))
              : Column(
                  children: List.generate(
                      txs.length,
                      (i) =>
                          TxTile(tx: txs[i], showDivider: i < txs.length - 1))),
        ),
      ]),
    );
  }
}

// ─── Bottom navigation ────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _BottomBar({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfColor,
        border: Border(top: BorderSide(color: context.divColor)),
        boxShadow: [
          BoxShadow(
              color:
                  Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, -3))
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NBt(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  i: 0,
                  cur: current,
                  onTap: onTap),
              _NBt(
                  icon: Icons.bar_chart_rounded,
                  label: 'Stats',
                  i: 1,
                  cur: current,
                  onTap: onTap),
              _NBt(
                  icon: Icons.add_circle_rounded,
                  label: 'Add',
                  i: 2,
                  cur: current,
                  onTap: onTap,
                  isAdd: true),
              _NBt(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Activity',
                  i: 3,
                  cur: current,
                  onTap: onTap),
              _NBt(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  i: 4,
                  cur: current,
                  onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NBt extends StatelessWidget {
  final IconData icon;
  final String label;
  final int i, cur;
  final ValueChanged<int> onTap;
  final bool isAdd;
  const _NBt({
    required this.icon,
    required this.label,
    required this.i,
    required this.cur,
    required this.onTap,
    this.isAdd = false,
  });

  @override
  Widget build(BuildContext context) {
    final sel = cur == i;
    final color = (sel || isAdd) ? AppColors.primary : context.txtMuted;
    return GestureDetector(
      onTap: () => onTap(i),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: isAdd ? 28 : 24, color: color),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w500, color: color)),
        ]),
      ),
    );
  }
}
