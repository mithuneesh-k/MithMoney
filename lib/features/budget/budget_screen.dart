import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/category_model.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/budget_progress_bar.dart';
import '../../shared/widgets/animated_counter.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final categories = ref.watch(categoryProvider);
    final txNotifier = ref.read(transactionProvider.notifier);
    final symbol = settings.currencySymbol;

    final monthlyExpense = txNotifier.thisMonthExpense;
    final monthlyBudget = settings.monthlyBudget ?? 0;
    final budgetRatio = monthlyBudget > 0
        ? (monthlyExpense / monthlyBudget).clamp(0.0, 1.5)
        : 0.0;

    // Per-category spending this month
    final catExpenses =
        ref.read(transactionRepoProvider).getExpenseByCategory();

    final expenseCategories = categories
        .where((c) =>
            c.type == CategoryType.expense || c.type == CategoryType.both)
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Budget',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _editBudget(context),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Edit'),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),
            ),

            // Overall budget card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Monthly Budget',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          if (budgetRatio >= 0.85)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8365D)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                budgetRatio >= 1.0
                                    ? '⚠ Overspent'
                                    : '⚠ Near Limit',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFE8365D),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AnimatedCounter(
                            value: monthlyExpense,
                            prefix: symbol,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            decimalPlaces: 0,
                          ),
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '/ $symbol${monthlyBudget.toStringAsFixed(0)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      BudgetProgressBar(
                        label: '',
                        spent: monthlyExpense,
                        budget: monthlyBudget,
                        currencySymbol: symbol,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        monthlyBudget > monthlyExpense
                            ? '$symbol${(monthlyBudget - monthlyExpense).toStringAsFixed(0)} left to spend'
                            : '$symbol${(monthlyExpense - monthlyBudget).toStringAsFixed(0)} over budget',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: budgetRatio >= 1.0
                              ? const Color(0xFFE8365D)
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate(delay: 60.ms).fadeIn(duration: 400.ms),
            ),

            // Per-category budgets
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text(
                  'Category Budgets',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ).animate(delay: 100.ms).fadeIn(duration: 300.ms),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final cat = expenseCategories[i];
                    final spent = catExpenses[cat.id] ?? 0;
                    final budget = cat.budgetLimit ?? 0;
                    if (budget == 0 && spent == 0) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: cat.color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(cat.icon,
                                      color: cat.color, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: BudgetProgressBar(
                                    label: cat.name,
                                    spent: spent,
                                    budget: budget > 0 ? budget : spent * 1.5,
                                    color: cat.color,
                                    currencySymbol: symbol,
                                    animationDelay: i * 80,
                                  ),
                                ),
                                if (budget == 0)
                                  TextButton(
                                    onPressed: () =>
                                        _setCategoryBudget(context, cat),
                                    child: const Text('Set'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate(delay: Duration(milliseconds: 120 + i * 60))
                        .fadeIn(duration: 400.ms)
                        .slideY(
                            begin: 0.2,
                            end: 0,
                            duration: 400.ms,
                            curve: Curves.easeOutExpo);
                  },
                  childCount: expenseCategories.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editBudget(BuildContext context) async {
    final settings = ref.read(settingsProvider);
    final controller = TextEditingController(
        text: settings.monthlyBudget?.toStringAsFixed(0) ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Monthly Budget',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter budget amount',
            prefixText: settings.currencySymbol,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                ref.read(settingsProvider.notifier).setMonthlyBudget(val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _setCategoryBudget(
      BuildContext context, CategoryModel cat) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Budget for ${cat.name}',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter budget amount',
            prefixText: ref.read(settingsProvider).currencySymbol,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                final updated = cat.copyWith(budgetLimit: val);
                ref.read(categoryProvider.notifier).update(updated);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
