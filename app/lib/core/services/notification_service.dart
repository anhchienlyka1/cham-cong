import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../config/constants/app_constants.dart';

/// Khởi tạo & gửi local notification cho chấm công.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _androidDetails = AndroidNotificationDetails(
    'attendance_channel',
    'Chấm Công',
    channelDescription: 'Nhắc nhở chấm công',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
  );

  static const _notifDetails = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  /// Gọi một lần trong main() trước runApp().
  static Future<void> init() async {
    tz.initializeTimeZones();
    final localTz = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTz.identifier));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
  }

  /// Yêu cầu quyền trên iOS (Android 13+ xử lý qua manifest).
  static Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Hiện notification ngay lập tức (gọi từ background task).
  static Future<void> showImmediate({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(id, title, body, _notifDetails);
  }

  /// Lên lịch check-in lúc 8:25 sáng hằng ngày (chỉ cần gọi một lần).
  static Future<void> scheduleCheckInReminder() async {
    try {
      await _plugin.zonedSchedule(
        AppConstants.notifIdCheckIn,
        '⏰ Nhắc chấm công vào',
        'Đừng quên chấm công vào hôm nay!',
        _nextInstanceOfTime(
          AppConstants.checkInNotifHour,
          AppConstants.checkInNotifMinute,
        ),
        _notifDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // Fallback: inexact alarm if exact alarm permission is denied
      await _plugin.zonedSchedule(
        AppConstants.notifIdCheckIn,
        '⏰ Nhắc chấm công vào',
        'Đừng quên chấm công vào hôm nay!',
        _nextInstanceOfTime(
          AppConstants.checkInNotifHour,
          AppConstants.checkInNotifMinute,
        ),
        _notifDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  /// Lên lịch check-out lúc 17:25 hằng ngày.
  static Future<void> scheduleCheckOutReminder() async {
    try {
      await _plugin.zonedSchedule(
        AppConstants.notifIdCheckOut,
        '🏁 Nhắc chấm công ra',
        'Đừng quên chấm công ra trước khi về!',
        _nextInstanceOfTime(
          AppConstants.checkOutNotifHour,
          AppConstants.checkOutNotifMinute,
        ),
        _notifDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      await _plugin.zonedSchedule(
        AppConstants.notifIdCheckOut,
        '🏁 Nhắc chấm công ra',
        'Đừng quên chấm công ra trước khi về!',
        _nextInstanceOfTime(
          AppConstants.checkOutNotifHour,
          AppConstants.checkOutNotifMinute,
        ),
        _notifDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static Future<void> cancelAll() => _plugin.cancelAll();
}
