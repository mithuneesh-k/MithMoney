import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/bank_sms_message.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/category_model.dart';
import '../../shared/providers/app_providers.dart';

class SmsInboxScreen extends ConsumerWidget {
  const SmsInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allSms = ref.watch(smsProvider);
    final pending = allSms.where((m) => m.status == SmsStatus.pending).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SMS Bank Reader',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (pending.isNotEmpty)
                            Text(
                              '${pending.length} pending',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Sync button
                    _SyncButton(),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 12),

              if (allSms.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sms_outlined,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No bank SMS found',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap sync to read SMS from your bank senders',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    physics: const BouncingScrollPhysics(),
                    itemCount: allSms.length,
                    itemBuilder: (context, i) {
                      return _SmsTile(
                        sms: allSms[i],
                        onAddTransaction: () =>
                            _showAddTransactionSheet(context, ref, allSms[i]),
                        onDismiss: () => ref
                            .read(smsProvider.notifier)
                            .updateStatus(allSms[i].id, SmsStatus.dismissed),
                      )
                          .animate(delay: (i * 40).ms)
                          .fadeIn(duration: 300.ms)
                          .slideY(
                            begin: 0.1,
                            end: 0,
                            duration: 300.ms,
                          );
                    },
                  ),
                ),
            ],
          ),
        ),
    );
  }

  void _showAddTransactionSheet(
      BuildContext context, WidgetRef ref, BankSmsMessage sms) {
    final settings = ref.read(settingsProvider);
    final categories = ref.read(categoryProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddFromSmsSheet(
        sms: sms,
        settings: settings,
        categories: categories,
        onConfirm: (tx) async {
          await ref.read(transactionProvider.notifier).add(tx);
          await ref
              .read(smsProvider.notifier)
              .updateStatus(sms.id, SmsStatus.added);
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _SyncButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends ConsumerState<_SyncButton> {
  bool _syncing = false;

  Future<void> _sync() async {
    setState(() => _syncing = true);
    final settings = ref.read(settingsProvider);
    final service = ref.read(smsServiceProvider);
    final count = await service.syncSms(settings.knownSenderIds);
    ref.read(smsProvider.notifier).refresh();
    setState(() => _syncing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(count > 0
              ? 'Found $count new bank transactions'
              : 'No new messages found'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _syncing ? null : _sync,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: _syncing
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sync_rounded,
                      size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Sync',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SmsTile extends StatelessWidget {
  final BankSmsMessage sms;
  final VoidCallback onAddTransaction;
  final VoidCallback onDismiss;

  const _SmsTile({
    required this.sms,
    required this.onAddTransaction,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDebit = sms.parsedType == 'debit';
    final isAdded = sms.status == SmsStatus.added;
    final isDismissed = sms.status == SmsStatus.dismissed;

    final amountColor =
        isDebit ? LightColors.expenseRed : LightColors.incomeGreen;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row: sender + amount + date
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00CEC9).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    sms.sender,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF00CEC9),
                    ),
                  ),
                ),
                const Spacer(),
                if (sms.parsedAmount != null)
                  Text(
                    '₹${sms.parsedAmount!.toStringAsFixed(0)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: amountColor,
                    ),
                  ),
              ],
            ),
            if (sms.parsedMerchant != null) ...[
              const SizedBox(height: 6),
              Text(
                sms.parsedMerchant!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              sms.rawBody,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('d MMM yyyy, hh:mm a').format(sms.receivedAt),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.35),
              ),
            ),
            if (!isAdded && !isDismissed) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDismiss,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        side: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.2),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Dismiss',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onAddTransaction,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Add Transaction',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isAdded
                      ? LightColors.incomeGreen.withValues(alpha: 0.12)
                      : Colors.grey.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isAdded ? 'Added' : 'Dismissed',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isAdded ? LightColors.incomeGreen : Colors.grey,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddFromSmsSheet extends StatefulWidget {
  final BankSmsMessage sms;
  final dynamic settings;
  final List<CategoryModel> categories;
  final Future<void> Function(TransactionModel) onConfirm;

  const _AddFromSmsSheet({
    required this.sms,
    required this.settings,
    required this.categories,
    required this.onConfirm,
  });

  @override
  State<_AddFromSmsSheet> createState() => _AddFromSmsSheetState();
}

class _AddFromSmsSheetState extends State<_AddFromSmsSheet> {
  late TransactionType _type;
  late TextEditingController _amountCtrl;
  late TextEditingController _noteCtrl;
  CategoryModel? _category;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.sms.parsedType == 'credit'
        ? TransactionType.income
        : TransactionType.expense;
    _amountCtrl = TextEditingController(
      text: widget.sms.parsedAmount?.toStringAsFixed(2) ?? '',
    );
    _noteCtrl = TextEditingController(
      text: widget.sms.parsedMerchant ?? '',
    );
    final relevant = widget.categories
        .where((c) =>
            (_type == TransactionType.expense &&
                c.type == CategoryType.expense) ||
            (_type == TransactionType.income && c.type == CategoryType.income))
        .toList();
    _category = relevant.isNotEmpty ? relevant.first : null;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final relevant = widget.categories
        .where((c) =>
            (_type == TransactionType.expense &&
                c.type == CategoryType.expense) ||
            (_type == TransactionType.income && c.type == CategoryType.income))
        .toList();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add Transaction from SMS',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            // Type toggle
            Row(
              children: [
                _TypeButton(
                  label: 'Expense',
                  selected: _type == TransactionType.expense,
                  color: LightColors.expenseRed,
                  onTap: () => setState(() => _type = TransactionType.expense),
                ),
                const SizedBox(width: 10),
                _TypeButton(
                  label: 'Income',
                  selected: _type == TransactionType.income,
                  color: LightColors.incomeGreen,
                  onTap: () => setState(() => _type = TransactionType.income),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '${widget.settings.currencySymbol} ',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              decoration: InputDecoration(
                labelText: 'Note / Merchant',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CategoryModel>(
              initialValue: relevant.contains(_category) ? _category : null,
              decoration: InputDecoration(
                labelText: 'Category',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: relevant
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.name),
                      ))
                  .toList(),
              onChanged: (c) => setState(() => _category = c),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Add Transaction',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a category')),
      );
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    final tx = TransactionModel(
      id: 'sms_${widget.sms.id}',
      amount: amount,
      type: _type,
      categoryId: _category!.id,
      note: _noteCtrl.text.trim(),
      date: widget.sms.parsedDate ?? now,
      isFromSms: true,
      smsSource: widget.sms.sender,
      createdAt: now,
      updatedAt: now,
    );
    await widget.onConfirm(tx);
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:
                selected ? color.withValues(alpha: 0.15) : Colors.transparent,
            border: Border.all(
              color: selected ? color : Colors.grey.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? color : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
