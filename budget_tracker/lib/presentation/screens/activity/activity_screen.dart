// lib/presentation/screens/activity/activity_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../data/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../transactions/add_transaction_screen.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});
  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Activity'),
        actions: [
          // Add button only visible on the Transactions tab.
          ListenableBuilder(
            listenable: _tab,
            builder: (_, __) => _tab.index == 0
                ? IconButton(
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () async {
                      // Push and wait for pop. The repository's
                      // notifyDataChanged() fires inside createTransaction()
                      // which automatically triggers HomeBloc to reload.
                      // We only need to refresh the local transaction list here.
                      final ok = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddTransactionScreen()),
                      );
                      if (ok == true && mounted) {
                        _txTabKey.currentState?._load();
                      }
                    })
                : const SizedBox.shrink(),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: context.txtMuted,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: const [
            Tab(text: 'Transactions'),
            Tab(text: 'Categories'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _TransactionsTab(key: _txTabKey),
          const _CategoriesTab(),
        ],
      ),
    );
  }

  // Key scoped to this State so the add button can call _load() on the
  // transactions tab after a successful add without any callback chain.
  final _txTabKey = GlobalKey<_TransactionsTabState>();
}

// ─── Transactions tab ─────────────────────────────────────────
class _TransactionsTab extends StatefulWidget {
  const _TransactionsTab({super.key});
  @override
  State<_TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<_TransactionsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _repo = BudgetRepository();
  List<TransactionModel> _all = [];
  List<TransactionModel> _filtered = [];
  bool _loading = true;
  String _filter = 'all';
  String _q = '';
  StreamSubscription<void>? _updatesSub;

  @override
  void initState() {
    super.initState();
    _load();
    _updatesSub = _repo.dataUpdates.listen((_) => _load());
  }

  @override
  void dispose() {
    _updatesSub?.cancel();
    super.dispose();
  }

  // Called after add, edit, delete — refreshes only the local list.
  // The dashboard refresh is handled by HomeBloc via dataUpdates stream.
  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final d = await _repo.getTransactions(limit: 200);
    if (!mounted) return;
    setState(() {
      _all = d;
      _loading = false;
      _applyFilter();
    });
  }

  void _applyFilter() {
    _filtered = _all.where((tx) {
      final matchType = _filter == 'all' || tx.type == _filter;
      final matchSearch = _q.isEmpty ||
          tx.title.toLowerCase().contains(_q.toLowerCase()) ||
          (tx.categoryName ?? '').toLowerCase().contains(_q.toLowerCase());
      return matchType && matchSearch;
    }).toList();
  }

  String _dateKey(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDay = DateTime(d.year, d.month, d.day);
    if (txDay == today) return 'Today';
    if (txDay == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('MMMM d, yyyy').format(d);
  }

  Map<String, List<TransactionModel>> _grouped() {
    final Map<String, List<TransactionModel>> m = {};
    for (final tx in _filtered) {
      m.putIfAbsent(_dateKey(tx.date), () => []).add(tx);
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final grouped = _grouped();
    final keys = grouped.keys.toList();
    final fmt = NumberFormat('#,##0.00');

    return Column(children: [
      // Search bar
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: TextField(
          decoration: InputDecoration(
              hintText: 'Search transactions…',
              prefixIcon:
                  Icon(Icons.search_rounded, color: context.txtMuted, size: 20),
              suffixIcon: _q.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded,
                          color: context.txtMuted, size: 20),
                      onPressed: () {
                        setState(() => _q = '');
                        _applyFilter();
                      })
                  : null),
          onChanged: (v) {
            setState(() => _q = v);
            _applyFilter();
          },
        ),
      ),

      // Filter chips
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          ...['all', 'expense', 'income'].map((f) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() => _filter = f);
                  _applyFilter();
                },
                child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                        color: _filter == f
                            ? (f == 'expense'
                                ? AppColors.expense
                                : f == 'income'
                                    ? AppColors.income
                                    : AppColors.primary)
                            : context.surfColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.divColor)),
                    child: Text(
                        f == 'all'
                            ? 'All'
                            : f == 'expense'
                                ? 'Expenses'
                                : 'Income',
                        style: TextStyle(
                            color: _filter == f
                                ? Colors.white
                                : context.txtSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500))),
              ))),
          const Spacer(),
          Text('${_filtered.length} items',
              style: Theme.of(context).textTheme.labelSmall),
        ]),
      ),

      // List
      Expanded(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : _filtered.isEmpty
                ? const EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'No transactions',
                    subtitle: 'Tap + in the top right to add one')
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: keys.length,
                      itemBuilder: (ctx, di) {
                        final txs = grouped[keys[di]]!;
                        final dayTotal = txs.fold(0.0,
                            (s, t) => s + (t.isExpense ? -t.amount : t.amount));

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(keys[di],
                                          style: Theme.of(ctx)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                  color: ctx.txtSecondary)),
                                      Text(
                                          '${dayTotal >= 0 ? '+' : ''}₱${fmt.format(dayTotal)}',
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: dayTotal >= 0
                                                  ? AppColors.income
                                                  : AppColors.expense)),
                                    ])),
                            Container(
                              decoration: BoxDecoration(
                                  color: ctx.surfColor,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: ctx.divColor)),
                              child: Column(
                                children: List.generate(
                                    txs.length,
                                    (ti) => Dismissible(
                                          key: Key(txs[ti].id),
                                          direction:
                                              DismissDirection.endToStart,
                                          background: Container(
                                              alignment: Alignment.centerRight,
                                              padding: const EdgeInsets.only(
                                                  right: 20),
                                              decoration: BoxDecoration(
                                                  color: AppColors.expense
                                                      .withValues(alpha: 0.10),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          14)),
                                              child: const Icon(
                                                  Icons.delete_outline_rounded,
                                                  color: AppColors.expense)),
                                          confirmDismiss: (_) async => await showDialog<
                                                  bool>(
                                              context: ctx,
                                              builder: (_) => AlertDialog(
                                                      title: const Text(
                                                          'Delete transaction?'),
                                                      content: Text(
                                                          'Delete "${txs[ti].title}"?'),
                                                      actions: [
                                                        TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    ctx, false),
                                                            child: const Text(
                                                                'Cancel')),
                                                        TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    ctx, true),
                                                            child: const Text(
                                                                'Delete',
                                                                style: TextStyle(
                                                                    color: AppColors
                                                                        .expense))),
                                                      ])),
                                          onDismissed: (_) async {
                                            // deleteTransaction calls notifyDataChanged()
                                            // internally — HomeBloc reloads automatically.
                                            await _repo
                                                .deleteTransaction(txs[ti].id);
                                            _load(); // refresh local list only
                                          },
                                          child: TxTile(
                                              tx: txs[ti],
                                              showDivider: ti < txs.length - 1,
                                              onTap: () async {
                                                final ok =
                                                    await Navigator.push<bool>(
                                                  ctx,
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          AddTransactionScreen(
                                                              existing:
                                                                  txs[ti])),
                                                );
                                                // updateTransaction calls notifyDataChanged()
                                                // internally — HomeBloc reloads automatically.
                                                if (ok == true) _load();
                                              }),
                                        )),
                              ),
                            ),
                          ],
                        );
                      },
                    )),
      ),
    ]);
  }
}

