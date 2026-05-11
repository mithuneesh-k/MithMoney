<div align="center">

<img src="assets/icon/app_icon.png" alt="MithMoney Logo" width="100" height="100" style="border-radius:22px"/>

# MithMoney

**Track every rupee, own your future.**

A production-grade, 100% offline personal finance tracker built with Flutter.
Beautiful glassmorphism UI · Riverpod state · Hive local database · Zero data collection.

[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0%2B-0175C2?logo=dart)](https://dart.dev)
[![CI](https://github.com/aswin-blix/mithmoney/actions/workflows/flutter_ci.yml/badge.svg)](https://github.com/aswin-blix/mithmoney/actions)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

[**Download APK**](../../releases/latest) · [**Landing Page**](https://aswin-blix.github.io/mithmoney) · [**Report Bug**](../../issues/new?template=bug_report.md) · [**Request Feature**](../../issues/new?template=feature_request.md)

</div>

---

## Features

| | Feature | Description |
|---|---|---|
| 💰 | **Transaction Tracking** | Log income, expenses, and transfers with categories, notes, and tags |
| 📊 | **Analytics** | Bar charts, pie charts, weekly/monthly/yearly breakdowns |
| 🎯 | **Budget Tracking** | Set monthly budgets per category with live progress bars |
| 📱 | **SMS Bank Reader** | Auto-reads bank transaction SMS — 100% local, never uploaded |
| 🔐 | **App Lock** | Biometric / device PIN gate on open and on background resume |
| ☁️ | **Backup & Restore** | Export full data as JSON and restore from file |
| 🌙 | **Dark / Light Mode** | Instant theme switching, follows system preference |
| 💱 | **Multi-Currency** | INR, USD, EUR, GBP, JPY, AUD, CAD, SGD, AED |
| ✨ | **Glassmorphism UI** | Frosted glass cards with spring animations throughout |
| 🚫 | **100% Offline** | Zero network calls, zero telemetry, zero cloud |

---

## Screenshots

> _Screenshots coming soon — contributions welcome!_

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x, Dart 3.x |
| State Management | `flutter_riverpod` (StateNotifierProvider) |
| Local Database | `hive` + `hive_flutter` (hand-written adapters, no build_runner) |
| Charts | `fl_chart` v0.68 |
| Animations | `flutter_animate`, `animations` |
| Typography | Google Fonts — Plus Jakarta Sans |
| Biometric Auth | `local_auth` |
| SMS Reading | `flutter_sms_inbox` |
| Notifications | `flutter_local_notifications`, `flutter_timezone` |
| Background Tasks | `workmanager` |
| File Operations | `path_provider`, `share_plus`, `file_picker` |

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.0.0
- Android SDK (for Android builds)
- A physical or virtual Android device

### Clone & Run

```bash
# 1. Clone
git clone https://github.com/aswin-blix/mithmoney.git
cd mithmoney

# 2. Install dependencies
flutter pub get

# 3. Run on connected device
flutter run
```

### Build Release APK

```bash
flutter build apk --release --no-tree-shake-icons
# Output: build/app/outputs/flutter-apk/app-release.apk
```

> **Note:** The `--no-tree-shake-icons` flag is required because category icons are stored as integer codepoints in Hive and resolved at runtime via `IconData(codePoint, fontFamily: 'MaterialIcons')`.

### Install on Device (ADB)

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## Project Structure

```
lib/
├── core/
│   ├── constants/      # App-wide constants, currencies, default categories
│   ├── theme/          # AppTheme, AppColors, gradients
│   └── utils/          # SmsParser, formatters
├── data/
│   ├── models/         # Hive models + hand-written .g.dart adapters
│   └── repositories/   # Thin Hive box wrappers
├── features/           # One folder per screen/feature
│   ├── analytics/
│   ├── app_lock/
│   ├── backup/
│   ├── budget/
│   ├── dashboard/
│   ├── onboarding/
│   ├── settings/
│   ├── sms/
│   ├── splash/
│   ├── tips/
│   └── transactions/
└── shared/
    ├── providers/      # All Riverpod providers (settings, transactions, categories, SMS)
    └── widgets/        # Reusable widgets (GlassCard, TransactionTile, etc.)
```

---

## Architecture Notes

- **Hive adapters are hand-written** — the `.g.dart` files are checked in. Do not run `build_runner`.
- **Settings state** — `AppSettings` is cloned via `fromJson`/`toJson` on every update so Riverpod detects the change. Mutation-in-place won't work.
- **Tab indices** in `HomeShell`: `0`=Dashboard, `1`=Transactions, `2`=FAB (opens sheet), `3`=Analytics, `4`=Settings.
- **fl_chart v0.68** — does not accept `duration`/`curve` at the chart widget level.
- **Notifications** — `flutter_timezone` is used to resolve the device's local timezone at runtime via `FlutterTimezone.getLocalTimezone()`. This must be called during `NotificationService.init()` before any `zonedSchedule` call, otherwise notifications fire at UTC time on many devices.
- **Week analytics** — uses a rolling last-7-days window (`today − 6` to `today`), not a Mon–Sun calendar week, so data is always visible regardless of the day of the week.

---

## Permissions (Android)

| Permission | Why |
|---|---|
| `READ_SMS` | SMS Bank Reader — reads bank transaction messages locally |
| `USE_BIOMETRIC` / `USE_FINGERPRINT` | App Lock |
| `POST_NOTIFICATIONS` | Daily reminder notifications |
| `CAMERA` / `READ_MEDIA_IMAGES` | Profile avatar picker |
| `RECEIVE_BOOT_COMPLETED` | Reschedule notifications after reboot |
| `USE_FULL_SCREEN_INTENT` | Show heads-up notification display |

All permissions are optional. Core tracking works without any of them.

---

## Contributing

Contributions are very welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

1. Fork the repo
2. Create a branch: `git checkout -b feat/your-feature`
3. Commit your changes
4. Open a Pull Request

---

## Roadmap

- [ ] Recurring / scheduled transactions
- [x] CSV / XLSX Import & Export
- [x] Home Screen Widgets (Live Balance & Quick Add)
- [ ] Natural Language Processing (NLP) for quick expense entry (e.g., "20rs for auto")
- [ ] Receipt OCR (AI Scanner) for automated bill logging
- [ ] Debt & Loan Manager (track who owes you and who you owe)
- [ ] PDF Financial Reports (branded monthly summaries)
- [ ] Savings Goals with visual progress tracking
- [ ] Split-the-Bill integration
- [ ] Voice-to-Expense input
- [ ] iOS support
- [ ] UPI deep link detection
- [ ] Multi-account support

---

## License

Distributed under the MIT License. See [LICENSE](LICENSE) for details.

---

<div align="center">
Made with ❤️ by <a href="https://github.com/aswin-blix">Aswin Blix</a> &amp; <a href="https://claude.ai/code">Claude Code</a> &amp; Antigravity
</div>
