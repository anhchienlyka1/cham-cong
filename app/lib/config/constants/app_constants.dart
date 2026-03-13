class AppConstants {
  AppConstants._();

  static const String appName = 'Chấm Công';
  static const String appVersion = '0.1.0';

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String localeKey = 'locale';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 32;

  // ── Office location ─────────────────────────────────────────────────────────
  /// Tọa độ văn phòng – chỉnh theo địa chỉ thực tế
  static const double officeLatitude = 10.776889;
  static const double officeLongitude = 106.700806;
  /// Bán kính vùng cho phép chấm công (mét)
  static const double officeRadiusMeters = 200.0;

  // ── Background task names ───────────────────────────────────────────────────
  static const String bgTaskCheckIn  = 'bg_attendance_checkin_task';
  static const String bgTaskCheckOut = 'bg_attendance_checkout_task';

  // ── SharedPreferences keys ──────────────────────────────────────────────────
  static const String prefCheckedInToday  = 'pref_checked_in_today';
  static const String prefCheckedOutToday = 'pref_checked_out_today';
  /// 'yyyy-MM-dd' của lần check-in cuối để reset mỗi ngày
  static const String prefLastCheckinDate  = 'pref_last_checkin_date';
  static const String prefLastCheckoutDate = 'pref_last_checkout_date';

  // ── Notification IDs ────────────────────────────────────────────────────────
  static const int notifIdCheckIn  = 1001;
  static const int notifIdCheckOut = 1002;

  // ── Check-in / check-out times ──────────────────────────────────────────────
  /// Giờ nhắc check-in: 8:25
  static const int checkInNotifHour   = 8;
  static const int checkInNotifMinute = 25;
  /// Giờ nhắc check-out: 17:25
  static const int checkOutNotifHour   = 17;
  static const int checkOutNotifMinute = 25;
}
