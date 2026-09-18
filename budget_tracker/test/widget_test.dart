import 'package:flutter_test/flutter_test.dart';
import 'package:budget_tracker_app/data/models/models.dart';

void main() {
  group('ProfileModel Tests', () {
    test('parses from valid JSON', () {
      final json = {
        'id': 'user-123',
        'full_name': 'Juan Dela Cruz',
        'monthly_budget': 15000,
        'created_at': '2026-01-01T12:00:00Z',
      };
      final profile = ProfileModel.fromJson(json);
      expect(profile.id, 'user-123');
      expect(profile.fullName, 'Juan Dela Cruz');
      expect(profile.monthlyBudget, 15000.0);
    });

    test('handles null fields with safe fallbacks', () {
      final json = <String, dynamic>{};
      final profile = ProfileModel.fromJson(json);
      expect(profile.id, '');
      expect(profile.fullName, 'User');
      expect(profile.monthlyBudget, 0.0);
      expect(profile.createdAt, isNotNull);
    });
  });

  group('CategoryModel Tests', () {
    test('parses colorHex correctly', () {
      final json = {
        'id': 'cat-1',
        'user_id': 'u-1',
        'name': 'Food & Dining',
        'icon': 'restaurant',
        'color': '#FF9800',
        'budget_limit': 5000,
        'spent': 1200,
        'created_at': '2026-01-01T00:00:00Z',
      };
      final cat = CategoryModel.fromJson(json);
      expect(cat.name, 'Food & Dining');
      expect(cat.color.toARGB32(), 0xFFFF9800);
      expect(cat.spent, 1200.0);
    });

    test('handles fallback on invalid color hex', () {
      final json = {
        'id': 'cat-2',
        'user_id': 'u-1',
        'name': 'Misc',
        'icon': 'more_horiz',
        'color': 'invalid',
        'created_at': '2026-01-01T00:00:00Z',
      };
      final cat = CategoryModel.fromJson(json);
      expect(cat.color, isNotNull);
    });
  });

  group('TransactionModel Tests', () {
    test('parses transaction correctly and computes flags', () {
      final json = {
        'id': 'tx-1',
        'user_id': 'u-1',
        'title': 'Groceries',
        'type': 'expense',
        'amount': 750.50,
        'date': '2026-03-15',
        'created_at': '2026-03-15T10:30:00Z',
        'categories': {
          'name': 'Food & Dining',
          'icon': 'restaurant',
          'color': '#FF9800',
        },
      };
      final tx = TransactionModel.fromJson(json);
      expect(tx.isExpense, isTrue);
      expect(tx.isIncome, isFalse);
      expect(tx.categoryName, 'Food & Dining');
      expect(tx.amount, 750.50);
      expect(tx.date.day, 15);
    });

    test('handles missing category and date gracefully', () {
      final json = {
        'id': 'tx-2',
        'user_id': 'u-1',
        'title': 'Salary',
        'type': 'income',
        'amount': 25000,
      };
      final tx = TransactionModel.fromJson(json);
      expect(tx.isIncome, isTrue);
      expect(tx.isExpense, isFalse);
      expect(tx.categoryName, isNull);
      expect(tx.date, isNotNull);
    });
  });

  group('Weekly Bucket Analytics Logic', () {
    int weekForDay(int day) => ((day - 1) ~/ 7).clamp(0, 3) + 1;

    test('maps all 31 days into 4 standard weeks without omitting end-of-month',
        () {
      expect(weekForDay(1), 1);
      expect(weekForDay(7), 1);
      expect(weekForDay(8), 2);
      expect(weekForDay(14), 2);
      expect(weekForDay(15), 3);
      expect(weekForDay(21), 3);
      expect(weekForDay(22), 4);
      expect(weekForDay(28), 4);
      // Days 29-31 must be counted in Week 4 rather than discarded
      expect(weekForDay(29), 4);
      expect(weekForDay(30), 4);
      expect(weekForDay(31), 4);
    });
  });
}
