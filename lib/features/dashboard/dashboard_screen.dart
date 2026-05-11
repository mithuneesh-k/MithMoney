import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction_model.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/animated_counter.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/transaction_tile.dart';
import '../tips/tips_data.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final VoidCallback onAddTransaction;
  final VoidCallback onViewAllTransactions;

  const DashboardScreen({
    super.key,
    required this.onAddTransaction,
    required this.onViewAllTransactions,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late final String _tipOfDay;

  @override
  void initState() {
    super.initState();
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    _tipOfDay = allTips[dayOfYear % allTips.length].text;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final categories = ref.watch(categoryProvider);
    final symbol = settings.currencySymbol;

    final catMap = {for (final c in categories) c.id: c};
    final txNotifier = ref.read(transactionProvider.notifier);
    final selectedAcc = ref.watch(selectedAccountProvider);
    final recent = ref.watch(filteredTransactionsProvider).take(5).toList();
    
    // Calculate balances based on filter
    double balance, monthlyIncome, monthlyExpense;
    if (selectedAcc != null) {
      balance = selectedAcc.balance;
      // We still need this month's stats for the cards
      final thisMonthTxs = ref.watch(filteredTransactionsProvider).where((t) {
        final now = DateTime.now();
        return t.date.month == now.month && t.date.year == now.year;
      }).toList();
      monthlyIncome = thisMonthTxs.where((t) => t.type == TransactionType.income).fold(0, (sum, t) => sum + t.amount);
      monthlyExpense = thisMonthTxs.where((t) => t.type == TransactionType.expense).fold(0, (sum, t) => sum + t.amount);
    } else {
      monthlyIncome = txNotifier.thisMonthIncome;
      monthlyExpense = txNotifier.thisMonthExpense;
      balance = monthlyIncome - monthlyExpense; // or total balance across all accounts?
      // Let's use sum of all accounts for total balance
      balance = ref.watch(accountProvider).fold(0, (sum, a) => sum + a.balance);
    }
    final budgetRatio =
        settings.monthlyBudget != null && settings.monthlyBudget! > 0
            ? (monthlyExpense / settings.monthlyBudget!).clamp(0.0, 1.0)
            : 0.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header section — greeting + balance card in a tinted container for light mode
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.transparent 
                    : accent.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(28),
                      ),
                    ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${AppFormatters.formatGreeting()},',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              Text(
                                settings.userName.isNotEmpty
                                    ? '${settings.userName} 👋'
                                    : 'Welcome 👋',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          if (settings.avatarPath != null)
                            CircleAvatar(
                              radius: 22,
                              backgroundImage: AssetImage(settings.avatarPath!),
                            )
                          else
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_rounded,
                                  color: Colors.white, size: 22),
                            ),
                        ],
                      ),
                    ).animate(delay: 0.ms).fadeIn(duration: 400.ms),
                    
                    // Account Filter / Balance list
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 54,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: ref.watch(accountProvider).length + 1,
                        itemBuilder: (ctx, i) {
                          if (i == 0) {
                            final isAll = ref.watch(selectedAccountIdProvider) == null;
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: ChoiceChip(
                                label: const Text('All Accounts'),
                                selected: isAll,
                                onSelected: (val) => ref.read(selectedAccountIdProvider.notifier).state = null,
                                labelStyle: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isAll ? Colors.white : Theme.of(context).colorScheme.onSurface,
                                ),
                                selectedColor: accent,
                                backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                showCheckmark: false,
                              ),
                            );
                          }
                          final acc = ref.watch(accountProvider)[i - 1];
                          final isSelected = ref.watch(selectedAccountIdProvider) == acc.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ChoiceChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(acc.icon, size: 14, color: isSelected ? Colors.white : acc.color),
                                  const SizedBox(width: 8),
                                  Text(acc.name),
                                ],
                              ),
                              selected: isSelected,
                              onSelected: (val) => ref.read(selectedAccountIdProvider.notifier).state = val ? acc.id : null,
                              labelStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                              ),
                              selectedColor: accent,
                              backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              showCheckmark: false,
                            ),
                          );
                        },
                      ),
                    ).animate(delay: 50.ms).fadeIn(duration: 400.ms),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: _BalanceCard(
                        balance: balance,
                        income: monthlyIncome,
                        expense: monthlyExpense,
                        budgetRatio: budgetRatio,
                        currencySymbol: symbol,
                        monthlyBudget: settings.monthlyBudget,
                      ),
                    ).animate(delay: 60.ms).fadeIn(duration: 500.ms).scale(
                          begin: const Offset(0.92, 0.92),
                          end: const Offset(1, 1),
                          duration: 500.ms,
                          curve: Curves.easeOutExpo,
                        ),
                  ],
                ),
              ),
            ),
          ),

          // Quick actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _QuickActions(onAddTransaction: widget.onAddTransaction),
            ).animate(delay: 240.ms).fadeIn(duration: 400.ms),
          ),

          // Mini bar chart
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: _MiniBarChart(
                  transactions:
                      ref.read(transactionRepoProvider).getLast7Days(),
                  currencySymbol: symbol,
                ),
              ),
            ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
          ),

          // Recent transactions
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Recent Transactions',
              actionLabel: 'See All',
              onAction: widget.onViewAllTransactions,
            ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
          ),

          if (recent.isEmpty)
            SliverToBoxAdapter(
              child: _EmptyState(onAdd: widget.onAddTransaction),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final tx = recent[i];
                  return TransactionTile(
                    transaction: tx,
                    category: catMap[tx.categoryId],
                    account: ref.watch(accountProvider).firstWhere((a) => a.id == tx.accountId, orElse: () => ref.watch(accountProvider).first),
                    currencySymbol: symbol,
                    animationIndex: i,
                    onTap: () => _showDetail(context, tx),
                    onDelete: () => _deleteTransaction(tx),
                    onEdit: () => _editTransaction(tx),
                  );
                },
                childCount: recent.length,
              ),
            ),

          // Tip card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              child: _TipCard(tip: _tipOfDay),
            ).animate(delay: 500.ms).fadeIn(duration: 400.ms).rotate(
                begin: 0.03,
                end: 0,
                duration: 500.ms,
                curve: Curves.easeOutExpo),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, TransactionModel tx) {
    final categories = ref.read(categoryProvider);
    final cat = categories.firstWhere(
      (c) => c.id == tx.categoryId,
      orElse: () => categories.last,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TransactionDetail(transaction: tx, category: cat),
    );
  }

  Future<void> _deleteTransaction(TransactionModel tx) async {
    await ref.read(transactionProvider.notifier).delete(tx);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Transaction deleted'),
          action: SnackBarAction(label: 'Undo', onPressed: () {}),
        ),
      );
    }
  }

  void _editTransaction(TransactionModel tx) {
    Navigator.of(context).pushNamed('/add-transaction', arguments: tx);
  }
}

