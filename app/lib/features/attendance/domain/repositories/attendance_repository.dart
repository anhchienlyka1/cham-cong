import 'package:flutter/material.dart';

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

  /// Cập nhật giờ checkIn/checkOut của một record, tự tính lại status.
  Future<AttendanceRecord> updateRecord({
    required String userId,
    required String recordId,
    DateTime? checkIn,
    DateTime? checkOut,
    String? lateReason,
    String? earlyLeaveReason,
    String? note,
    TimeOfDay shiftStart = const TimeOfDay(hour: 8, minute: 30),
    TimeOfDay shiftEnd = const TimeOfDay(hour: 17, minute: 30),
  });

  /// Xoá một record khỏi Firestore.
  /// Đồng thời ghi nhận ngày đó vào collection deletedDays
  /// để tránh auto-detect forgotPunch tạo lại record.
  Future<void> deleteRecord({
    required String userId,
    required String recordId,
  });

  /// Lấy tập hợp các ngày đã bị xoá thủ công trong tháng [month]/[year].
  /// Dùng để loại trừ khỏi auto-detect forgotPunch.
  Future<Set<DateTime>> getDeletedDays({
    required String userId,
    required int month,
    required int year,
  });

  /// Tạo record mới với trạng thái "quên chấm công" (forgotPunch).
  Future<AttendanceRecord> submitForgotPunch({
    required String userId,
    required DateTime date,
    required DateTime checkIn,
    required DateTime checkOut,
    required String reason,
  });

  /// Đánh dấu nhanh loại ngày hôm nay (nghỉ phép / NKL / WFH).
  /// Tạo record mới nếu chưa tồn tại, ngược lại cập nhật status.
  Future<AttendanceRecord> markDayType({
    required String userId,
    required AttendanceStatus status,
  });
}

