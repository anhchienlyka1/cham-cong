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
    );
  }

  /// Trả về true nếu check-in muộn (sau 8:30)
  bool get isLate {
    if (checkIn == null) return false;
    final cutoff = DateTime(checkIn!.year, checkIn!.month, checkIn!.day, 8, 30);
    return checkIn!.isAfter(cutoff);
  }

  /// Trả về true nếu check-out sớm (trước 17:30)
  bool get isEarlyLeave {
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
}
