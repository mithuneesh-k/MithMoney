import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/category_model.dart';
import '../../shared/providers/app_providers.dart';

// ─── Icon catalogue (Material Icons — free & bundled) ──────────────────────
const _iconCatalogue = <String, List<({String label, IconData icon})>>{
  'Finance': [
    (label: 'Wallet', icon: Icons.account_balance_wallet_rounded),
    (label: 'Bank', icon: Icons.account_balance_rounded),
    (label: 'Cash', icon: Icons.payments_rounded),
    (label: 'Card', icon: Icons.credit_card_rounded),
    (label: 'Savings', icon: Icons.savings_rounded),
    (label: 'Trending Up', icon: Icons.trending_up_rounded),
    (label: 'Trending Down', icon: Icons.trending_down_rounded),
    (label: 'Currency', icon: Icons.currency_exchange_rounded),
    (label: 'ATM', icon: Icons.local_atm_rounded),
    (label: 'Receipt', icon: Icons.receipt_long_rounded),
    (label: 'Invoice', icon: Icons.request_quote_rounded),
    (label: 'Loan', icon: Icons.money_rounded),
    (label: 'Invest', icon: Icons.candlestick_chart_rounded),
    (label: 'Gift', icon: Icons.card_giftcard_rounded),
    (label: 'Percent', icon: Icons.percent_rounded),
  ],
  'Food & Drink': [
    (label: 'Restaurant', icon: Icons.restaurant_rounded),
    (label: 'Coffee', icon: Icons.coffee_rounded),
    (label: 'Fastfood', icon: Icons.fastfood_rounded),
    (label: 'Pizza', icon: Icons.local_pizza_rounded),
    (label: 'Bakery', icon: Icons.bakery_dining_rounded),
    (label: 'Grocery', icon: Icons.local_grocery_store_rounded),
    (label: 'Bar', icon: Icons.local_bar_rounded),
    (label: 'Cake', icon: Icons.cake_rounded),
    (label: 'Ramen', icon: Icons.ramen_dining_rounded),
    (label: 'Ice Cream', icon: Icons.icecream_rounded),
    (label: 'Lunch', icon: Icons.lunch_dining_rounded),
    (label: 'Brunch', icon: Icons.brunch_dining_rounded),
    (label: 'Dining', icon: Icons.dining_rounded),
    (label: 'Delivery', icon: Icons.delivery_dining_rounded),
    (label: 'Kitchen', icon: Icons.kitchen_rounded),
  ],
  'Transport': [
    (label: 'Car', icon: Icons.directions_car_rounded),
    (label: 'Bus', icon: Icons.directions_bus_rounded),
    (label: 'Train', icon: Icons.directions_railway_rounded),
    (label: 'Bike', icon: Icons.directions_bike_rounded),
    (label: 'Walk', icon: Icons.directions_walk_rounded),
    (label: 'Flight', icon: Icons.flight_rounded),
    (label: 'Taxi', icon: Icons.local_taxi_rounded),
    (label: 'Subway', icon: Icons.subway_rounded),
    (label: 'Boat', icon: Icons.directions_boat_rounded),
    (label: 'Motorcycle', icon: Icons.motorcycle_rounded),
    (label: 'Fuel', icon: Icons.local_gas_station_rounded),
    (label: 'Parking', icon: Icons.local_parking_rounded),
    (label: 'EV', icon: Icons.electric_car_rounded),
    (label: 'Commute', icon: Icons.commute_rounded),
    (label: 'RV', icon: Icons.rv_hookup_rounded),
  ],
  'Shopping': [
    (label: 'Bag', icon: Icons.shopping_bag_rounded),
    (label: 'Cart', icon: Icons.shopping_cart_rounded),
    (label: 'Store', icon: Icons.store_rounded),
    (label: 'Clothes', icon: Icons.checkroom_rounded),
    (label: 'Jewel', icon: Icons.diamond_rounded),
    (label: 'Watch', icon: Icons.watch_rounded),
    (label: 'Shoes', icon: Icons.dry_cleaning_rounded),
    (label: 'Toy', icon: Icons.toys_rounded),
    (label: 'Book', icon: Icons.menu_book_rounded),
    (label: 'Devices', icon: Icons.devices_rounded),
    (label: 'Phone', icon: Icons.smartphone_rounded),
    (label: 'Headphones', icon: Icons.headphones_rounded),
    (label: 'Camera', icon: Icons.camera_alt_rounded),
    (label: 'Laptop', icon: Icons.laptop_mac_rounded),
    (label: 'Furniture', icon: Icons.chair_rounded),
  ],
  'Health': [
    (label: 'Health', icon: Icons.favorite_rounded),
    (label: 'Medical', icon: Icons.medical_services_rounded),
    (label: 'Pharmacy', icon: Icons.local_pharmacy_rounded),
    (label: 'Hospital', icon: Icons.local_hospital_rounded),
    (label: 'Fitness', icon: Icons.fitness_center_rounded),
    (label: 'Spa', icon: Icons.spa_rounded),
    (label: 'Mental', icon: Icons.self_improvement_rounded),
    (label: 'Dentist', icon: Icons.elderly_rounded),
    (label: 'Eye', icon: Icons.visibility_rounded),
    (label: 'Yoga', icon: Icons.sports_gymnastics_rounded),
    (label: 'Run', icon: Icons.directions_run_rounded),
    (label: 'Swim', icon: Icons.pool_rounded),
    (label: 'Cycle', icon: Icons.pedal_bike_rounded),
    (label: 'Vaccine', icon: Icons.vaccines_rounded),
    (label: 'Pulse', icon: Icons.monitor_heart_rounded),
  ],
  'Home': [
    (label: 'Home', icon: Icons.home_rounded),
    (label: 'Bills', icon: Icons.receipt_rounded),
    (label: 'Electric', icon: Icons.bolt_rounded),
    (label: 'Water', icon: Icons.water_drop_rounded),
    (label: 'Gas', icon: Icons.local_fire_department_rounded),
    (label: 'Internet', icon: Icons.wifi_rounded),
    (label: 'Rent', icon: Icons.real_estate_agent_rounded),
    (label: 'Repair', icon: Icons.build_rounded),
    (label: 'Clean', icon: Icons.cleaning_services_rounded),
    (label: 'Garden', icon: Icons.yard_rounded),
    (label: 'Security', icon: Icons.security_rounded),
    (label: 'Appliance', icon: Icons.microwave_rounded),
    (label: 'TV', icon: Icons.tv_rounded),
    (label: 'Sofa', icon: Icons.weekend_rounded),
    (label: 'Bed', icon: Icons.king_bed_rounded),
  ],
  'Entertainment': [
    (label: 'Movie', icon: Icons.movie_rounded),
    (label: 'Music', icon: Icons.music_note_rounded),
    (label: 'Games', icon: Icons.sports_esports_rounded),
    (label: 'Sports', icon: Icons.sports_rounded),
    (label: 'Event', icon: Icons.event_rounded),
    (label: 'Ticket', icon: Icons.confirmation_number_rounded),
    (label: 'Stream', icon: Icons.live_tv_rounded),
    (label: 'Photo', icon: Icons.photo_camera_rounded),
    (label: 'Books', icon: Icons.auto_stories_rounded),
    (label: 'Podcast', icon: Icons.podcasts_rounded),
    (label: 'Dance', icon: Icons.nightlife_rounded),
    (label: 'Bowling', icon: Icons.sports_handball_rounded),
    (label: 'Golf', icon: Icons.golf_course_rounded),
    (label: 'Travel', icon: Icons.travel_explore_rounded),
    (label: 'Park', icon: Icons.park_rounded),
  ],
  'Education': [
    (label: 'School', icon: Icons.school_rounded),
    (label: 'Study', icon: Icons.import_contacts_rounded),
    (label: 'Online', icon: Icons.computer_rounded),
    (label: 'Science', icon: Icons.science_rounded),
    (label: 'Art', icon: Icons.palette_rounded),
    (label: 'Music Ed', icon: Icons.piano_rounded),
    (label: 'Language', icon: Icons.language_rounded),
    (label: 'Certificate', icon: Icons.workspace_premium_rounded),
    (label: 'Lab', icon: Icons.biotech_rounded),
    (label: 'Library', icon: Icons.local_library_rounded),
  ],
  'Work': [
    (label: 'Work', icon: Icons.work_rounded),
    (label: 'Office', icon: Icons.business_center_rounded),
    (label: 'Freelance', icon: Icons.laptop_rounded),
    (label: 'Meeting', icon: Icons.groups_rounded),
    (label: 'Business', icon: Icons.business_rounded),
    (label: 'Print', icon: Icons.print_rounded),
    (label: 'Pen', icon: Icons.edit_rounded),
    (label: 'Chart', icon: Icons.bar_chart_rounded),
    (label: 'Calendar', icon: Icons.calendar_month_rounded),
    (label: 'Task', icon: Icons.task_alt_rounded),
  ],
  'Other': [
    (label: 'Star', icon: Icons.star_rounded),
    (label: 'Tag', icon: Icons.label_rounded),
    (label: 'Pin', icon: Icons.push_pin_rounded),
    (label: 'Phone', icon: Icons.phone_rounded),
    (label: 'Map', icon: Icons.map_rounded),
    (label: 'Pet', icon: Icons.pets_rounded),
    (label: 'Child', icon: Icons.child_care_rounded),
    (label: 'Charity', icon: Icons.volunteer_activism_rounded),
    (label: 'Insurance', icon: Icons.shield_rounded),
    (label: 'Tax', icon: Icons.account_tree_rounded),
    (label: 'Subscription', icon: Icons.subscriptions_rounded),
    (label: 'Cloud', icon: Icons.cloud_rounded),
    (label: 'More', icon: Icons.more_horiz_rounded),
    (label: 'Misc', icon: Icons.category_rounded),
    (label: 'Dollar', icon: Icons.attach_money_rounded),
  ],
};

