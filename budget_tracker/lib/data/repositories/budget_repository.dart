// lib/data/repositories/budget_repository.dart
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../../core/constants/app_constants.dart';

class BudgetRepository {
  static final BudgetRepository _instance = BudgetRepository._internal();
  factory BudgetRepository() => _instance;
  BudgetRepository._internal();

  SupabaseClient get _db => Supabase.instance.client;
  User? get me => _isGuestMode ? _guestUser : _db.auth.currentUser;
  String? get _uid => _isGuestMode ? 'guest_user' : me?.id;

  // ── Guest / Offline Mode ─────────────────────────────────
  bool _isGuestMode = false;
  bool get isGuestMode => _isGuestMode;

  User? get _guestUser => User.fromJson({
        'id': 'guest_user',
        'app_metadata': <String, dynamic>{},
        'user_metadata': <String, dynamic>{'full_name': 'Francis Yap (Guest)'},
        'aud': 'authenticated',
        'created_at': DateTime.now().toIso8601String(),
      });

  ProfileModel? _guestProfile = ProfileModel(
    id: 'guest_user',
    fullName: 'Francis Yap (Guest)',
    monthlyBudget: 25000,
    createdAt: DateTime.now(),
  );

  final List<CategoryModel> _guestCategories = [];
  final List<TransactionModel> _guestTransactions = [];

  void enableGuestMode() {
    _isGuestMode = true;
    _initGuestData();
    notifyDataChanged();
  }

  void disableGuestMode() {
    _isGuestMode = false;
    notifyDataChanged();
  }

  void _initGuestData() {
    if (_guestCategories.isEmpty) {
      _guestCategories.addAll(
        AppConstants.defaultCategories.map((c) => CategoryModel(
              id: 'cat_${c['name']}',
              userId: 'guest_user',
              name: c['name'] ?? 'Category',
              icon: c['icon'] ?? 'more_horiz',
              colorHex: c['color'] ?? '#757575',
              budgetLimit: 5000,
              spent: 0,
              createdAt: DateTime.now(),
            )),
      );
    }
    if (_guestTransactions.isEmpty) {
      final now = DateTime.now();
      _guestTransactions.addAll([
        TransactionModel(
          id: 'tx_sample_1',
          userId: 'guest_user',
          title: 'Monthly Salary',
          type: 'income',
          amount: 35000,
          date: DateTime(now.year, now.month, 1),
          createdAt: DateTime.now(),
          categoryName: 'Income',
          categoryIcon: 'account_balance_wallet',
          categoryColor: '#4CAF50',
          note: 'Sample Income',
        ),
        TransactionModel(
          id: 'tx_sample_2',
          userId: 'guest_user',
          title: 'Groceries & Market',
          type: 'expense',
          amount: 3200,
          date: DateTime(now.year, now.month, now.day.clamp(1, 28)),
          createdAt: DateTime.now(),
          categoryName: 'Food & Dining',
          categoryIcon: 'restaurant',
          categoryColor: '#FF9800',
          note: 'Sample Expense',
        ),
      ]);
    }
  }

  // ── Change-notification stream ───────────────────────────
  // A broadcast StreamController so multiple listeners (e.g. HomeBloc)
  // can subscribe simultaneously without conflict.
  // Emits a void event every time any local data mutation completes,
  // letting subscribers react without polling or manual reload calls.
  final _dataUpdateController = StreamController<void>.broadcast();

  /// Public stream that any BLoC or widget can subscribe to in order to
  /// be notified whenever the repository mutates data in Supabase.
  Stream<void> get dataUpdates => _dataUpdateController.stream;

  /// Fires a void event on [dataUpdates]. Called at the end of every
  /// method that writes, updates, or deletes data in Supabase.
  void notifyDataChanged() => _dataUpdateController.add(null);

  /// Must be called when the repository is no longer needed to close
  /// the stream and release resources.
  void dispose() {
    // Shared singleton stream remains active for the app lifetime.
  }

