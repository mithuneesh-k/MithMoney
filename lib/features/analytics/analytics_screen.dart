import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction_model.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/animated_counter.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTimeRange _getRange() {
    final now = DateTime.now();
    switch (_tabController.index) {
      case 0: // Week — rolling last 7 days
        final start = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6));
        return DateTimeRange(
          start: start,
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case 1: // Month
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
      case 2: // Year
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31, 23, 59, 59),
        );
      default:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allTransactions = ref.watch(transactionProvider);
    final categories = ref.watch(categoryProvider);
    final settings = ref.watch(settingsProvider);
    final catMap = {for (final c in categories) c.id: c};
    final symbol = settings.currencySymbol;
    final range = _getRange();

    final periodTxs = allTransactions
        .where((t) =>
            t.date.isAfter(range.start.subtract(const Duration(seconds: 1))) &&
            t.date.isBefore(range.end.add(const Duration(seconds: 1))))
        .toList();

    final totalIncome = periodTxs
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
    final totalExpense = periodTxs
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);

    // Category breakdown
    final catBreakdown = <String, double>{};
    for (final t in periodTxs.where((t) => t.type == TransactionType.expense)) {
      catBreakdown[t.categoryId] = (catBreakdown[t.categoryId] ?? 0) + t.amount;
    }
    final sortedCats = catBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(
                  'Analytics',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms),
            ),
            // Period tabs
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _PeriodTabs(controller: _tabController),
              ).animate(delay: 60.ms).fadeIn(duration: 300.ms),
            ),
            // Summary cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'Income',
                        value: totalIncome,
                        color: const Color(0xFF00B87C),
                        icon: Icons.arrow_downward_rounded,
                        symbol: symbol,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Expense',
                        value: totalExpense,
                        color: const Color(0xFFE8365D),
                        icon: Icons.arrow_upward_rounded,
                        symbol: symbol,
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 120.ms).fadeIn(duration: 300.ms),
            ),
            // Donut chart
            if (catBreakdown.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spending by Category',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: _DonutChart(
                            data: sortedCats
                                .take(6)
                                .map((e) => _ChartItem(
                                      label: catMap[e.key]?.name ?? e.key,
                                      value: e.value,
                                      color: catMap[e.key]?.color ??
                                          const Color(0xFF636E72),
                                    ))
                                .toList(),
                            total: totalExpense,
                            symbol: symbol,
                            touchedIndex: _touchedIndex,
                            onTouch: (i) => setState(() => _touchedIndex = i),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: 180.ms).fadeIn(duration: 400.ms),
              ),
            // Category breakdown list
            if (sortedCats.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category Breakdown',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...sortedCats.asMap().entries.map((e) {
                          final cat = catMap[e.value.key];
                          final pct = totalExpense > 0
                              ? e.value.value / totalExpense
                              : 0.0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _CategoryBreakdownRow(
                              name: cat?.name ?? e.value.key,
                              amount: e.value.value,
                              percentage: pct,
                              color: cat?.color ?? const Color(0xFF636E72),
                              icon: cat?.icon ?? Icons.category,
                              symbol: symbol,
                              delay: e.key * 50,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ).animate(delay: 240.ms).fadeIn(duration: 400.ms),
              ),
            // Monthly bar chart
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                child: AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tabController.index == 0
                            ? 'Weekly Overview'
                            : 'Monthly Overview',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_tabController.index == 0)
                        _WeeklyBarChart(
                          transactions: periodTxs,
                          symbol: symbol,
                        )
                      else
                        _MonthlyBarChart(
                          transactions: allTransactions,
                          symbol: symbol,
                        ),
                    ],
                  ),
                ),
              ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Period Tabs ──────────────────────────────────────────────────────────────
class _PeriodTabs extends StatelessWidget {
  final TabController controller;

  const _PeriodTabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(50),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding:
            const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        labelColor: Colors.white,
        unselectedLabelColor:
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        tabs: const [
          Tab(text: 'Week'),
          Tab(text: 'Month'),
          Tab(text: 'Year'),
        ],
      ),
    );
  }
}

// ─── Summary Card ─────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  final String symbol;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      color: color.withValues(alpha: 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedCounter(
            value: value,
            prefix: symbol,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            decimalPlaces: 0,
          ),
        ],
      ),
    );
  }
}

// ─── Donut Chart ──────────────────────────────────────────────────────────────
class _DonutChart extends StatelessWidget {
  final List<_ChartItem> data;
  final double total;
  final String symbol;
  final int touchedIndex;
  final ValueChanged<int> onTouch;

