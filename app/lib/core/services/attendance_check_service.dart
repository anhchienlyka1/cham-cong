import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../config/constants/app_constants.dart';
import 'location_service.dart';
import 'notification_service.dart';

/// Logic chạy trong background task:
/// - Lấy GPS, kiểm tra geofence văn phòng
/// - Gửi notification nếu chưa check-in / check-out hôm nay
class AttendanceCheckService {
  final LocationService _location;

  AttendanceCheckService({LocationService? locationService})
      : _location = locationService ?? LocationService();

  String get _today => DateFormat('yyyy-MM-dd').format(DateTime.now());

  // ── Check-in ────────────────────────────────────────────────────────────────
  /// Gọi từ background task check-in (khoảng 8:25 sáng).
  Future<void> runCheckInCheck() async {
    final prefs = await SharedPreferences.getInstance();

    // Reset flag nếu sang ngày mới
    final lastDate = prefs.getString(AppConstants.prefLastCheckinDate);
    if (lastDate != _today) {
      await prefs.setBool(AppConstants.prefCheckedInToday, false);
      await prefs.setString(AppConstants.prefLastCheckinDate, _today);
    }

    final alreadyDone = prefs.getBool(AppConstants.prefCheckedInToday) ?? false;
    if (alreadyDone) return;

    final atOffice = await _location.isAtOffice();
    if (atOffice) {
      await NotificationService.showImmediate(
        id: AppConstants.notifIdCheckIn,
        title: '📍 Bạn đang ở văn phòng!',
        body: 'Đừng quên chấm công vào nhé.',
      );
    }
  }

  // ── Check-out ───────────────────────────────────────────────────────────────
  /// Gọi từ background task check-out (khoảng 17:25 chiều).
  Future<void> runCheckOutCheck() async {
    final prefs = await SharedPreferences.getInstance();

    final lastDate = prefs.getString(AppConstants.prefLastCheckoutDate);
    if (lastDate != _today) {
      await prefs.setBool(AppConstants.prefCheckedOutToday, false);
      await prefs.setString(AppConstants.prefLastCheckoutDate, _today);
    }

    final alreadyDone = prefs.getBool(AppConstants.prefCheckedOutToday) ?? false;
    if (alreadyDone) return;

    // Chỉ nhắc nếu đã check-in hôm nay
    final checkedIn = prefs.getBool(AppConstants.prefCheckedInToday) ?? false;
    if (!checkedIn) return;

    final atOffice = await _location.isAtOffice();
    if (atOffice) {
      await NotificationService.showImmediate(
        id: AppConstants.notifIdCheckOut,
        title: '🏁 Sắp hết giờ làm!',
        body: 'Đừng quên chấm công ra trước khi về.',
      );
    }
  }

  // ── Đánh dấu đã check-in (gọi từ UI sau khi chấm công thành công) ──────────
  static Future<void> markCheckedIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefCheckedInToday, true);
    await prefs.setString(
      AppConstants.prefLastCheckinDate,
      DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
  }

  // ── Đánh dấu đã check-out ───────────────────────────────────────────────────
  static Future<void> markCheckedOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefCheckedOutToday, true);
    await prefs.setString(
      AppConstants.prefLastCheckoutDate,
      DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
  }
}