  // ── Auth ────────────────────────────────────────────────
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) =>
      _db.auth.signUp(
          email: email, password: password, data: {'full_name': fullName});

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) =>
      _db.auth.signInWithPassword(email: email, password: password);

  Future<void> signOut() async {
    _isGuestMode = false;
    try {
      await _db.auth.signOut();
    } catch (_) {}
    notifyDataChanged();
  }

  Stream<AuthState> get authStream => _db.auth.onAuthStateChange;

  // ── Profile ─────────────────────────────────────────────
  Future<ProfileModel?> getProfile() async {
    if (_isGuestMode) return _guestProfile;
    if (_uid == null) return null;
    try {
      final d = await _db
          .from(AppConstants.profilesTable)
          .select()
          .eq('id', _uid!)
          .maybeSingle();
      if (d != null) {
        return ProfileModel.fromJson(d);
      }
      // Defensive profile creation if no auth trigger was configured in Supabase
      final userName = (me?.userMetadata?['full_name'] as String?) ?? 'User';
      try {
        final inserted = await _db
            .from(AppConstants.profilesTable)
            .upsert({
              'id': _uid,
              'full_name': userName,
              'monthly_budget': 0,
            })
            .select()
            .single();
        return ProfileModel.fromJson(inserted);
      } catch (_) {
        return ProfileModel(
          id: _uid!,
          fullName: userName,
          monthlyBudget: 0,
          createdAt: DateTime.now(),
        );
      }
    } catch (_) {
      return null;
    }
  }

  Future<void> updateMonthlyBudget(double amount) async {
    if (_isGuestMode) {
      _guestProfile = _guestProfile?.copyWith(monthlyBudget: amount);
      notifyDataChanged();
      return;
    }
    if (_uid == null) return;
    try {
      final existing = await _db
          .from(AppConstants.profilesTable)
          .select('full_name')
          .eq('id', _uid!)
          .maybeSingle();

      final currentName = (existing?['full_name'] as String?) ??
          (me?.userMetadata?['full_name'] as String?) ??
          'User';

      await _db.from(AppConstants.profilesTable).upsert({
        'id': _uid!,
        'monthly_budget': amount,
        'full_name': currentName,
      });
    } catch (_) {
      try {
        await _db
            .from(AppConstants.profilesTable)
            .update({'monthly_budget': amount})
            .eq('id', _uid!);
      } catch (_) {}
    } finally {
      notifyDataChanged();
    }
  }

  Future<void> updateProfileName(String name) async {
    if (_isGuestMode) {
      _guestProfile = _guestProfile?.copyWith(fullName: name);
      notifyDataChanged();
      return;
    }
    if (_uid == null) return;
    try {
      final existing = await _db
          .from(AppConstants.profilesTable)
          .select('monthly_budget')
          .eq('id', _uid!)
          .maybeSingle();

      final currentBudget =
          (existing?['monthly_budget'] as num?)?.toDouble() ?? 0.0;

      await _db.from(AppConstants.profilesTable).upsert({
        'id': _uid!,
        'full_name': name,
        'monthly_budget': currentBudget,
      });
    } catch (_) {
      try {
        await _db
            .from(AppConstants.profilesTable)
            .update({'full_name': name})
            .eq('id', _uid!);
      } catch (_) {}
    } finally {
      notifyDataChanged();
    }
  }

  // ── Categories ──────────────────────────────────────────
  Future<List<CategoryModel>> getCategories() async {
    if (_isGuestMode) {
      if (_guestCategories.isEmpty) _initGuestData();
      return List.from(_guestCategories);
    }
    if (_uid == null) return [];
    final d = await _db
        .from(AppConstants.categoriesTable)
        .select()
        .eq('user_id', _uid!)
        .order('name');
    return (d as List).map((e) => CategoryModel.fromJson(e)).toList();
  }

  Future<void> seedDefaultCategories() async {
    if (_isGuestMode) return;
    if (_uid == null) return;
    final ex = await _db
        .from(AppConstants.categoriesTable)
        .select('id')
        .eq('user_id', _uid!);
    if ((ex as List).isNotEmpty) return;
    await _db.from(AppConstants.categoriesTable).insert(
          AppConstants.defaultCategories
              .map((c) => {
                    'user_id': _uid,
                    'name': c['name'],
                    'icon': c['icon'],
                    'color': c['color'],
                    'budget_limit': 0,
                  })
              .toList(),
        );
    // Seeding is also a write — notify so any subscriber can react
    // if they need to reflect the newly created categories.
    notifyDataChanged();
  }

  // ── Transactions ────────────────────────────────────────
  Future<List<TransactionModel>> getTransactions({
    int? month,
    int? year,
    int limit = 100,
  }) async {
    if (_isGuestMode) {
      var list = List<TransactionModel>.from(_guestTransactions);
      if (month != null && year != null) {
        list = list
            .where((t) => t.date.month == month && t.date.year == year)
            .toList();
      }
      list.sort((a, b) => b.date.compareTo(a.date));
      return list.take(limit).toList();
    }
    if (_uid == null) return [];
    var q = _db
        .from(AppConstants.transactionsTable)
        .select('*, categories(name, icon, color)')
        .eq('user_id', _uid!);
    if (month != null && year != null) {
      q = q
          .gte('date',
              DateTime(year, month, 1).toIso8601String().split('T').first)
          .lte('date',
              DateTime(year, month + 1, 0).toIso8601String().split('T').first);
    }
    final d = await q
        .order('date', ascending: false)
        .order('created_at', ascending: false)
        .limit(limit);
    return (d as List).map((e) => TransactionModel.fromJson(e)).toList();
  }

  Future<TransactionModel> createTransaction(TransactionModel tx) async {
    if (_isGuestMode) {
      final created = TransactionModel(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'guest_user',
        title: tx.title,
        type: tx.type,
        amount: tx.amount,
        date: tx.date,
        createdAt: DateTime.now(),
        categoryId: tx.categoryId,
        categoryName: tx.categoryName,
        categoryIcon: tx.categoryIcon,
        categoryColor: tx.categoryColor,
        note: tx.note,
      );
      _guestTransactions.insert(0, created);
      notifyDataChanged();
      return created;
    }
    if (_uid == null) throw Exception('User not authenticated');
    final payload = Map<String, dynamic>.from(tx.toJson());
    payload['user_id'] = _uid!;
    final d = await _db
        .from(AppConstants.transactionsTable)
        .insert(payload)
        .select('*, categories(name, icon, color)')
        .single();
    final created = TransactionModel.fromJson(d);
    notifyDataChanged();
    return created;
  }

  Future<void> updateTransaction(TransactionModel tx) async {
    if (_isGuestMode) {
      final idx = _guestTransactions.indexWhere((t) => t.id == tx.id);
      if (idx != -1) {
        _guestTransactions[idx] = tx;
        notifyDataChanged();
      }
      return;
    }
    if (_uid == null) return;
    final payload = Map<String, dynamic>.from(tx.toJson());
    payload['user_id'] = _uid!;
    await _db
        .from(AppConstants.transactionsTable)
        .update(payload)
        .eq('id', tx.id)
        .eq('user_id', _uid!);
    notifyDataChanged();
  }

  Future<void> deleteTransaction(String id) async {
    if (_isGuestMode) {
      _guestTransactions.removeWhere((t) => t.id == id);
      notifyDataChanged();
      return;
    }
    if (_uid == null) return;
    await _db
        .from(AppConstants.transactionsTable)
        .delete()
        .eq('id', id)
        .eq('user_id', _uid!);
    notifyDataChanged();
  }

  // ── Analytics ───────────────────────────────────────────
  Future<Map<String, double>> getMonthlySummary({
    required int month,
    required int year,
  }) async {
    if (_isGuestMode) {
      final txRows = await getTransactions(month: month, year: year);
      double inc = 0, exp = 0;
      for (final r in txRows) {
        if (r.type == 'income') {
          inc += r.amount;
        } else {
          exp += r.amount;
        }
      }
      final monthlyBudget = _guestProfile?.monthlyBudget ?? 0;
      final base = monthlyBudget > inc ? monthlyBudget : inc;
      final savingsRate =
          base > 0 ? ((inc - exp) / base * 100).clamp(-100.0, 100.0) : 0.0;
      return {
        'income': inc,
        'expense': exp,
        'balance': inc - exp,
        'savings_rate': savingsRate,
        'tx_count': txRows.length.toDouble(),
      };
    }
    if (_uid == null) return {};

    final txRows = await _db
        .from(AppConstants.transactionsTable)
        .select('amount, type')
        .eq('user_id', _uid!)
        .gte(
            'date', DateTime(year, month, 1).toIso8601String().split('T').first)
        .lte('date',
            DateTime(year, month + 1, 0).toIso8601String().split('T').first);

    final profileRow = await _db
        .from(AppConstants.profilesTable)
        .select('monthly_budget')
        .eq('id', _uid!)
        .maybeSingle();

    final monthlyBudget =
        ((profileRow?['monthly_budget'] ?? 0) as num).toDouble();

    double inc = 0, exp = 0;
    for (final r in txRows) {
      final a = ((r['amount'] ?? 0) as num).toDouble();
      if (r['type'] == 'income') {
        inc += a;
      } else {
        exp += a;
      }
    }

    final base = monthlyBudget > inc ? monthlyBudget : inc;
    final savingsRate =
        base > 0 ? ((inc - exp) / base * 100).clamp(-100.0, 100.0) : 0.0;

    return {
      'income': inc,
      'expense': exp,
      'balance': inc - exp,
      'savings_rate': savingsRate,
      'tx_count': txRows.length.toDouble(),
    };
  }

  Future<Map<String, double>> getCategorySpending({
    required int month,
    required int year,
  }) async {
    if (_isGuestMode) {
      final txs = await getTransactions(month: month, year: year);
      final Map<String, double> res = {};
      for (final r in txs) {
        if (r.type == 'expense') {
          final name = r.categoryName ?? 'Others';
          res[name] = (res[name] ?? 0) + r.amount;
        }
      }
      return res;
    }
    if (_uid == null) return {};
    final d = await _db
        .from(AppConstants.transactionsTable)
        .select('amount, categories(name)')
        .eq('user_id', _uid!)
        .eq('type', 'expense')
        .gte(
            'date', DateTime(year, month, 1).toIso8601String().split('T').first)
        .lte('date',
            DateTime(year, month + 1, 0).toIso8601String().split('T').first);
    final Map<String, double> res = {};
    for (final r in d as List) {
      final name = (r['categories'] as Map?)?['name'] as String? ?? 'Others';
      res[name] = (res[name] ?? 0) + ((r['amount'] ?? 0) as num).toDouble();
    }
    return res;
  }

  Future<List<Map<String, dynamic>>> getWeeklySpending({
    required int month,
    required int year,
  }) async {
    if (_isGuestMode) {
      final txs = await getTransactions(month: month, year: year);
      final Map<int, double> w = {1: 0, 2: 0, 3: 0, 4: 0};
      for (final r in txs) {
        if (r.type == 'expense') {
          final day = r.date.day;
          final wk = ((day - 1) ~/ 7).clamp(0, 3) + 1;
          w[wk] = (w[wk] ?? 0) + r.amount;
        }
      }
      return [
        {'week': 'W1', 'amount': w[1]!},
        {'week': 'W2', 'amount': w[2]!},
        {'week': 'W3', 'amount': w[3]!},
        {'week': 'W4', 'amount': w[4]!},
      ];
    }
    if (_uid == null) return [];
    final d = await _db
        .from(AppConstants.transactionsTable)
        .select('amount, date, type')
        .eq('user_id', _uid!)
        .gte(
            'date', DateTime(year, month, 1).toIso8601String().split('T').first)
        .lte('date',
            DateTime(year, month + 1, 0).toIso8601String().split('T').first);
    final Map<int, double> w = {1: 0, 2: 0, 3: 0, 4: 0};
    for (final r in d as List) {
      if (r['type'] == 'expense') {
        final day = DateTime.parse(r['date'] as String).day;
        final wk = ((day - 1) ~/ 7).clamp(0, 3) + 1;
        w[wk] = (w[wk] ?? 0) + ((r['amount'] ?? 0) as num).toDouble();
      }
    }
    return [
      {'week': 'W1', 'amount': w[1]!},
      {'week': 'W2', 'amount': w[2]!},
      {'week': 'W3', 'amount': w[3]!},
      {'week': 'W4', 'amount': w[4]!},
    ];
  }

  Future<List<CategoryModel>> getCategoriesWithSpending({
    required int month,
    required int year,
  }) async {
    final cats = await getCategories();
    final spending = await getCategorySpending(month: month, year: year);
    return cats.map((c) => c.copyWith(spent: spending[c.name] ?? 0)).toList()
      ..sort((a, b) => b.spent.compareTo(a.spent));
  }
}
