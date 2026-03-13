import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../../config/constants/app_constants.dart';
import '../services/attendance_check_service.dart';
import '../services/notification_service.dart';

/// Hàm callback cho Workmanager – phải là top-level function.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    // Khởi notification (cần thiết trong isolate mới)
    await NotificationService.init();

    final svc = AttendanceCheckService();

    switch (task) {
      case AppConstants.bgTaskCheckIn:
        await svc.runCheckInCheck();
        break;
      case AppConstants.bgTaskCheckOut:
        await svc.runCheckOutCheck();
        break;
    }

    // Trên iOS không hỗ trợ periodic task nên phải tự đăng ký lại
    // one-off task cho ngày hôm sau.
    if (Platform.isIOS) {
      await _registerOneOffTasks();
    }

    return Future.value(true);
  });
}

/// Đăng ký các background task với Workmanager.
/// Gọi sau khi đã xin quyền location.
Future<void> registerBackgroundTasks() async {
  if (Platform.isAndroid) {
    await _registerPeriodicTasks();
  } else if (Platform.isIOS) {
    await _registerOneOffTasks();
  }
}

/// Android: dùng registerPeriodicTask (repeat mỗi 24h).
Future<void> _registerPeriodicTasks() async {
  final wm = Workmanager();
  final now = DateTime.now();

  // Task check-in
  var checkInTime = DateTime(now.year, now.month, now.day,
      AppConstants.checkInNotifHour, AppConstants.checkInNotifMinute);
  if (checkInTime.isBefore(now)) {
    checkInTime = checkInTime.add(const Duration(days: 1));
  }

  await wm.registerPeriodicTask(
    AppConstants.bgTaskCheckIn,
    AppConstants.bgTaskCheckIn,
    frequency: const Duration(hours: 24),
    initialDelay: checkInTime.difference(now),
    constraints: Constraints(networkType: NetworkType.notRequired),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
  );

  // Task check-out
  var checkOutTime = DateTime(now.year, now.month, now.day,
      AppConstants.checkOutNotifHour, AppConstants.checkOutNotifMinute);
  if (checkOutTime.isBefore(now)) {
    checkOutTime = checkOutTime.add(const Duration(days: 1));
  }

  await wm.registerPeriodicTask(
    AppConstants.bgTaskCheckOut,
    AppConstants.bgTaskCheckOut,
    frequency: const Duration(hours: 24),
    initialDelay: checkOutTime.difference(now),
    constraints: Constraints(networkType: NetworkType.notRequired),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
  );
}

/// iOS: dùng registerOneOffTask (tự đăng ký lại sau mỗi lần chạy).
Future<void> _registerOneOffTasks() async {
  final wm = Workmanager();
  final now = DateTime.now();

  // Task check-in
  var checkInTime = DateTime(now.year, now.month, now.day,
      AppConstants.checkInNotifHour, AppConstants.checkInNotifMinute);
  if (checkInTime.isBefore(now)) {
    checkInTime = checkInTime.add(const Duration(days: 1));
  }

  await wm.registerOneOffTask(
    AppConstants.bgTaskCheckIn,
    AppConstants.bgTaskCheckIn,
    initialDelay: checkInTime.difference(now),
    constraints: Constraints(networkType: NetworkType.notRequired),
  );

  // Task check-out
  var checkOutTime = DateTime(now.year, now.month, now.day,
      AppConstants.checkOutNotifHour, AppConstants.checkOutNotifMinute);
  if (checkOutTime.isBefore(now)) {
    checkOutTime = checkOutTime.add(const Duration(days: 1));
  }

  await wm.registerOneOffTask(
    AppConstants.bgTaskCheckOut,
    AppConstants.bgTaskCheckOut,
    initialDelay: checkOutTime.difference(now),
    constraints: Constraints(networkType: NetworkType.notRequired),
  );
}