// ─── Categories tab ───────────────────────────────────────────
class _CategoriesTab extends StatefulWidget {
  const _CategoriesTab();
  @override
  State<_CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<_CategoriesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _repo = BudgetRepository();
  List<CategoryModel> _cats = [];
  bool _loading = true;
  late DateTime _sel;
  StreamSubscription<void>? _updatesSub;

  @override
  void initState() {
    super.initState();
    _sel = DateTime.now();
    _load();
    _updatesSub = _repo.dataUpdates.listen((_) => _load());
  }

  @override
  void dispose() {
    _updatesSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final c = await _repo.getCategoriesWithSpending(
        month: _sel.month, year: _sel.year);
    if (!mounted) return;
    setState(() {
      _cats = c;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final with_ = _cats.where((c) => c.spent > 0).toList();
    final none_ = _cats.where((c) => c.spent == 0).toList();
    final total = with_.fold(0.0, (s, c) => s + c.spent);
    final fmt = NumberFormat('#,##0');
    final now = DateTime.now();
    final isCur = _sel.year == now.year && _sel.month == now.month;

    return _loading
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
                            onPressed: () {
                              setState(() =>
                                  _sel = DateTime(_sel.year, _sel.month - 1));
                              _load();
                            }),
                        Text(DateFormat('MMMM yyyy').format(_sel),
                            style: Theme.of(context).textTheme.titleLarge),
                        IconButton(
                            icon: Icon(Icons.chevron_right_rounded,
                                color: isCur
                                    ? context.txtMuted
                                    : context.txtPrimary),
                            onPressed: isCur
                                ? null
                                : () {
                                    setState(() => _sel =
                                        DateTime(_sel.year, _sel.month + 1));
                                    _load();
                                  }),
                      ])),
              const SizedBox(height: 16),

              // Total banner
              if (total > 0)
                Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      const Icon(Icons.pie_chart_rounded,
                          color: Colors.white70, size: 26),
                      const SizedBox(width: 14),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Spent This Month',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            Text('₱${fmt.format(total)}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800)),
                          ]),
                      const Spacer(),
                      Text('${with_.length} categories',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 12)),
                    ])),

              // Active categories
              if (with_.isNotEmpty) ...[
                ...with_.map((cat) {
                  final pct = total > 0 ? cat.spent / total : 0.0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: context.surfColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.divColor)),
                    child: Row(children: [
                      CatCircle(icon: cat.icon, size: 46),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(cat.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text('₱${fmt.format(cat.spent)}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14)),
                                        Text(
                                            '${(pct * 100).toStringAsFixed(0)}%',
                                            style: TextStyle(
                                                color: context.txtMuted,
                                                fontSize: 11)),
                                      ]),
                                ]),
                            const SizedBox(height: 8),
                            ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                    value: pct.clamp(0.0, 1.0),
                                    backgroundColor: context.divColor,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        cat.color),
                                    minHeight: 5)),
                          ])),
                    ]),
                  );
                }),
                const SizedBox(height: 8),
              ],

              // Unused categories
              if (none_.isNotEmpty) ...[
                Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('No Activity',
                        style: Theme.of(context).textTheme.labelSmall)),
                Container(
                  decoration: BoxDecoration(
                      color: context.surfColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.divColor)),
                  child: Column(
                      children: List.generate(
                          none_.length,
                          (i) => Column(children: [
                                ListTile(
                                    leading: CatCircle(
                                        icon: none_[i].icon, size: 40),
                                    title: Text(none_[i].name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium),
                                    subtitle: Text('No spending this month',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: context.txtMuted)),
                                    trailing: Text('₱0',
                                        style: TextStyle(
                                            color: context.txtMuted,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600))),
                                if (i < none_.length - 1)
                                  Divider(
                                      height: 1,
                                      indent: 68,
                                      color: context.divColor),
                              ]))),
                ),
              ],

              if (_cats.isEmpty)
                const EmptyState(
                    icon: Icons.category_rounded,
                    title: 'No categories',
                    subtitle:
                        'Categories are created automatically on sign-up'),
              const SizedBox(height: 100),
            ]));
  }
}
