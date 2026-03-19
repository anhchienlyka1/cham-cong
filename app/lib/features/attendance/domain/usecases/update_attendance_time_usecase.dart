import 'package:flutter/material.dart';

import '../entities/attendance_record.dart';
import '../repositories/attendance_repository.dart';

class UpdateAttendanceTimeUseCase {
  final AttendanceRepository _repo;
  UpdateAttendanceTimeUseCase(this._repo);

  Future<AttendanceRecord> call({
    required String userId,
    required String recordId,
    DateTime? checkIn,
    DateTime? checkOut,
    String? lateReason,
    String? earlyLeaveReason,
    String? note,
    TimeOfDay shiftStart = const TimeOfDay(hour: 8, minute: 30),
    TimeOfDay shiftEnd = const TimeOfDay(hour: 17, minute: 30),
  }) =>
      _repo.updateRecord(
        userId: userId,
        recordId: recordId,
        checkIn: checkIn,
        checkOut: checkOut,
        lateReason: lateReason,
        earlyLeaveReason: earlyLeaveReason,
        note: note,
        shiftStart: shiftStart,
        shiftEnd: shiftEnd,
      );
}