// ─── Balance Card ─────────────────────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;
  final double budgetRatio;
  final String currencySymbol;
  final double? monthlyBudget;

  const _BalanceCard({
    required this.balance,
    required this.income,
    required this.expense,
    required this.budgetRatio,
    required this.currencySymbol,
    this.monthlyBudget,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Month',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedCounter(
            value: balance,
            prefix: currencySymbol,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _IncomeExpenseItem(
                  label: 'Income',
                  value: income,
                  color:
                      isDark ? DarkColors.incomeGreen : LightColors.incomeGreen,
                  icon: Icons.arrow_downward_rounded,
                  currencySymbol: currencySymbol,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _IncomeExpenseItem(
                  label: 'Expense',
                  value: expense,
                  color:
                      isDark ? DarkColors.expenseRed : LightColors.expenseRed,
                  icon: Icons.arrow_upward_rounded,
                  currencySymbol: currencySymbol,
                ),
              ),
              if (monthlyBudget != null && monthlyBudget! > 0) ...[
                const SizedBox(width: 16),
                _BudgetRing(ratio: budgetRatio, accent: accent),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _IncomeExpenseItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  final String currencySymbol;

  const _IncomeExpenseItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 12, color: color),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        AnimatedCounter(
          value: value,
          prefix: currencySymbol,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
          decimalPlaces: 0,
        ),
      ],
    );
  }
}

class _BudgetRing extends StatelessWidget {
  final double ratio;
  final Color accent;

  const _BudgetRing({required this.ratio, required this.accent});

