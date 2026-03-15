import 'package:flutter/foundation.dart';

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

  const AttendanceUpdateTime({
    required this.recordId,
    this.newCheckIn,
    this.newCheckOut,
    this.lateReason,
    this.earlyLeaveReason,
  });
}

