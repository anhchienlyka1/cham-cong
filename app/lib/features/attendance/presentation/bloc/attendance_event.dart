import 'package:flutter/foundation.dart';

@immutable
abstract class AttendanceEvent {
  const AttendanceEvent();
}

class AttendanceCheckIn extends AttendanceEvent {
  /// Lý do đi muộn (nếu check-in sau 8:30)
  final String? lateReason;

  const AttendanceCheckIn({this.lateReason});
}

class AttendanceCheckOut extends AttendanceEvent {
  /// Lý do về sớm (nếu check-out trước 17:30)
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

  const AttendanceUpdateTime({
    required this.recordId,
    this.newCheckIn,
    this.newCheckOut,
  });
}