  @override
  Widget build(BuildContext context) {
    final color = ratio >= 0.85
        ? const Color(0xFFE8365D)
        : ratio >= 0.6
            ? const Color(0xFFFFB300)
            : const Color(0xFF00B87C);

    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: ratio,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeWidth: 5,
            strokeCap: StrokeCap.round,
          ),
          Text(
            '${(ratio * 100).toStringAsFixed(0)}%',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Actions ────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  final VoidCallback onAddTransaction;

  const _QuickActions({required this.onAddTransaction});

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        icon: Icons.remove_circle_outline_rounded,
        label: 'Expense',
        color: const Color(0xFFE8365D)
      ),
      (
        icon: Icons.add_circle_outline_rounded,
        label: 'Income',
        color: const Color(0xFF00B87C)
      ),
      (
        icon: Icons.swap_horiz_rounded,
        label: 'Transfer',
        color: const Color(0xFFFFB300)
      ),
      (
        icon: Icons.sms_rounded,
        label: 'Scan SMS',
        color: const Color(0xFF6C63FF)
      ),
    ];

    return Row(
      children: List.generate(actions.length, (i) {
        final a = actions[i];
        return Expanded(
          child: GestureDetector(
            onTap: onAddTransaction,
            child: Container(
              margin: EdgeInsets.only(right: i < actions.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: a.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: a.color.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(a.icon, color: a.color, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    a.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: a.color,
                    ),
                  ),
                ],
              ),
            ),
          ).animate(delay: Duration(milliseconds: 240 + i * 40)).scale(
              begin: const Offset(0, 0),
              duration: 400.ms,
              curve: Curves.elasticOut),
        );
      }),
    );
  }
}

// ─── Mini Bar Chart ───────────────────────────────────────────────────────────
class _MiniBarChart extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String currencySymbol;

  const _MiniBarChart({
    required this.transactions,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    // Build daily data for last 7 days
    final now = DateTime.now();
    final dailyData = <int, double>{};
    for (int i = 6; i >= 0; i--) {
      dailyData[i] = 0;
    }
    for (final tx in transactions) {
      if (tx.type == TransactionType.expense) {
        final daysAgo = now.difference(tx.date).inDays;
        if (daysAgo >= 0 && daysAgo < 7) {
          dailyData[daysAgo] = (dailyData[daysAgo] ?? 0) + tx.amount;
        }
      }
    }

    final maxVal = dailyData.values.fold(0.0, (m, v) => v > m ? v : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '7-Day Spending',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal > 0 ? maxVal * 1.2 : 100,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final val = rod.toY;
                    return BarTooltipItem(
                      '$currencySymbol${val.toStringAsFixed(0)}',
                      GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) {
                      final daysAgo = 6 - value.toInt();
                      final day = now.subtract(Duration(days: daysAgo));
                      return Text(
                        AppFormatters.formatDayShort(day),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(7, (i) {
                final daysAgo = 6 - i;
                final val = dailyData[daysAgo] ?? 0;
                final isToday = daysAgo == 0;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: val,
                      width: 18,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(6)),
                      color: isToday ? accent : accent.withValues(alpha: 0.4),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Tip Card ─────────────────────────────────────────────────────────────────
class _TipCard extends StatelessWidget {
  final String tip;

  const _TipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lightbulb_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 Tip of the Day',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6C63FF),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first transaction',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Transaction'),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ─── Transaction Detail Sheet ─────────────────────────────────────────────────
class _TransactionDetail extends StatelessWidget {
  final TransactionModel transaction;
  final dynamic category;

  const _TransactionDetail({required this.transaction, required this.category});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = transaction.type == TransactionType.income;
    final amountColor = isIncome
        ? (isDark ? DarkColors.incomeGreen : LightColors.incomeGreen)
        : transaction.type == TransactionType.transfer
            ? (isDark ? DarkColors.transferColor : LightColors.transferColor)
            : (isDark ? DarkColors.expenseRed : LightColors.expenseRed);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1428) : const Color(0xFFF8FAFF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            if (category != null)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(category.icon, color: category.color, size: 30),
              ),
            const SizedBox(height: 12),
            Text(
              '${isIncome ? '+' : transaction.type == TransactionType.transfer ? '↔ ' : '-'}${AppFormatters.formatAmount(transaction.amount, '')}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: amountColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppFormatters.formatDateTime(transaction.date),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
            if (transaction.note.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                transaction.note,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