const _colorPalette = [
  Color(0xFFE8365D),
  Color(0xFFFF6B6B),
  Color(0xFFFF8E53),
  Color(0xFFFFB300),
  Color(0xFFFFE66D),
  Color(0xFF00B87C),
  Color(0xFF00CEC9),
  Color(0xFF4ECDC4),
  Color(0xFF55EFC4),
  Color(0xFF0984E3),
  Color(0xFF6C63FF),
  Color(0xFF6C5CE7),
  Color(0xFFA29BFE),
  Color(0xFFFD79A8),
  Color(0xFFE17055),
  Color(0xFF74B9FF),
  Color(0xFF00B894),
  Color(0xFF636E72),
  Color(0xFF2D3436),
  Color(0xFFDFE6E9),
];

// ─── Screen ───────────────────────────────────────────────────────────────────
class ManageCategoriesScreen extends ConsumerWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Manage Categories',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Category',
            onPressed: () => _showCategorySheet(context, ref, null),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          const _SectionHeader('Default Categories'),
          ...categories.where((c) => !c.isCustom).map(
                (c) => _CategoryTile(
                  category: c,
                  onEdit: null,
                  onDelete: null,
                ),
              ),
          const SizedBox(height: 8),
          const _SectionHeader('Custom Categories'),
          if (categories.where((c) => c.isCustom).isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.category_outlined,
                      size: 56,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.2)),
                  const SizedBox(height: 12),
                  Text(
                    'No custom categories yet.\nTap + to create one.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            )
          else
            ...categories.where((c) => c.isCustom).map(
                  (c) => _CategoryTile(
                    category: c,
                    onEdit: () => _showCategorySheet(context, ref, c),
                    onDelete: () => _confirmDelete(context, ref, c),
                  ),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategorySheet(context, ref, null),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add Category',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showCategorySheet(
      BuildContext context, WidgetRef ref, CategoryModel? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryFormSheet(existing: existing),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, CategoryModel category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${category.name}"?',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text(
          'This will not delete existing transactions using this category.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(categoryProvider.notifier).delete(category.id);
            },
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFE8365D))),
          ),
        ],
      ),
    );
  }
}

