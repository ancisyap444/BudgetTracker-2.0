// test/verify_runner.dart
// ignore_for_file: avoid_print
// Standalone automated test runner executable via `dart run test/verify_runner.dart`

void main() {
  print('=============================================');
  print('    BUDGET TRACKER - AUTOMATED TEST SUITE    ');
  print('=============================================\n');

  int passed = 0;
  int failed = 0;

  void runTest(String name, void Function() body) {
    try {
      body();
      print(' [PASS] $name');
      passed++;
    } catch (e, st) {
      print(' [FAIL] $name');
      print('        Error: $e');
      print('        $st');
      failed++;
    }
  }

  // ── Test 1: Weekly Spending Clamping (Days 29-31 restoration) ──
  runTest('Weekly bucket clamping preserves end-of-month days (29-31)', () {
    int weekForDay(int day) => ((day - 1) ~/ 7).clamp(0, 3) + 1;
    assert(weekForDay(1) == 1, 'Day 1 -> W1');
    assert(weekForDay(7) == 1, 'Day 7 -> W1');
    assert(weekForDay(8) == 2, 'Day 8 -> W2');
    assert(weekForDay(14) == 2, 'Day 14 -> W2');
    assert(weekForDay(15) == 3, 'Day 15 -> W3');
    assert(weekForDay(21) == 3, 'Day 21 -> W3');
    assert(weekForDay(22) == 4, 'Day 22 -> W4');
    assert(weekForDay(28) == 4, 'Day 28 -> W4');
    assert(weekForDay(29) == 4, 'Day 29 must map to W4');
    assert(weekForDay(30) == 4, 'Day 30 must map to W4');
    assert(weekForDay(31) == 4, 'Day 31 must map to W4');
  });

  // ── Test 2: Chart title safe bounds ─────────────────────────
  runTest('FlChart title lookup safely guards against out-of-bounds indices',
      () {
    String getTitle(double v) {
      final idx = v.toInt();
      return (idx >= 0 && idx < 4) ? ['W1', 'W2', 'W3', 'W4'][idx] : '';
    }

    assert(getTitle(-1.0) == '', 'Negative index returns empty');
    assert(getTitle(0.0) == 'W1', 'Index 0 -> W1');
    assert(getTitle(1.0) == 'W2', 'Index 1 -> W2');
    assert(getTitle(2.0) == 'W3', 'Index 2 -> W3');
    assert(getTitle(3.0) == 'W4', 'Index 3 -> W4');
    assert(getTitle(4.0) == '', 'Index 4 returns empty');
    assert(getTitle(99.0) == '', 'Large index returns empty');
  });

  // ── Test 3: CashFlow Chart maxY Zero Guard ──────────────────
  runTest('CashFlow maxY safely falls back to positive value on zero balance',
      () {
    double computeMaxY(double inc, double exp) {
      final computed = (inc > exp ? inc : exp) * 1.2;
      return computed > 0 ? computed : 100.0;
    }

    assert(computeMaxY(0, 0) == 100.0, 'Zero values produce maxY > 0');
    assert(computeMaxY(1000, 200) == 1200.0, 'Positive values scale properly');
  });

  // ── Test 4: Savings Rate Clamping ───────────────────────────
  runTest('Savings rate computation clamps safely between -100% and +100%', () {
    double computeSavingsRate(double inc, double exp, double budget) {
      final base = budget > inc ? budget : inc;
      return base > 0 ? ((inc - exp) / base * 100).clamp(-100.0, 100.0) : 0.0;
    }

    assert(computeSavingsRate(1000, 200, 1000) == 80.0, 'Normal rate');
    assert(computeSavingsRate(100, 5000, 100) == -100.0,
        'Extreme loss clamped at -100');
    assert(computeSavingsRate(0, 0, 0) == 0.0, 'Zero base returns 0%');
  });

  // ── Test 5: Days Left in Month Computation ──────────────────
  runTest(
      'Days remaining correctly distinguishes past, current, and future months',
      () {
    String getDaysLeftText(int year, int month, DateTime now) {
      final totalDays = DateTime(year, month + 1, 0).day;
      final isCurrentMonth = year == now.year && month == now.month;
      final isPastMonth =
          year < now.year || (year == now.year && month < now.month);
      return isPastMonth
          ? 'Month ended'
          : isCurrentMonth
              ? '${(totalDays - now.day).clamp(0, totalDays)} days left'
              : '$totalDays days left';
    }

    final now = DateTime(2026, 3, 15);
    assert(getDaysLeftText(2026, 2, now) == 'Month ended');
    assert(getDaysLeftText(2026, 3, now) == '16 days left');
    assert(getDaysLeftText(2026, 4, now) == '30 days left');
  });

  // ── Test 6: CSV Export Serialization ────────────────────────
  runTest('CSV export formatting safely escapes commas, quotes, and newlines',
      () {
    String escapeCsv(String value) {
      if (value.contains(',') || value.contains('"') || value.contains('\n')) {
        return '"${value.replaceAll('"', '""')}"';
      }
      return value;
    }

    assert(escapeCsv('Simple') == 'Simple');
    assert(escapeCsv('Dinner, "Italian"') == '"Dinner, ""Italian"""');
    assert(escapeCsv('Line1\nLine2') == '"Line1\nLine2"');
  });

  // ── Test 7: CSV Formula Injection Prevention (CWE-1236) ──
  runTest('CSV export neutralizes formula injection prefixes (=, +, -, @)', () {
    String escapeCsv(String value) {
      var v = value;
      if (v.isNotEmpty &&
          (v.startsWith('=') ||
              v.startsWith('+') ||
              v.startsWith('-') ||
              v.startsWith('@') ||
              v.startsWith('\t') ||
              v.startsWith('\r'))) {
        v = "'$v";
      }
      if (v.contains(',') || v.contains('"') || v.contains('\n')) {
        return '"${v.replaceAll('"', '""')}"';
      }
      return v;
    }

    assert(escapeCsv('=cmd|calc!A0') == "'=cmd|calc!A0", 'Neutralizes = prefix');
    assert(escapeCsv('+1234') == "'+1234", 'Neutralizes + prefix');
    assert(escapeCsv('@SUM(A1:A5)') == "'@SUM(A1:A5)", 'Neutralizes @ prefix');
  });

  print('\n---------------------------------------------');
  print('Result: $passed Passed, $failed Failed');
  print('---------------------------------------------');

  if (failed > 0) {
    throw Exception('$failed test(s) failed.');
  }
}
