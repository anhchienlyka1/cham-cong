import '../entities/attendance_record.dart';

/// Định nghĩa contract cho Attendance data operations.
abstract class AttendanceRepository {
  /// Lấy record của ngày hôm nay cho [userId].
  Future<AttendanceRecord?> getTodayRecord(String userId);

  /// Lấy lịch sử chấm công theo [month]/[year] cho [userId].
  Future<List<AttendanceRecord>> getHistory({
    required String userId,
    required int month,
    required int year,
  });

  /// Tạo hoặc cập nhật record check-in.
  Future<AttendanceRecord> checkIn({
    required String userId,
    required DateTime time,
    required String location,
    String? lateReason,
  });

  /// Cập nhật record check-out.
  Future<AttendanceRecord> checkOut({
    required String userId,
    required String recordId,
    required DateTime time,
    String? earlyLeaveReason,
  });

  /// Cập nhật giờ checkIn/checkOut của một record.
  Future<AttendanceRecord> updateRecord({
    required String userId,
    required String recordId,
    DateTime? checkIn,
    DateTime? checkOut,
  });
}
