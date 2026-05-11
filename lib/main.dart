import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';
import 'core/utils/app_logger.dart';
import 'data/models/transaction_model.dart';
import 'data/models/category_model.dart';
import 'data/models/bank_sms_message.dart';
import 'data/models/app_settings.dart';
import 'data/models/account_model.dart';
import 'core/constants/app_constants.dart';
import 'features/splash/splash_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/dashboard/home_shell.dart';
import 'features/backup/backup_screen.dart';
import 'features/app_lock/app_lock_screen.dart';
import 'features/sms/sms_inbox_screen.dart';
import 'shared/providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters
  if (!Hive.isAdapterRegistered(kTransactionTypeEnumId)) {
    Hive.registerAdapter(TransactionTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(kTransactionTypeId)) {
    Hive.registerAdapter(TransactionModelAdapter());
  }
  if (!Hive.isAdapterRegistered(kCategoryTypeEnumId)) {
    Hive.registerAdapter(CategoryTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(kCategoryTypeId)) {
    Hive.registerAdapter(CategoryModelAdapter());
  }
  if (!Hive.isAdapterRegistered(kSmsStatusEnumId)) {
    Hive.registerAdapter(SmsStatusAdapter());
  }
  if (!Hive.isAdapterRegistered(kBankSmsMessageTypeId)) {
    Hive.registerAdapter(BankSmsMessageAdapter());
  }
  if (!Hive.isAdapterRegistered(kAppSettingsTypeId)) {
    Hive.registerAdapter(AppSettingsAdapter());
  }
  if (!Hive.isAdapterRegistered(kAccountTypeEnumId)) {
    Hive.registerAdapter(AccountTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(kAccountTypeId)) {
    Hive.registerAdapter(AccountModelAdapter());
  }

  // Open boxes
  await Future.wait([
    Hive.openBox<TransactionModel>(kTransactionsBox),
    Hive.openBox<CategoryModel>(kCategoriesBox),
    Hive.openBox<BankSmsMessage>(kSmsMessagesBox),
    Hive.openBox<AppSettings>(kSettingsBox),
    Hive.openBox<bool>(kTipsFavoritesBox),
    Hive.openBox<AccountModel>(kAccountsBox),
  ]);

  // Seed default categories if box is empty
  final catBox = Hive.box<CategoryModel>(kCategoriesBox);
  if (catBox.isEmpty) {
    for (final cat in defaultCategories) {
      await catBox.put(cat.id, cat);
    }
  }

  // Seed default account if box is empty
  final accBox = Hive.box<AccountModel>(kAccountsBox);
  if (accBox.isEmpty) {
    final defaultAccount = AccountModel(
      id: 'default_cash',
      name: 'Cash',
      type: AccountType.cash,
      balance: 0.0,
      colorValue: Colors.blue.toARGB32(),
      iconCode: Icons.payments_outlined.codePoint,
      createdAt: DateTime.now(),
    );
    await accBox.put(defaultAccount.id, defaultAccount);
  }

  // Initialize notification service
  await NotificationService.instance.init();

  // Reschedule daily reminder if it was previously enabled
  final settingsBox = Hive.box<AppSettings>(kSettingsBox);
  final savedSettings = settingsBox.get('app_settings');
  if (savedSettings != null && savedSettings.notificationEnabled) {
    AppLogger.i('main',
        'Rescheduling daily reminder at ${savedSettings.notificationHour}:${savedSettings.notificationMinute}');
    await NotificationService.instance.scheduleDailyReminder(
      hour: savedSettings.notificationHour,
      minute: savedSettings.notificationMinute,
    );
  }

  runApp(const ProviderScope(child: MithMoneyApp()));
}

class MithMoneyApp extends ConsumerWidget {
  const MithMoneyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.resolvedThemeMode,
      initialRoute: '/',
      routes: {
        '/': (ctx) => const SplashScreen(),
        '/onboarding': (ctx) => const OnboardingScreen(),
        '/home': (ctx) => const HomeShell(),
        '/backup': (ctx) => const BackupScreen(),
        '/lock': (ctx) => const AppLockScreen(),
        '/sms': (ctx) => const SmsInboxScreen(),
      },
    );
  }
}
