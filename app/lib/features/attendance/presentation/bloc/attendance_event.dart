import 'package:flutter/foundation.dart';

import '../../domain/entities/attendance_record.dart';

@immutable
abstract class AttendanceEvent {
  const AttendanceEvent();
}

class AttendanceCheckIn extends AttendanceEvent {
  /// Lý do đi muộn (nếu check-in sau giờ shift)
  final String? lateReason;

  const AttendanceCheckIn({this.lateReason});
}

class AttendanceCheckOut extends AttendanceEvent {
  /// Lý do về sớm (nếu check-out trước giờ shift)
  final String? earlyLeaveReason;

  const AttendanceCheckOut({this.earlyLeaveReason});
}

class AttendanceLoadHistory extends AttendanceEvent {
  const AttendanceLoadHistory();
}

class AttendanceUpdateTime extends AttendanceEvent {
  final String recordId;
  final DateTime? newCheckIn;
  final DateTime? newCheckOut;
  final String? lateReason;
  final String? earlyLeaveReason;
  final String? note;

  const AttendanceUpdateTime({
    required this.recordId,
    this.newCheckIn,
    this.newCheckOut,
    this.lateReason,
    this.earlyLeaveReason,
    this.note,
  });
}

class AttendanceDeleteRecord extends AttendanceEvent {
  final String recordId;
  const AttendanceDeleteRecord({required this.recordId});
}

/// Đánh dấu nhanh loại ngày (Nghỉ phép / NKL / WFH).
class AttendanceMarkDayType extends AttendanceEvent {
  final AttendanceStatus dayType;
  const AttendanceMarkDayType({required this.dayType});
}