// ─── Category Tile ────────────────────────────────────────────────────────────
class _CategoryTile extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final typeLabel = switch (category.type) {
      CategoryType.expense => 'Expense',
      CategoryType.income => 'Income',
      CategoryType.both => 'Both',
    };

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: category.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(category.icon, color: category.color, size: 22),
      ),
      title: Text(
        category.name,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        typeLabel,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
      ),
      trailing: category.isCustom
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  onPressed: onEdit,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  onPressed: onDelete,
                  color: const Color(0xFFE8365D),
                ),
              ],
            )
          : Icon(Icons.lock_outline_rounded,
              size: 16,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.25)),
    ).animate().fadeIn(duration: 250.ms);
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

// ─── Category Form Sheet ──────────────────────────────────────────────────────
class _CategoryFormSheet extends ConsumerStatefulWidget {
  final CategoryModel? existing;
  const _CategoryFormSheet({this.existing});

  @override
  ConsumerState<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<_CategoryFormSheet> {
  late TextEditingController _nameController;
  late CategoryType _type;
  late Color _selectedColor;
  late IconData _selectedIcon;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _nameController = TextEditingController(text: ex?.name ?? '');
    _type = ex?.type ?? CategoryType.expense;
    _selectedColor = ex?.color ?? _colorPalette[0];
    _selectedIcon = ex?.icon ?? Icons.category_rounded;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _colorToHex(Color c) {
    final argb = c.toARGB32();
    return '#${argb.toRadixString(16).substring(2).toUpperCase()}';
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a category name')),
      );
      return;
    }
    setState(() => _saving = true);
    final ex = widget.existing;
    final categories = ref.read(categoryProvider);
    final category = CategoryModel(
      id: ex?.id ?? const Uuid().v4(),
      name: name,
      iconCodePoint: _selectedIcon.codePoint,
      colorHex: _colorToHex(_selectedColor),
      isCustom: true,
      type: _type,
      sortOrder: ex?.sortOrder ?? categories.length,
    );
    if (ex != null) {
      await ref.read(categoryProvider.notifier).update(category);
    } else {
      await ref.read(categoryProvider.notifier).add(category);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1428) : const Color(0xFFF8FAFF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => CustomScrollView(
          controller: scrollController,
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
                  // Title
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.existing != null
                              ? 'Edit Category'
                              : 'New Category',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),

                  // Preview
                  Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: _selectedColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _selectedColor.withValues(alpha: 0.5),
                            width: 2),
                      ),
                      child:
                          Icon(_selectedIcon, color: _selectedColor, size: 32),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Name field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                        prefixIcon: Icon(Icons.label_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Type selector
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TYPE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _TypeChip(
                              label: 'Expense',
                              color: const Color(0xFFE8365D),
                              selected: _type == CategoryType.expense,
                              onTap: () =>
                                  setState(() => _type = CategoryType.expense),
                            ),
                            const SizedBox(width: 8),
                            _TypeChip(
                              label: 'Income',
                              color: const Color(0xFF00B87C),
                              selected: _type == CategoryType.income,
                              onTap: () =>
                                  setState(() => _type = CategoryType.income),
                            ),
                            const SizedBox(width: 8),
                            _TypeChip(
                              label: 'Both',
                              color: const Color(0xFFFFB300),
                              selected: _type == CategoryType.both,
                              onTap: () =>
                                  setState(() => _type = CategoryType.both),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Color picker
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COLOR',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _colorPalette.map((color) {
                            final isSelected =
                                _selectedColor.toARGB32() == color.toARGB32();
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedColor = color),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                        : Colors.transparent,
                                    width: 2.5,
                                  ),
                                   boxShadow: const [],
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check_rounded,
                                        color: Colors.white, size: 18)
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Icon picker header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ICON',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _openIconPicker,
                          icon: const Icon(Icons.grid_view_rounded, size: 16),
                          label: const Text('Browse All'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Quick icon row — flat list from first category
                  SizedBox(
                    height: 56,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: _iconCatalogue.values
                          .expand((list) => list)
                          .take(20)
                          .map((entry) {
                        final isSelected =
                            _selectedIcon.codePoint == entry.icon.codePoint;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedIcon = entry.icon),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _selectedColor.withValues(alpha: 0.2)
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? _selectedColor
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              entry.icon,
                              color: isSelected
                                  ? _selectedColor
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5),
                              size: 22,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Save button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                widget.existing != null
                                    ? 'Update Category'
                                    : 'Create Category',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openIconPicker() async {
    final picked = await showDialog<IconData>(
      context: context,
      builder: (ctx) => _IconPickerDialog(
        selectedIcon: _selectedIcon,
        accentColor: _selectedColor,
      ),
    );
    if (picked != null) setState(() => _selectedIcon = picked);
  }
}

// ─── Type chip ────────────────────────────────────────────────────────────────
class _TypeChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

// ─── Icon Picker Dialog ───────────────────────────────────────────────────────
class _IconPickerDialog extends StatefulWidget {
  final IconData selectedIcon;
  final Color accentColor;

  const _IconPickerDialog({
    required this.selectedIcon,
    required this.accentColor,
  });

  @override
  State<_IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<_IconPickerDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _iconCatalogue.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keys = _iconCatalogue.keys.toList();

    // Build filtered list across all categories when searching
    final allIcons = _iconCatalogue.values.expand((l) => l).toList();
    final filtered = _search.isEmpty
        ? <({String label, IconData icon})>[]
        : allIcons
            .where((e) => e.label.toLowerCase().contains(_search.toLowerCase()))
            .toList();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Choose Icon',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: false,
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search icons...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                ),
              ),
            ),
            const SizedBox(height: 8),

            if (_search.isNotEmpty)
              Expanded(
                  child: _IconGrid(
                icons: filtered,
                selected: widget.selectedIcon,
                accentColor: widget.accentColor,
                onPick: (icon) => Navigator.pop(context, icon),
              ))
            else ...[
              // Tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12, fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 12),
                tabs: keys.map((k) => Tab(text: k)).toList(),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: keys.map((k) {
                    return _IconGrid(
                      icons: _iconCatalogue[k]!,
                      selected: widget.selectedIcon,
                      accentColor: widget.accentColor,
                      onPick: (icon) => Navigator.pop(context, icon),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IconGrid extends StatelessWidget {
  final List<({String label, IconData icon})> icons;
  final IconData selected;
  final Color accentColor;
  final ValueChanged<IconData> onPick;

  const _IconGrid({
    required this.icons,
    required this.selected,
    required this.accentColor,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    if (icons.isEmpty) {
      return Center(
        child: Text(
          'No icons found',
          style: GoogleFonts.plusJakartaSans(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4)),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: icons.length,
      itemBuilder: (ctx, i) {
        final entry = icons[i];
        final isSelected = selected.codePoint == entry.icon.codePoint;
        return Tooltip(
          message: entry.label,
          child: GestureDetector(
            onTap: () => onPick(entry.icon),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.2)
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? accentColor : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Icon(
                entry.icon,
                size: 22,
                color: isSelected
                    ? accentColor
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
              ),
            ),
          ),
        );
      },
    );
  }
}
