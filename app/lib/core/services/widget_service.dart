import 'package:home_widget/home_widget.dart';

import '../../features/attendance/domain/entities/attendance_record.dart';

/// Service giao tiếp với native widget (Android/iOS).
/// Ghi dữ liệu chấm công hôm nay vào SharedPreferences native.
class WidgetService {
  static const String _appGroupId = 'group.com.company.chamcong32';
  static const String _androidWidgetName = 'AttendanceWidget';

  /// Khởi tạo, cần gọi sau khi app khởi động.
  Future<void> initialize() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  /// Cập nhật dữ liệu chấm công hôm nay lên widget.
  Future<void> updateTodayAttendance(AttendanceRecord? record) async {
    try {
      final checkIn = record?.formattedCheckIn ?? '--:--';
      final checkOut = record?.formattedCheckOut ?? '--:--';
      final status = _statusLabel(record?.status);
      final hours = record?.formattedHours ?? '0.0 hrs';
      final hasCheckedIn = record?.checkIn != null ? '1' : '0';

      await Future.wait([
        HomeWidget.saveWidgetData<String>('checkIn', checkIn),
        HomeWidget.saveWidgetData<String>('checkOut', checkOut),
        HomeWidget.saveWidgetData<String>('status', status),
        HomeWidget.saveWidgetData<String>('hours', hours),
        HomeWidget.saveWidgetData<String>('hasCheckedIn', hasCheckedIn),
      ]);

      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
        iOSName: _androidWidgetName,
      );
    } catch (_) {
      // Widget update không được block main flow
    }
  }

  /// Chuyển enum sang tiếng Việt để hiển thị.
  String _statusLabel(AttendanceStatus? status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Có mặt';
      case AttendanceStatus.absent:
        return 'Vắng';
      case AttendanceStatus.late:
        return 'Đi muộn';
      case AttendanceStatus.halfDay:
        return 'Nửa ngày';
      case AttendanceStatus.onLeave:
        return 'Nghỉ phép';
      case AttendanceStatus.unpaidLeave:
        return 'Nghỉ không lương';
      case AttendanceStatus.earlyLeave:
        return 'Về sớm';
      case AttendanceStatus.sickLeave:
        return 'Nghỉ bệnh';
      case AttendanceStatus.businessTrip:
        return 'Công tác';
      case AttendanceStatus.workFromHome:
        return 'WFH';
      case AttendanceStatus.holiday:
        return 'Ngày lễ';
      case AttendanceStatus.overtime:
        return 'Tăng ca';
      case AttendanceStatus.forgotPunch:
        return 'Quên chấm';
      case null:
        return 'Chưa chấm công';
    }
  }
}
