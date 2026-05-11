import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction_model.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  final VoidCallback onAddTransaction;

  const TransactionsScreen({super.key, required this.onAddTransaction});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = ref.watch(filteredTransactionsProvider);
    final categories = ref.watch(categoryProvider);
    final settings = ref.watch(settingsProvider);
    final catMap = {for (final c in categories) c.id: c};
    final symbol = settings.currencySymbol;
    final typeFilter = ref.watch(transactionTypeFilterProvider);

    // Group by date
    final groups = _groupByDate(filtered);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                'Transactions',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: TextField(
                controller: _searchController,
                onChanged: (v) =>
                    ref.read(transactionSearchProvider.notifier).state = v,
                decoration: const InputDecoration(
                  hintText: 'Search transactions...',
                  prefixIcon: Icon(Icons.search_rounded),
                  suffixIcon: Icon(Icons.tune_rounded),
                ),
              ),
            ).animate(delay: 60.ms).fadeIn(duration: 300.ms),
            // Filter chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: typeFilter == null,
                      onTap: () => ref
                          .read(transactionTypeFilterProvider.notifier)
                          .state = null,
                    ),
                    _FilterChip(
                      label: 'Expense',
                      selected: typeFilter == TransactionType.expense,
                      color: const Color(0xFFE8365D),
                      onTap: () => ref
                          .read(transactionTypeFilterProvider.notifier)
                          .state = TransactionType.expense,
                    ),
                    _FilterChip(
                      label: 'Income',
                      selected: typeFilter == TransactionType.income,
                      color: const Color(0xFF00B87C),
                      onTap: () => ref
                          .read(transactionTypeFilterProvider.notifier)
                          .state = TransactionType.income,
                    ),
                    _FilterChip(
                      label: 'Transfer',
                      selected: typeFilter == TransactionType.transfer,
                      color: const Color(0xFFFFB300),
                      onTap: () => ref
                          .read(transactionTypeFilterProvider.notifier)
                          .state = TransactionType.transfer,
                    ),
                  ],
                ),
              ),
            ).animate(delay: 80.ms).fadeIn(duration: 300.ms),
            // List
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyTransactions(onAdd: widget.onAddTransaction)
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 120),
                      itemCount: groups.length,
                      itemBuilder: (ctx, groupIdx) {
                        final group = groups[groupIdx];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date header
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    group.dateLabel,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  Text(
                                    '$symbol${group.total.abs().toStringAsFixed(2)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Transactions in group
                            ...group.transactions.asMap().entries.map((e) {
                              final tx = e.value;
                              return TransactionTile(
                                transaction: tx,
                                category: catMap[tx.categoryId],
                                account: ref.watch(accountProvider).firstWhere((a) => a.id == tx.accountId, orElse: () => ref.watch(accountProvider).first),
                                currencySymbol: symbol,
                                animationIndex: e.key,
                                onDelete: () => _delete(context, tx),
                                onEdit: () => _edit(tx),
                              );
                            }),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<_DateGroup> _groupByDate(List<TransactionModel> txs) {
    final map = <String, List<TransactionModel>>{};
    for (final tx in txs) {
      final label = AppFormatters.formatDate(tx.date);
      map.putIfAbsent(label, () => []);
      map[label]!.add(tx);
    }
    return map.entries.map((e) {
      final total = e.value.fold<double>(
        0,
        (sum, t) =>
            t.type == TransactionType.expense ? sum - t.amount : sum + t.amount,
      );
      return _DateGroup(dateLabel: e.key, transactions: e.value, total: total);
    }).toList();
  }

  Future<void> _delete(BuildContext context, TransactionModel tx) async {
    await ref.read(transactionProvider.notifier).delete(tx);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction deleted')),
      );
    }
  }

  void _edit(TransactionModel tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionSheetProxy(existingTransaction: tx),
    );
  }
}

class AddTransactionSheetProxy extends StatelessWidget {
  final TransactionModel existingTransaction;
  const AddTransactionSheetProxy(
      {super.key, required this.existingTransaction});
  @override
  Widget build(BuildContext context) {
    return AddTransactionScreen(existingTransaction: existingTransaction);
  }
}

class _DateGroup {
  final String dateLabel;
  final List<TransactionModel> transactions;
  final double total;
  const _DateGroup({
    required this.dateLabel,
    required this.transactions,
    required this.total,
  });
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? chipColor : chipColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : chipColor,
          ),
        ),
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyTransactions({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 72,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.35),
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
