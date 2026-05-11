import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/app_logger.dart';
import '../../shared/providers/app_providers.dart';
import '../categories/manage_categories_screen.dart';
import 'manage_accounts_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(
                  'Settings',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms),
            ),

            // Profile section
            SliverToBoxAdapter(
              child: _SectionCard(
                margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                children: [
                  ListTile(
                    leading: GestureDetector(
                      onTap: _pickAvatar,
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.15),
                        child: settings.avatarPath != null
                            ? null
                            : Icon(Icons.person_rounded,
                                color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    title: Text(
                      settings.userName.isNotEmpty
                          ? settings.userName
                          : 'Set your name',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Tap to edit profile',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _editName(context),
                  ),
                ],
              ).animate(delay: 60.ms).fadeIn(duration: 350.ms),
            ),

            // Preferences
            SliverToBoxAdapter(
              child: _SettingsGroup(
                title: 'Preferences',
                margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                children: [
                  _SettingsTile(
                    icon: Icons.palette_rounded,
                    iconColor: const Color(0xFF6C63FF),
                    title: 'Theme',
                    subtitle: ['System', 'Light', 'Dark'][settings.themeMode],
                    onTap: () => _pickTheme(context, settings.themeMode),
                  ),
                  _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.currency_exchange_rounded,
                    iconColor: const Color(0xFF00B87C),
                    title: 'Currency',
                    subtitle: '${settings.currencySymbol} ${settings.currency}',
                    onTap: () => _pickCurrency(context),
                  ),
                  _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.category_rounded,
                    iconColor: const Color(0xFFFF8E53),
                    title: 'Categories',
                    subtitle: 'Add, edit or remove categories',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ManageCategoriesScreen(),
                      ),
                    ),
                  ),
                  _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: const Color(0xFF0061A4),
                    title: 'Accounts',
                    subtitle: 'Manage Bank, Wallet, Cash, Savings',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ManageAccountsScreen(),
                      ),
                    ),
                  ),
                ],
              ).animate(delay: 100.ms).fadeIn(duration: 350.ms),
            ),

            // Notifications
            SliverToBoxAdapter(
              child: _SettingsGroup(
                title: 'Notifications',
                margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                children: [
                  _SettingsSwitchTile(
                    icon: Icons.notifications_rounded,
                    iconColor: const Color(0xFF0984E3),
                    title: 'Daily Reminder',
                    subtitle: 'Get reminded to log expenses',
                    value: settings.notificationEnabled,
                    onChanged: (v) => _toggleNotification(context, v),
                  ),
                  if (settings.notificationEnabled) ...[
                    _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.access_time_rounded,
                      iconColor: const Color(0xFF0984E3),
                      title: 'Reminder Time',
                      subtitle:
                          '${settings.notificationHour.toString().padLeft(2, '0')}:${settings.notificationMinute.toString().padLeft(2, '0')}',
                      onTap: () => _pickTime(context, settings.notificationHour,
                          settings.notificationMinute),
                    ),
                    _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.rocket_launch_rounded,
                      iconColor: const Color(0xFFE84393),
                      title: 'Test Live Alert',
                      subtitle: 'Verify if OxygenOS is blocking alerts',
                      onTap: () async {
                        await NotificationService.instance
                            .showTestNotification();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Test sent! If it fails, check App Info permissions.')),
                          );
                        }
                      },
                    ),
                  ],
                ],
              ).animate(delay: 140.ms).fadeIn(duration: 350.ms),
            ),

            // SMS Reader
            SliverToBoxAdapter(
              child: _SettingsGroup(
                title: 'SMS Bank Reader',
                margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                children: [
                  _SettingsSwitchTile(
                    icon: Icons.sms_rounded,
                    iconColor: const Color(0xFF00CEC9),
                    title: 'SMS Reader',
                    subtitle: '100% local — never uploaded',
                    value: settings.smsReaderEnabled,
                    onChanged: (v) => _toggleSmsReader(context, v),
                  ),
                  if (settings.smsReaderEnabled) ...[
                    _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.inbox_rounded,
                      iconColor: const Color(0xFF00CEC9),
                      title: 'SMS Inbox',
                      subtitle: 'View & add bank transactions',
                      onTap: () => Navigator.of(context).pushNamed('/sms'),
                    ),
                  ],
                ],
              ).animate(delay: 160.ms).fadeIn(duration: 350.ms),
            ),

            // Backup
            SliverToBoxAdapter(
              child: _SettingsGroup(
                title: 'Backup & Restore',
                margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                children: [
                  _SettingsSwitchTile(
                    icon: Icons.backup_rounded,
                    iconColor: const Color(0xFF6C63FF),
                    title: 'Auto Backup',
                    subtitle: settings.lastBackupAt != null
                        ? 'Last: ${settings.lastBackupAt!.day}/${settings.lastBackupAt!.month}/${settings.lastBackupAt!.year}'
                        : 'Never backed up',
                    value: settings.autoBackupEnabled,
                    onChanged: (v) => notifier.setAutoBackup(
                      enabled: v,
                      hour: settings.autoBackupHour,
                      minute: settings.autoBackupMinute,
                      retentionDays: settings.backupRetentionDays,
                    ),
                  ),
                  _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.download_rounded,
                    iconColor: const Color(0xFF6C63FF),
                    title: 'Backup & Restore',
                    subtitle: 'Manage backups',
                    onTap: () => Navigator.of(context).pushNamed('/backup'),
                  ),
                ],
              ).animate(delay: 180.ms).fadeIn(duration: 350.ms),
            ),

            // Security
            SliverToBoxAdapter(
              child: _SettingsGroup(
                title: 'Security',
                margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                children: [
                  _SettingsSwitchTile(
                    icon: Icons.fingerprint_rounded,
                    iconColor: const Color(0xFFE8365D),
                    title: 'App Lock',
                    subtitle: 'Biometric / device PIN',
                    value: settings.appLockEnabled,
                    onChanged: (v) => _toggleAppLock(context, v),
                  ),
                ],
              ).animate(delay: 200.ms).fadeIn(duration: 350.ms),
            ),

            // Danger zone
            SliverToBoxAdapter(
              child: _SettingsGroup(
                title: 'Data',
                margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                children: [
                  _SettingsTile(
                    icon: Icons.delete_forever_rounded,
                    iconColor: const Color(0xFFE8365D),
                    title: 'Clear All Data',
                    subtitle: 'Cannot be undone',
                    titleColor: const Color(0xFFE8365D),
                    onTap: () => _confirmClearData(context),
                  ),
                ],
              ).animate(delay: 220.ms).fadeIn(duration: 350.ms),
            ),

            // App info
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        kAppName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4),
                        ),
                      ),
                      Text(
                        'Version $kAppVersion',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '100% offline • No data collected',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.25),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate(delay: 260.ms).fadeIn(duration: 350.ms),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleSmsReader(BuildContext context, bool enable) async {
    if (enable) {
      final service = ref.read(smsServiceProvider);
      final granted = await service.requestPermission();
      if (!granted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'SMS permission denied. Please grant it in app settings.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      await ref.read(settingsProvider.notifier).setSmsReaderEnabled(true);
      // Auto-sync on first enable
      final settings = ref.read(settingsProvider);
      final count = await service.syncSms(settings.knownSenderIds);
      ref.read(smsProvider.notifier).refresh();
      if (context.mounted && count > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found $count bank transactions from SMS'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      await ref.read(settingsProvider.notifier).setSmsReaderEnabled(false);
    }
  }

  Future<void> _toggleAppLock(BuildContext context, bool enable) async {
    if (enable) {
      final auth = LocalAuthentication();
      final isSupported = await auth.isDeviceSupported();
      if (!isSupported) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Biometric authentication not supported on this device.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      // Verify once before enabling
      final authenticated = await auth.authenticate(
        localizedReason: 'Confirm your identity to enable App Lock',
      );
      if (authenticated) {
        await ref
            .read(settingsProvider.notifier)
            .setAppLock(enabled: true, type: 'biometric');
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication failed. App Lock not enabled.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      await ref
          .read(settingsProvider.notifier)
          .setAppLock(enabled: false, type: 'biometric');
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      ref.read(settingsProvider.notifier).setAvatarPath(img.path);
    }
  }

  Future<void> _editName(BuildContext context) async {
    final ctrl =
        TextEditingController(text: ref.read(settingsProvider).userName);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Your Name',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).setUserName(ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTheme(BuildContext context, int current) async {
    final options = ['System', 'Light', 'Dark'];
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Theme',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        children: options
            .asMap()
            .entries
            .map((e) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, e.key),
                  child: Row(
                    children: [
                      if (e.key == current)
                        Icon(Icons.check_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 18),
                      const SizedBox(width: 8),
                      Text(e.value),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
    if (result != null) {
      ref.read(settingsProvider.notifier).setThemeMode(result);
    }
  }

  Future<void> _pickCurrency(BuildContext context) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Currency',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        children: kCurrencies
            .map((c) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, c),
                  child: Text('${c['symbol']} ${c['name']}'),
                ))
            .toList(),
      ),
    );
    if (result != null) {
      ref
          .read(settingsProvider.notifier)
          .setCurrency(result['code']!, result['symbol']!);
    }
  }

  Future<void> _toggleNotification(BuildContext context, bool enable) async {
    final settings = ref.read(settingsProvider);
    if (enable) {
      final granted = await NotificationService.instance.requestPermission();
      if (!granted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Notification permission denied. Please enable it in app settings.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      await ref.read(settingsProvider.notifier).setNotificationSettings(
            enabled: true,
            hour: settings.notificationHour,
            minute: settings.notificationMinute,
          );
      await NotificationService.instance.scheduleDailyReminder(
        hour: settings.notificationHour,
        minute: settings.notificationMinute,
      );
      AppLogger.i('Settings',
          'Daily reminder enabled at ${settings.notificationHour}:${settings.notificationMinute}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reminder set for ${settings.notificationHour.toString().padLeft(2, '0')}:${settings.notificationMinute.toString().padLeft(2, '0')} daily',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      await ref.read(settingsProvider.notifier).setNotificationSettings(
            enabled: false,
            hour: settings.notificationHour,
            minute: settings.notificationMinute,
          );
      await NotificationService.instance.cancelDailyReminder();
      AppLogger.i('Settings', 'Daily reminder disabled');
    }
  }

  Future<void> _pickTime(BuildContext context, int hour, int minute) async {
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );
    if (result != null) {
      final settings = ref.read(settingsProvider);
      await ref.read(settingsProvider.notifier).setNotificationSettings(
            enabled: settings.notificationEnabled,
            hour: result.hour,
            minute: result.minute,
          );
      // Reschedule with the new time if enabled
      if (settings.notificationEnabled) {
        await NotificationService.instance.scheduleDailyReminder(
          hour: result.hour,
          minute: result.minute,
        );
        AppLogger.i('Settings',
            'Reminder time updated to ${result.hour}:${result.minute}');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Reminder updated to ${result.hour.toString().padLeft(2, '0')}:${result.minute.toString().padLeft(2, '0')} daily',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmClearData(BuildContext context) async {
    final confirm1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear All Data?',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: const Text(
            'This will permanently delete all transactions, categories, and settings.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8365D)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm1 != true) return;
    if (!context.mounted) return;

    final confirm2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Are you sure?',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: const Text('This action CANNOT be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8365D)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, delete everything'),
          ),
        ],
      ),
    );

    if (confirm2 != true) return;

    await ref.read(transactionRepoProvider).deleteAll();
    await ref.read(categoryRepoProvider).deleteAll();
    await ref.read(categoryRepoProvider).seedDefaults();
    await ref.read(settingsRepoProvider).reset();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data cleared')),
      );
    }
  }
}

// ─── Reusable Settings Widgets ────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets margin;

  const _SectionCard({required this.children, required this.margin});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.5),
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final EdgeInsets margin;

  const _SettingsGroup({
    required this.title,
    required this.children,
    required this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: margin.add(const EdgeInsets.only(bottom: 8)),
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        _SectionCard(
          margin: EdgeInsets.only(
            left: margin.left,
            right: margin.right,
          ),
          children: children,
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: titleColor ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            )
          : null,
      trailing: onTap != null
          ? Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            )
          : null,
      onTap: onTap,
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            )
          : null,
      value: value,
      onChanged: onChanged,
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 64,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
    );
  }
}
