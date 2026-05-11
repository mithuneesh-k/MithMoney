import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/app_card.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  final _nameController = TextEditingController();
  double _budgetValue = 20000;
  String _currency = 'INR';
  String _currencySymbol = '₹';
  bool _notificationsEnabled = true;
  bool _smsEnabled = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutExpo,
      );
    } else {
      _finish();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutExpo,
      );
    }
  }

  Future<void> _finish() async {
    final notifier = ref.read(settingsProvider.notifier);
    await notifier.setUserName(_nameController.text.trim());
    await notifier.setCurrency(_currency, _currencySymbol);
    await notifier.setMonthlyBudget(_budgetValue);
    await notifier.setNotificationSettings(
      enabled: _notificationsEnabled,
      hour: 21,
      minute: 0,
    );
    await notifier.setSmsReaderEnabled(_smsEnabled);
    await notifier.completeOnboarding();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(),
        child: SafeArea(
          child: Column(
            children: [
              // Navigation row: back (when applicable) + skip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentPage > 0)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: Theme.of(context).colorScheme.primary,
                        onPressed: _previousPage,
                      )
                    else
                      const SizedBox(width: 48),
                    TextButton(
                      onPressed: _finish,
                      child: Text(
                        'Skip',
                        style: GoogleFonts.plusJakartaSans(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Page content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    _WelcomePage(nameController: _nameController),
                    _BudgetPage(
                      budget: _budgetValue,
                      currency: _currency,
                      currencySymbol: _currencySymbol,
                      onBudgetChanged: (v) => setState(() => _budgetValue = v),
                      onCurrencyChanged: (code, symbol) {
                        setState(() {
                          _currency = code;
                          _currencySymbol = symbol;
                        });
                      },
                    ),
                    _PermissionsPage(
                      notificationsEnabled: _notificationsEnabled,
                      smsEnabled: _smsEnabled,
                      onNotifChanged: (v) =>
                          setState(() => _notificationsEnabled = v),
                      onSmsChanged: (v) => setState(() => _smsEnabled = v),
                    ),
                  ],
                ),
              ),
              // Progress dots + next button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _currentPage ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _currentPage
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        child:
                            Text(_currentPage < 2 ? 'Continue' : 'Get Started'),
                      ),
                    ),
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

// ─── Page 1: Welcome ──────────────────────────────────────────────────────────
class _WelcomePage extends StatelessWidget {
  final TextEditingController nameController;
  const _WelcomePage({required this.nameController});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/icon/app_icon.png',
                fit: BoxFit.cover,
              ),
            ),
          ).animate().scale(
              begin: const Offset(0.4, 0.4),
              duration: 600.ms,
              curve: Curves.elasticOut),
          const SizedBox(height: 32),
          Text(
            'Welcome to MithMoney',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),
          const SizedBox(height: 12),
          Text(
            'Take control of your finances with beautiful, private expense tracking.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 40),
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "What's your name?",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: 'Enter your name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ).animate(delay: 400.ms).fadeIn(duration: 400.ms).slideY(begin: 0.3),
        ],
      ),
    );
  }
}

// ─── Page 2: Budget & Currency ────────────────────────────────────────────────
class _BudgetPage extends StatelessWidget {
  final double budget;
  final String currency;
  final String currencySymbol;
  final ValueChanged<double> onBudgetChanged;
  final void Function(String code, String symbol) onCurrencyChanged;

  const _BudgetPage({
    required this.budget,
    required this.currency,
    required this.currencySymbol,
    required this.onBudgetChanged,
    required this.onCurrencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_balance_wallet_rounded,
              size: 64, color: Color(0xFF6C63FF)),
          const SizedBox(height: 24),
          Text(
            'Set Your Budget',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 8),
          Text(
            'Set a monthly spending goal and preferred currency.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 32),
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Currency selector
                Text(
                  'Currency',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: currency,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.currency_exchange_rounded),
                  ),
                  items: kCurrencies
                      .map((c) => DropdownMenuItem(
                            value: c['code'],
                            child: Text(
                              '${c['symbol']} ${c['name']}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 14),
                            ),
                          ))
                      .toList(),
                  onChanged: (code) {
                    final cur = kCurrencies.firstWhere((c) => c['code'] == code,
                        orElse: () => kCurrencies.first);
                    onCurrencyChanged(cur['code']!, cur['symbol']!);
                  },
                ),
                const SizedBox(height: 20),
                // Budget slider
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
                    Text(
                      '$currencySymbol${budget.toStringAsFixed(0)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: budget,
                  min: 1000,
                  max: 500000,
                  divisions: 499,
                  onChanged: onBudgetChanged,
                ),
              ],
            ),
          ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.3),
        ],
      ),
    );
  }
}

// ─── Page 3: Permissions ──────────────────────────────────────────────────────
class _PermissionsPage extends StatelessWidget {
  final bool notificationsEnabled;
  final bool smsEnabled;
  final ValueChanged<bool> onNotifChanged;
  final ValueChanged<bool> onSmsChanged;

  const _PermissionsPage({
    required this.notificationsEnabled,
    required this.smsEnabled,
    required this.onNotifChanged,
    required this.onSmsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_active_rounded,
              size: 64, color: Color(0xFF00D4FF)),
          const SizedBox(height: 24),
          Text(
            'Stay on Track',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 8),
          Text(
            'Enable reminders and optionally let MithMoney scan your bank SMS — all stays on your device.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 32),
          AppCard(
            padding: const EdgeInsets.all(4),
            child: Column(
              children: [
                _PermissionTile(
                  icon: Icons.notifications_rounded,
                  iconColor: const Color(0xFF6C63FF),
                  title: 'Daily Reminders',
                  subtitle: 'Get nudged to log expenses at 9 PM',
                  value: notificationsEnabled,
                  onChanged: onNotifChanged,
                ),
                const Divider(height: 1),
                _PermissionTile(
                  icon: Icons.sms_rounded,
                  iconColor: const Color(0xFF00B894),
                  title: 'Bank SMS Reader',
                  subtitle:
                      'Auto-detect transactions from bank messages. Stays 100% local.',
                  value: smsEnabled,
                  onChanged: onSmsChanged,
                ),
              ],
            ),
          ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.3),
        ],
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PermissionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
