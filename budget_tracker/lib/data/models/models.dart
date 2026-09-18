// lib/data/models/models.dart
import 'package:flutter/material.dart';

// ─── ProfileModel ─────────────────────────────────────────────
class ProfileModel {
  final String id, fullName;
  final double monthlyBudget;
  final DateTime createdAt;

  const ProfileModel({
    required this.id,
    required this.fullName,
    this.monthlyBudget = 0,
    required this.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> j) => ProfileModel(
        id: (j['id'] as String?) ?? '',
        fullName: (j['full_name'] as String?) ?? 'User',
        monthlyBudget: ((j['monthly_budget'] ?? 0) as num).toDouble(),
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'monthly_budget': monthlyBudget,
      };

  ProfileModel copyWith({String? fullName, double? monthlyBudget}) =>
      ProfileModel(
        id: id,
        fullName: fullName ?? this.fullName,
        monthlyBudget: monthlyBudget ?? this.monthlyBudget,
        createdAt: createdAt,
      );
}

// ─── CategoryModel ────────────────────────────────────────────
class CategoryModel {
  final String id, userId, name, icon, colorHex;
  final double budgetLimit, spent;
  final DateTime createdAt;

  const CategoryModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.icon,
    required this.colorHex,
    this.budgetLimit = 0,
    this.spent = 0,
    required this.createdAt,
  });

  Color get color {
    try {
      return Color(int.parse('FF${colorHex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  factory CategoryModel.fromJson(Map<String, dynamic> j) => CategoryModel(
        id: (j['id'] as String?) ?? '',
        userId: (j['user_id'] as String?) ?? '',
        name: (j['name'] as String?) ?? 'Category',
        icon: (j['icon'] as String?) ?? 'more_horiz',
        colorHex: (j['color'] as String?) ?? '#757575',
        budgetLimit: ((j['budget_limit'] ?? 0) as num).toDouble(),
        spent: ((j['spent'] ?? 0) as num).toDouble(),
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'name': name,
        'icon': icon,
        'color': colorHex,
        'budget_limit': budgetLimit,
      };

  CategoryModel copyWith({double? spent}) => CategoryModel(
        id: id,
        userId: userId,
        name: name,
        icon: icon,
        colorHex: colorHex,
        budgetLimit: budgetLimit,
        spent: spent ?? this.spent,
        createdAt: createdAt,
      );
}

// ─── TransactionModel ─────────────────────────────────────────
class TransactionModel {
  final String id, userId, title, type;
  final String? categoryId, note, categoryName, categoryIcon, categoryColor;
  final double amount;
  final DateTime date, createdAt;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.type,
    required this.amount,
    required this.date,
    required this.createdAt,
    this.categoryId,
    this.note,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  });

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';

  factory TransactionModel.fromJson(Map<String, dynamic> j) {
    final cat = j['categories'] as Map<String, dynamic>?;
    return TransactionModel(
      id: (j['id'] as String?) ?? '',
      userId: (j['user_id'] as String?) ?? '',
      title: (j['title'] as String?) ?? 'Untitled',
      type: (j['type'] as String?) ?? 'expense',
      amount: ((j['amount'] ?? 0) as num).toDouble(),
      date: DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ??
          DateTime.now(),
      categoryId: j['category_id'] as String?,
      note: j['note'] as String?,
      categoryName: cat?['name'] as String?,
      categoryIcon: cat?['icon'] as String?,
      categoryColor: cat?['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'category_id': categoryId,
        'title': title,
        'amount': amount,
        'type': type,
        'note': note,
        'date': date.toIso8601String().split('T').first,
      };
}
