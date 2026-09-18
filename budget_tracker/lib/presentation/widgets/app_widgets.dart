// lib/presentation/widgets/app_widgets.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';

// ── Icon data from string key ─────────────────────────────────
IconData iconData(String key) {
  const m = <String, IconData>{
    'home': Icons.home_rounded,
    'restaurant': Icons.restaurant_rounded,
    'directions_car': Icons.directions_car_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'favorite': Icons.favorite_rounded,
    'sports_esports': Icons.sports_esports_rounded,
    'school': Icons.school_rounded,
    'bolt': Icons.bolt_rounded,
    'account_balance_wallet': Icons.account_balance_wallet_rounded,
    'more_horiz': Icons.more_horiz_rounded,
  };
  return m[key] ?? Icons.category_rounded;
}

// ── Round category icon circle (theme-aware) ──────────────────
class CatCircle extends StatelessWidget {
  final String icon;
  final double size;
  const CatCircle({super.key, required this.icon, this.size = 46});

  @override
  Widget build(BuildContext context) {
    final bg = context.catBgColor(icon);
    final fg = AppColors.catFg[icon] ?? const Color(0xFF757575);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(iconData(icon), color: fg, size: size * 0.44),
    );
  }
}

// ── Empty state (theme-aware) ─────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const EmptyState(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 56, color: context.txtMuted),
            const SizedBox(height: 12),
            Text(title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
          ]),
        ),
      );
}

// ── Transaction tile (theme-aware) ────────────────────────────
class TxTile extends StatelessWidget {
  final TransactionModel tx;
  final VoidCallback? onTap;
  final bool showDivider;
  const TxTile(
      {super.key, required this.tx, this.onTap, this.showDivider = false});

  @override
  Widget build(BuildContext context) {
    final icon = tx.categoryIcon ?? 'more_horiz';
    final color = tx.isExpense ? AppColors.expense : AppColors.income;
    final sign = tx.isExpense ? '-' : '+';
    final fmt = NumberFormat('#,##0.00');
    final mo = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final date = '${mo[tx.date.month - 1]} ${tx.date.day}';

    return Column(children: [
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            CatCircle(icon: icon, size: 44),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(tx.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('$date · ${tx.categoryName ?? 'Others'}',
                      style: Theme.of(context).textTheme.bodyMedium),
                ])),
            Text('$sign₱${fmt.format(tx.amount)}',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
        ),
      ),
      if (showDivider)
        Divider(height: 1, indent: 72, endIndent: 16, color: context.divColor),
    ]);
  }
}

// ── Section header with optional action ───────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader(
      {super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!,
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      );
}

// ── Themed surface card ───────────────────────────────────────
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: context.surfColor,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: context.divColor),
        ),
        child: child,
      );
}
