import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_logger.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/account_model.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/app_card.dart';
import '../categories/manage_categories_screen.dart';
import '../settings/manage_accounts_screen.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final TransactionModel? existingTransaction;

  const AddTransactionScreen({super.key, this.existingTransaction});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen>
    with TickerProviderStateMixin {
  late TransactionType _selectedType;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late TextEditingController _tagsController;
  String? _selectedCategoryId;
  String? _selectedAccountId;
  DateTime _selectedDate = DateTime.now();
  String? _receiptImagePath;
  bool _isSaving = false;
  bool _showSuccess = false;

  late AnimationController _saveButtonController;
  late AnimationController _successController;
  late Animation<double> _buttonWidthFactor;
  late Animation<double> _successScale;

  @override
  void initState() {
    super.initState();
    final ex = widget.existingTransaction;
    _selectedType = ex?.type ?? TransactionType.expense;
    _amountController =
        TextEditingController(text: ex != null ? ex.amount.toString() : '');
    _noteController = TextEditingController(text: ex?.note ?? '');
    _tagsController = TextEditingController(text: ex?.tags.join(', ') ?? '');
    _selectedCategoryId = ex?.categoryId;
    _selectedAccountId = ex?.accountId;
    _selectedDate = ex?.date ?? DateTime.now();

    _saveButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _buttonWidthFactor = Tween<double>(begin: 1.0, end: 0.18).animate(
      CurvedAnimation(parent: _saveButtonController, curve: Curves.easeInOut),
    );
    _successScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _tagsController.dispose();
    _saveButtonController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Color get _typeColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (_selectedType) {
      case TransactionType.expense:
        return isDark ? DarkColors.expenseRed : LightColors.expenseRed;
      case TransactionType.income:
        return isDark ? DarkColors.incomeGreen : LightColors.incomeGreen;
      case TransactionType.transfer:
        return isDark ? DarkColors.transferColor : LightColors.transferColor;
    }
  }

  Future<void> _save() async {
    // ── Input validation ──────────────────────────────────────────────────
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      _showError('Please enter an amount');
      return;
    }
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount greater than 0');
      return;
    }
    if (_selectedCategoryId == null) {
      _showError('Please select a category');
      return;
    }
    if (_selectedAccountId == null) {
      _showError('Please select an account');
      return;
    }

    setState(() => _isSaving = true);
    _saveButtonController.forward();

    try {
      await Future.delayed(const Duration(milliseconds: 400));

      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final ex = widget.existingTransaction;
      final now = DateTime.now();
      final transaction = TransactionModel(
        id: ex?.id ?? const Uuid().v4(),
        amount: amount,
        type: _selectedType,
        categoryId: _selectedCategoryId!,
        note: _noteController.text.trim(),
        tags: tags,
        date: _selectedDate,
        receiptImagePath: _receiptImagePath,
        accountId: _selectedAccountId,
        isFromSms: ex?.isFromSms ?? false,
        smsSource: ex?.smsSource,
        createdAt: ex?.createdAt ?? now,
        updatedAt: now,
      );

      AppLogger.i('AddTransaction',
          '${ex != null ? 'Updating' : 'Saving'} transaction id=${transaction.id} amount=${transaction.amount} type=${transaction.type.name} category=${transaction.categoryId}');

      if (ex != null) {
        await ref.read(transactionProvider.notifier).update(ex, transaction);
      } else {
        await ref.read(transactionProvider.notifier).add(transaction);
      }

      AppLogger.i('AddTransaction', 'Transaction saved successfully');

      HapticFeedback.mediumImpact();
      _saveButtonController.reverse();
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _showSuccess = true;
      });
      _successController.forward();
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e, stack) {
      AppLogger.e('AddTransaction', 'Failed to save transaction', e, stack);
      _saveButtonController.reverse();
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showError(
          'Failed to save transaction. Please try again.\n${e.toString()}');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: const Color(0xFFE8365D),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      if (!mounted) return;
      final timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      setState(() {
        _selectedDate = timePicked != null
            ? DateTime(picked.year, picked.month, picked.day, timePicked.hour,
                timePicked.minute)
            : picked;
      });
    }
  }

  Future<void> _pickReceipt() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _receiptImagePath = image.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = ref.watch(categoryProvider);

    final relevantCats = categories.where((c) {
      if (_selectedType == TransactionType.expense) {
        return c.type == CategoryType.expense || c.type == CategoryType.both;
      } else if (_selectedType == TransactionType.income) {
        return c.type == CategoryType.income || c.type == CategoryType.both;
      }
      return true;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1428) : const Color(0xFFF8FAFF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 1.0,
        minChildSize: 0.75,
        maxChildSize: 1.0,
        expand: false,
        builder: (ctx, scrollController) => SafeArea(
          top: false,
          child: CustomScrollView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Title bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.existingTransaction != null
                                ? 'Edit Transaction'
                                : 'Add Transaction',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    // Type toggle
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _TypeToggle(
                        selected: _selectedType,
                        onChanged: (t) => setState(() {
                          _selectedType = t;
                          _selectedCategoryId = null;
                        }),
                      ),
                    ).animate().fadeIn(duration: 300.ms),
                    const SizedBox(height: 20),
                    // Amount field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _AmountField(
                        controller: _amountController,
                        typeColor: _typeColor,
                        currencySymbol:
                            ref.read(settingsProvider).currencySymbol,
                      ),
                    ).animate(delay: 60.ms).fadeIn(duration: 300.ms),
                    const SizedBox(height: 16),
                    // Category picker
                    _CategoryPicker(
                      categories: relevantCats,
                      selectedId: _selectedCategoryId,
                      onSelect: (id) =>
                          setState(() => _selectedCategoryId = id),
                    ).animate(delay: 120.ms).fadeIn(duration: 300.ms),
                    const SizedBox(height: 16),
                    // Account selector
                    _AccountSelector(
                      accounts: ref.watch(accountProvider),
                      selectedId: _selectedAccountId,
                      onSelect: (id) => setState(() => _selectedAccountId = id),
                    ).animate(delay: 140.ms).fadeIn(duration: 300.ms),
                    const SizedBox(height: 16),
                    // Note
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          hintText: 'Note (optional)',
                          prefixIcon: Icon(Icons.notes_rounded),
                        ),
                        maxLines: 2,
                      ),
                    ).animate(delay: 160.ms).fadeIn(duration: 300.ms),
                    const SizedBox(height: 12),
                    // Tags
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: _tagsController,
                        decoration: const InputDecoration(
                          hintText: 'Tags (comma separated)',
                          prefixIcon: Icon(Icons.label_outline_rounded),
                        ),
                      ),
                    ).animate(delay: 180.ms).fadeIn(duration: 300.ms),
                    const SizedBox(height: 12),
                    // Date & Receipt row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _DateButton(
                              date: _selectedDate,
                              onTap: _pickDate,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _ReceiptButton(
                            imagePath: _receiptImagePath,
                            onTap: _pickReceipt,
                          ),
                        ],
                      ),
                    ).animate(delay: 200.ms).fadeIn(duration: 300.ms),
                    const SizedBox(height: 32),
                    // Save button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _showSuccess
                          ? Center(
                              child: ScaleTransition(
                                scale: _successScale,
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF00B87C),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                              ),
                            )
                          : AnimatedBuilder(
                              animation: _buttonWidthFactor,
                              builder: (ctx, _) => SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _save,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _typeColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          widget.existingTransaction != null
                                              ? 'Update'
                                              : 'Save Transaction',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Type Toggle ──────────────────────────────────────────────────────────────
class _TypeToggle extends StatelessWidget {
  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;

  const _TypeToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final types = [
      (
        type: TransactionType.expense,
        label: 'Expense',
        color: const Color(0xFFE8365D)
      ),
      (
        type: TransactionType.income,
        label: 'Income',
        color: const Color(0xFF00B87C)
      ),
      (
        type: TransactionType.transfer,
        label: 'Transfer',
        color: const Color(0xFFFFB300)
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: types.map((t) {
          final isSelected = selected == t.type;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(t.type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutExpo,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? t.color : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: const [],
                ),
                child: Text(
                  t.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Amount Field ─────────────────────────────────────────────────────────────
class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final Color typeColor;
  final String currencySymbol;

  const _AmountField({
    required this.controller,
    required this.typeColor,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Text(
            currencySymbol,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: typeColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                hintText: '0.00',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.3),
                ),
              ),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category Picker ──────────────────────────────────────────────────────────
class _CategoryPicker extends StatelessWidget {
  final List<CategoryModel> categories;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _CategoryPicker({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Category',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ManageCategoriesScreen(),
                  ));
                },
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded,
                        size: 14, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Manage',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            // +1 for the "Add Category" button at end
            itemCount: categories.length + 1,
            itemBuilder: (ctx, i) {
              // Last item: "Add" button
              if (i == categories.length) {
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const ManageCategoriesScreen(),
                    ));
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded,
                            size: 24,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.4)),
                        const SizedBox(height: 4),
                        Text(
                          'New',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
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
                );
              }

              final cat = categories[i];
              final isSelected = cat.id == selectedId;
              return GestureDetector(
                onTap: () => onSelect(cat.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutExpo,
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  transform: isSelected
                      ? Matrix4.diagonal3Values(1.1, 1.1, 1.0)
                      : Matrix4.identity(),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cat.color.withValues(alpha: 0.2)
                        : cat.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? cat.color
                          : cat.color.withValues(alpha: 0.2),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(cat.icon, color: cat.color, size: 24),
                      const SizedBox(height: 4),
                      Text(
                        cat.name.split(' ').first,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: cat.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate(delay: Duration(milliseconds: i * 20)).scale(
                  begin: const Offset(0, 0),
                  duration: 300.ms,
                  curve: Curves.elasticOut);
            },
          ),
        ),
      ],
    );
  }
}

// ─── Date Button ──────────────────────────────────────────────────────────────
class _DateButton extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _DateButton({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded,
              size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${date.day}/${date.month}/${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Receipt Button ───────────────────────────────────────────────────────────
class _ReceiptButton extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onTap;

  const _ReceiptButton({this.imagePath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Icon(
        imagePath != null
            ? Icons.image_rounded
            : Icons.add_photo_alternate_outlined,
        color: imagePath != null
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        size: 22,
      ),
    );
  }
}
// ─── Account Selector ─────────────────────────────────────────────────────────
class _AccountSelector extends StatelessWidget {
  final List<AccountModel> accounts;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _AccountSelector({
    required this.accounts,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Account',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: accounts.length + 1,
            itemBuilder: (ctx, i) {
              if (i == accounts.length) {
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const ManageAccountsScreen(),
                    ));
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'New',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final acc = accounts[i];
              final isSelected = acc.id == selectedId;
              return GestureDetector(
                onTap: () => onSelect(acc.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutExpo,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        acc.icon,
                        size: 18,
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        acc.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
