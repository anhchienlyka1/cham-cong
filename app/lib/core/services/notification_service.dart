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

  /// Lên lịch check-in hằng ngày.
  ///
  /// [hour] và [minute] là giờ nhắc (mặc định lấy từ AppConstants nếu không truyền).
  static Future<void> scheduleCheckInReminder({
    int? hour,
    int? minute,
  }) async {
    final h = hour ?? AppConstants.checkInNotifHour;
    final m = minute ?? AppConstants.checkInNotifMinute;
    try {
      await _plugin.zonedSchedule(
        AppConstants.notifIdCheckIn,
        '⏰ Nhắc chấm công vào',
        'Đừng quên chấm công vào hôm nay!',
        _nextInstanceOfTime(h, m),
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
        _nextInstanceOfTime(h, m),
        _notifDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  /// Lên lịch check-out hằng ngày.
  ///
  /// [hour] và [minute] là giờ nhắc (mặc định lấy từ AppConstants nếu không truyền).
  static Future<void> scheduleCheckOutReminder({
    int? hour,
    int? minute,
  }) async {
    final h = hour ?? AppConstants.checkOutNotifHour;
    final m = minute ?? AppConstants.checkOutNotifMinute;
    try {
      await _plugin.zonedSchedule(
        AppConstants.notifIdCheckOut,
        '🏁 Nhắc chấm công ra',
        'Đừng quên chấm công ra trước khi về!',
        _nextInstanceOfTime(h, m),
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
        _nextInstanceOfTime(h, m),
        _notifDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  /// Tính lại và đăng ký lại cả 2 alarm dựa trên ca chọn.
  ///
  /// [shiftStart] — giờ bắt đầu ca (e.g. "8:30").
  /// [shiftEnd]   — giờ kết thúc ca (e.g. "17:30").
  /// Nhắc trước 5 phút mỗi đầu/cuối ca.
  static Future<void> rescheduleForShift({
    required String shiftStart,
    required String shiftEnd,
  }) async {
    final start = _parseShiftTime(shiftStart);
    final end   = _parseShiftTime(shiftEnd);

    // Huỷ alarm cũ
    await _plugin.cancel(AppConstants.notifIdCheckIn);
    await _plugin.cancel(AppConstants.notifIdCheckOut);

    // Nhắc trước 5 phút
    final (inH, inM) = _subtractMinutes(start.$1, start.$2, 5);
    final (outH, outM) = _subtractMinutes(end.$1, end.$2, 5);

    await scheduleCheckInReminder(hour: inH, minute: inM);
    await scheduleCheckOutReminder(hour: outH, minute: outM);
  }

  /// Parse "H:mm" → (hour, minute). Trả về (0, 0) nếu lỗi.
  static (int, int) _parseShiftTime(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return (0, 0);
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return (h, m);
  }

  /// Trừ [minutes] phút khỏi (hour, minute), clamp về 0.
  static (int, int) _subtractMinutes(int h, int m, int minutes) {
    final total = h * 60 + m - minutes;
    if (total < 0) return (0, 0);
    return (total ~/ 60, total % 60);
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
