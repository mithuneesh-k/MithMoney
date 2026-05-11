import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../dashboard/dashboard_screen.dart';
import '../transactions/transactions_screen.dart';
import '../transactions/add_transaction_screen.dart';
import '../analytics/analytics_screen.dart';
import '../settings/settings_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with WidgetsBindingObserver {
  int _currentTab = 0;
  AppLifecycleState? _lastLifecycle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkWidgetLaunch();
  }

  void _checkWidgetLaunch() {
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetLaunch);
    HomeWidget.widgetClicked.listen(_handleWidgetLaunch);
  }

  void _handleWidgetLaunch(Uri? uri) {
    if (uri?.host == 'add_expense') {
      _openAddTransaction();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-lock when app resumes from background if app lock is enabled
    if (state == AppLifecycleState.resumed &&
        _lastLifecycle == AppLifecycleState.paused) {
      final settings = ref.read(settingsProvider);
      if (settings.appLockEnabled && mounted) {
        Navigator.of(context).pushReplacementNamed('/lock');
      }
    }
    _lastLifecycle = state;
  }

  // Map: tab index accounting for FAB in center (index 2)
  // Actual screens: 0=Home, 1=Transactions, 3=Analytics, 4=Settings
  // FAB at index 2 opens Add Transaction sheet

  Widget _buildScreen() {
    switch (_currentTab) {
      case 0:
        return DashboardScreen(
          onAddTransaction: _openAddTransaction,
          onViewAllTransactions: () => setState(() => _currentTab = 1),
        );
      case 1:
        return TransactionsScreen(onAddTransaction: _openAddTransaction);
      case 3:
        return const AnalyticsScreen();
      case 4:
        return const SettingsScreen();
      default:
        return DashboardScreen(
          onAddTransaction: _openAddTransaction,
          onViewAllTransactions: () => setState(() => _currentTab = 1),
        );
    }
  }

  void _onTabTap(int index) {
    if (index == 2) {
      _openAddTransaction();
      return;
    }
    setState(() => _currentTab = index);
  }

  void _openAddTransaction() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => const AddTransactionScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey(_currentTab),
            child: _buildScreen(),
          ),
        ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentTab,
        onTap: _onTabTap,
      ),
    );
  }
}
