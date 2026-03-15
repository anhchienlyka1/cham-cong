class AttendanceRecord {
  final String id;
  final DateTime date;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String? location;
  final double? hoursWorked;
  final AttendanceStatus status;
  final String? lateReason;
  final String? earlyLeaveReason;
  final bool isLateFlag;
  final bool isEarlyLeaveFlag;
  final String? leaveType;
  final String? note;
  final double? overtimeHours;

  const AttendanceRecord({
    required this.id,
    required this.date,
    this.checkIn,
    this.checkOut,
    this.location,
    this.hoursWorked,
    this.status = AttendanceStatus.absent,
    this.lateReason,
    this.earlyLeaveReason,
    this.isLateFlag = false,
    this.isEarlyLeaveFlag = false,
    this.leaveType,
    this.note,
    this.overtimeHours,
  });

  AttendanceRecord copyWith({
    String? id,
    DateTime? date,
    DateTime? checkIn,
    DateTime? checkOut,
    String? location,
    double? hoursWorked,
    AttendanceStatus? status,
    String? lateReason,
    String? earlyLeaveReason,
    bool? isLateFlag,
    bool? isEarlyLeaveFlag,
    String? leaveType,
    String? note,
    double? overtimeHours,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      location: location ?? this.location,
      hoursWorked: hoursWorked ?? this.hoursWorked,
      status: status ?? this.status,
      lateReason: lateReason ?? this.lateReason,
      earlyLeaveReason: earlyLeaveReason ?? this.earlyLeaveReason,
      isLateFlag: isLateFlag ?? this.isLateFlag,
      isEarlyLeaveFlag: isEarlyLeaveFlag ?? this.isEarlyLeaveFlag,
      leaveType: leaveType ?? this.leaveType,
      note: note ?? this.note,
      overtimeHours: overtimeHours ?? this.overtimeHours,
    );
  }

  /// Trả về true nếu ngày này là ngày đi làm thực tế (không phải nghỉ/vắng)
  bool get isActiveWorkDay => const {
    AttendanceStatus.present,
    AttendanceStatus.late,
    AttendanceStatus.earlyLeave,
    AttendanceStatus.halfDay,
    AttendanceStatus.overtime,
    AttendanceStatus.workFromHome,
  }.contains(status);

  /// Trả về true nếu check-in muộn (sau 8:30 hoặc theo flag)
  bool get isLate {
    if (isLateFlag) return true;
    if (checkIn == null) return false;
    final cutoff = DateTime(checkIn!.year, checkIn!.month, checkIn!.day, 8, 30);
    return checkIn!.isAfter(cutoff);
  }

  /// Trả về true nếu check-out sớm (trước 17:30 hoặc theo flag)
  bool get isEarlyLeave {
    if (isEarlyLeaveFlag) return true;
    if (checkOut == null) return false;
    final cutoff =
        DateTime(checkOut!.year, checkOut!.month, checkOut!.day, 17, 30);
    return checkOut!.isBefore(cutoff);
  }

  String get formattedCheckIn {
    if (checkIn == null) return '--:--';
    return '${checkIn!.hour.toString().padLeft(2, '0')}:${checkIn!.minute.toString().padLeft(2, '0')}';
  }

  String get formattedCheckOut {
    if (checkOut == null) return '--:--';
    return '${checkOut!.hour.toString().padLeft(2, '0')}:${checkOut!.minute.toString().padLeft(2, '0')}';
  }

  String get formattedHours {
    if (hoursWorked == null) return '0.0 hrs';
    return '${hoursWorked!.toStringAsFixed(1)} hrs';
  }

  String get dayOfWeek {
    const days = [
      'Chủ Nhật',
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy'
    ];
    return days[date.weekday % 7];
  }

  String get formattedDate {
    return '${date.day} THÁNG ${date.month}, ${date.year}';
  }
}

enum AttendanceStatus {
  present,
  absent,
  late,
  halfDay,
  onLeave,
  earlyLeave,
  sickLeave,
  businessTrip,
  workFromHome,
  holiday,
  overtime,
  forgotPunch,
}
