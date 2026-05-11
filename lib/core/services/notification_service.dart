import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── Initialise ──────────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized || kIsWeb) return;
    try {
      tz_data.initializeTimeZones();
      // Resolve the device's local timezone using the UTC offset.
      // Etc/GMT names use inverted sign convention (Etc/GMT-5 = UTC+5).
      try {
        final offset = DateTime.now().timeZoneOffset;
        if (offset.inMinutes == 330) {
          // India is UTC+5:30, which cannot be represented by whole-hour Etc/GMT offsets
          tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
        } else {
          final sign = offset.isNegative ? '+' : '-';
          final hours = offset.inHours.abs();
          tz.setLocalLocation(tz.getLocation('Etc/GMT$sign$hours'));
        }
      } catch (_) {
        // Falls back to UTC
      }

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestSoundPermission: false,
        requestBadgePermission: false,
        requestAlertPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (details) {
          AppLogger.i(
              'NotificationService', 'Notification tapped: ${details.payload}');
        },
      );

      _initialized = true;
      AppLogger.i('NotificationService', 'Initialized');
    } catch (e, stack) {
      AppLogger.e('NotificationService', 'Failed to initialize', e, stack);
    }
  }

  // ── Request POST_NOTIFICATIONS permission (Android 13+) ────────────────────
  Future<bool> requestPermission() async {
    if (kIsWeb) return true;
    try {
      final status = await Permission.notification.request();

      // Request iOS specific permissions explicitly
      final iosImplementation = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      if (status.isGranted) {
        // Request Alarms & Reminders permission on Android 14+
        final alarmStatus = await Permission.scheduleExactAlarm.status;
        if (!alarmStatus.isGranted) {
          await Permission.scheduleExactAlarm.request();
        }
      }
      AppLogger.i('NotificationService', 'Notification permission: $status');
      return status.isGranted;
    } catch (e, stack) {
      AppLogger.e('NotificationService', 'Permission request failed', e, stack);
      return false;
    }
  }

  Future<bool> hasPermission() async {
    if (kIsWeb) return true;
    return Permission.notification.isGranted;
  }

  // ── Schedule daily reminder ─────────────────────────────────────────────────
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await init();

    // Cancel existing before rescheduling
    await _plugin.cancel(id: kDailyReminderNotifId);

    // Request permission if not granted
    final granted = await hasPermission();
    if (!granted) {
      final result = await requestPermission();
      if (!result) {
        AppLogger.w('NotificationService',
            'Notification permission denied — reminder not scheduled');
        return;
      }
    }

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'mithmoney_daily_reminder',
      'Daily Reminder',
      channelDescription: 'Reminds you to log your daily expenses',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _plugin.zonedSchedule(
        id: kDailyReminderNotifId,
        title: '💰 Time to log your expenses!',
        body: 'Keep your finances on track — it only takes a minute.',
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // repeats daily
      );

      AppLogger.i(
        'NotificationService',
        'Daily reminder scheduled at $hour:${minute.toString().padLeft(2, '0')} (next: $scheduled)',
      );
    } catch (e) {
      AppLogger.w('NotificationService',
          'Exact alarm failed (likely blocked by Android 14). Falling back to inexact alarm.');

      try {
        await _plugin.zonedSchedule(
          id: kDailyReminderNotifId,
          title: '💰 Time to log your expenses!',
          body: 'Keep your finances on track — it only takes a minute.',
          scheduledDate: scheduled,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        AppLogger.i('NotificationService',
            'Fallback inexact alarm scheduled successfully.');
      } catch (fallbackErr) {
        AppLogger.e(
            'NotificationService', 'Even fallback alarm failed', fallbackErr);
      }
    }
  }

  // ── Cancel daily reminder ───────────────────────────────────────────────────
  Future<void> cancelDailyReminder() async {
    try {
      await _plugin.cancel(id: kDailyReminderNotifId);
      AppLogger.i('NotificationService', 'Daily reminder cancelled');
    } catch (e, stack) {
      AppLogger.e('NotificationService', 'Failed to cancel reminder', e, stack);
    }
  }

  // ── Test Immediate Notification ───────────────────────────────────────────
  Future<void> showTestNotification() async {
    if (!_initialized) await init();
    try {
      const androidDetails = AndroidNotificationDetails(
        'mithmoney_test',
        'Test Alerts',
        channelDescription: 'Testing channel for immediate verification',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      await _plugin.show(
        id: kDailyReminderNotifId + 1,
        title: '🚀 Immediate Test Alert',
        body:
            'If you can see this, your phone is allowing MithMoney notifications natively!',
        notificationDetails: details,
      );
      AppLogger.i('NotificationService', 'Immediate test notification fired');
    } catch (e, stack) {
      AppLogger.e('NotificationService', 'Failed to send test notif', e, stack);
    }
  }

  // ── Cancel all ──────────────────────────────────────────────────────────────
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
      AppLogger.i('NotificationService', 'All notifications cancelled');
    } catch (e, stack) {
      AppLogger.e('NotificationService', 'Failed to cancel all notifications',
          e, stack);
    }
  }
}