  const _DonutChart({
    required this.data,
    required this.total,
    required this.symbol,
    required this.touchedIndex,
    required this.onTouch,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  if (response?.touchedSection != null) {
                    onTouch(response!.touchedSection!.touchedSectionIndex);
                  } else {
                    onTouch(-1);
                  }
                },
              ),
              sections: data.asMap().entries.map((e) {
                final isTouched = e.key == touchedIndex;
                return PieChartSectionData(
                  value: e.value.value,
                  color: e.value.color,
                  radius: isTouched ? 64 : 56,
                  showTitle: false,
                );
              }).toList(),
              centerSpaceRadius: 48,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: data
              .map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: item.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.label.split(' ').first,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _ChartItem {
  final String label;
  final double value;
  final Color color;
  const _ChartItem(
      {required this.label, required this.value, required this.color});
}

// ─── Category Breakdown Row ───────────────────────────────────────────────────
class _CategoryBreakdownRow extends StatefulWidget {
  final String name;
  final double amount;
  final double percentage;
  final Color color;
  final IconData icon;
  final String symbol;
  final int delay;

  const _CategoryBreakdownRow({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.icon,
    required this.symbol,
    this.delay = 0,
  });

  @override
  State<_CategoryBreakdownRow> createState() => _CategoryBreakdownRowState();
}

class _CategoryBreakdownRowState extends State<_CategoryBreakdownRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween<double>(begin: 0, end: widget.percentage).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutExpo),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(widget.icon, color: widget.color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    AppFormatters.formatAmountCompact(
                        widget.amount, widget.symbol),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: widget.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedBuilder(
                animation: _anim,
                builder: (_, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _anim.value,
                    backgroundColor: widget.color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                    minHeight: 6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Monthly Bar Chart ────────────────────────────────────────────────────────
class _MonthlyBarChart extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String symbol;

  const _MonthlyBarChart({required this.transactions, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthlyData = <int, double>{};
    for (int i = 0; i < 6; i++) {
      monthlyData[i] = 0;
    }
    for (final t in transactions) {
      if (t.type == TransactionType.expense) {
        final diff = (now.year - t.date.year) * 12 + (now.month - t.date.month);
        if (diff >= 0 && diff < 6) {
          monthlyData[5 - diff] = (monthlyData[5 - diff] ?? 0) + t.amount;
        }
      }
    }
    final maxVal = monthlyData.values.fold(0.0, (m, v) => v > m ? v : m);
    final accent = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal > 0 ? maxVal * 1.2 : 100,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                '$symbol${rod.toY.toStringAsFixed(0)}',
                GoogleFonts.plusJakartaSans(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  final date = DateTime(now.year, now.month - (5 - idx));
                  return Text(
                    AppFormatters.formatMonthShort(date).split(' ').first,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
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
          barGroups: List.generate(6, (i) {
            final isCurrentMonth = i == 5;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: monthlyData[i] ?? 0,
                  width: 22,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(6)),
                  color: isCurrentMonth ? accent : accent.withValues(alpha: 0.25),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ─── Weekly Bar Chart ─────────────────────────────────────────────────────────
class _WeeklyBarChart extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String symbol;

  const _WeeklyBarChart({required this.transactions, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Index 0 = 6 days ago, index 6 = today
    final dailyData = <int, double>{};
    for (int i = 0; i < 7; i++) {
      dailyData[i] = 0;
    }

    for (final t in transactions) {
      if (t.type == TransactionType.expense) {
        final txDay = DateTime(t.date.year, t.date.month, t.date.day);
        final daysAgo = today.difference(txDay).inDays;
        if (daysAgo >= 0 && daysAgo < 7) {
          final index = 6 - daysAgo;
          dailyData[index] = (dailyData[index] ?? 0) + t.amount;
        }
      }
    }
    final maxVal = dailyData.values.fold(0.0, (m, v) => v > m ? v : m);
    final accent = Theme.of(context).colorScheme.primary;
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal > 0 ? maxVal * 1.2 : 100,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                '$symbol${rod.toY.toStringAsFixed(0)}',
                GoogleFonts.plusJakartaSans(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  final day = today.subtract(Duration(days: 6 - idx));
                  return Text(
                    dayNames[day.weekday - 1],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
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
            final isToday = i == 6;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: dailyData[i] ?? 0.0,
                  width: 14,
                  color: isToday ? accent : accent.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
