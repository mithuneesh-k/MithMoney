import 'package:flutter/material.dart';

// ─── Hive Box Names ───────────────────────────────────────────────────────────
const String kTransactionsBox = 'transactions';
const String kCategoriesBox = 'categories';
const String kSmsMessagesBox = 'sms_messages';
const String kSettingsBox = 'settings';
const String kTipsFavoritesBox = 'tips_favorites';
const String kAccountsBox = 'accounts';

// ─── Hive Type IDs ────────────────────────────────────────────────────────────
const int kTransactionTypeId = 0;
const int kCategoryTypeId = 1;
const int kBankSmsMessageTypeId = 2;
const int kAppSettingsTypeId = 3;
const int kTransactionTypeEnumId = 4;
const int kSmsStatusEnumId = 5;
const int kCategoryTypeEnumId = 6;
const int kAccountTypeId = 7;
const int kAccountTypeEnumId = 8;

// ─── Animation Constants ──────────────────────────────────────────────────────
const SpringDescription kSpringFast =
    SpringDescription(mass: 1, stiffness: 400, damping: 28);
const SpringDescription kSpringBouncy =
    SpringDescription(mass: 1, stiffness: 300, damping: 18);
const SpringDescription kSpringSmooth =
    SpringDescription(mass: 1, stiffness: 200, damping: 24);

const Duration kDurationFast = Duration(milliseconds: 220);
const Duration kDurationMed = Duration(milliseconds: 380);
const Duration kDurationSlow = Duration(milliseconds: 560);

const Curve kCurveSnap = Curves.easeOutExpo;
const Curve kCurveSoft = Curves.easeInOutCubic;
const Curve kCurveBounce = Curves.elasticOut;

// ─── App Info ─────────────────────────────────────────────────────────────────
const String kAppName = 'MithMoney';
const String kAppVersion = '1.0.0';
const String kBackupFolder = 'MithMoneyBackups';

// ─── Supported Currencies ─────────────────────────────────────────────────────
const List<Map<String, String>> kCurrencies = [
  {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
  {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
  {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
  {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
  {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
  {'code': 'AUD', 'symbol': 'A\$', 'name': 'Australian Dollar'},
  {'code': 'CAD', 'symbol': 'C\$', 'name': 'Canadian Dollar'},
  {'code': 'SGD', 'symbol': 'S\$', 'name': 'Singapore Dollar'},
  {'code': 'AED', 'symbol': 'د.إ', 'name': 'UAE Dirham'},
];

// ─── Known Bank SMS Senders ───────────────────────────────────────────────────
const List<String> kDefaultBankSenders = [
  'HDFCBK',
  'ICICIB',
  'SBIINB',
  'AXISBK',
  'KOTAKB',
  'INDUSB',
  'YESBNK',
  'PNBSMS',
  'BOIIND',
  'UNIONB',
  'PAYTM',
  'PHONEPE',
  'GPAY',
  'AMAZONP',
  'CRED',
];

// ─── Notification IDs ─────────────────────────────────────────────────────────
const int kDailyReminderNotifId = 1;
const int kWeeklySummaryNotifId = 2;
const int kBudgetAlertNotifId = 3;
