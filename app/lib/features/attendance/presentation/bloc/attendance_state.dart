import '../../domain/entities/attendance_record.dart';

enum AttendancePageStatus { initial, loading, loaded, error }

class AttendanceState {
  final AttendancePageStatus status;
  final AttendanceRecord? todayRecord;
  final List<AttendanceRecord> history;
  final double monthlyHours;
  final int workingDays;
  final int totalWorkingDays;
  final String? errorMessage;
  final String currentLocation;

  const AttendanceState({
    this.status = AttendancePageStatus.initial,
    this.todayRecord,
    this.history = const [],
    this.monthlyHours = 0.0,
    this.workingDays = 0,
    this.totalWorkingDays = 24,
    this.errorMessage,
    this.currentLocation = 'Văn phòng Quận 1, TP.HCM',
  });

  AttendanceState copyWith({
    AttendancePageStatus? status,
    AttendanceRecord? todayRecord,
    List<AttendanceRecord>? history,
    double? monthlyHours,
    int? workingDays,
    int? totalWorkingDays,
    String? errorMessage,
    String? currentLocation,
  }) {
    return AttendanceState(
      status: status ?? this.status,
      todayRecord: todayRecord ?? this.todayRecord,
      history: history ?? this.history,
      monthlyHours: monthlyHours ?? this.monthlyHours,
      workingDays: workingDays ?? this.workingDays,
      totalWorkingDays: totalWorkingDays ?? this.totalWorkingDays,
      errorMessage: errorMessage ?? this.errorMessage,
      currentLocation: currentLocation ?? this.currentLocation,
    );
  }

  // Helpers
  bool get isCheckedIn => todayRecord?.checkIn != null;
  bool get isCheckedOut => todayRecord?.checkOut != null;
  bool get isWorking => isCheckedIn && !isCheckedOut;

  double get workProgress {
    final hours = _effectiveHoursWorked;
    if (hours == null) return 0.0;
    return (hours / 8.0).clamp(0.0, 1.0);
  }

  /// Trả về '--' khi chưa checkout, có giá trị khi đã checkout hoặc đang tính thử real-time.
  String get formattedTotalHours {
    final hours = _effectiveHoursWorked;
    if (hours == null) return '--';
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  /// Số giờ thực tế: nếu có hoursWorked thì dùng, nếu đang làm việc (checkIn nhưng chưa checkOut) thì tính real-time.
  double? get _effectiveHoursWorked {
    if (todayRecord == null || todayRecord!.checkIn == null) return null;
    if (todayRecord!.hoursWorked != null) return todayRecord!.hoursWorked;
    // Đang làm việc: tính giờ tạm thời, trừ 1.5h (90 phút) nghỉ trưa
    final totalMin = DateTime.now().difference(todayRecord!.checkIn!).inMinutes;
    return (totalMin - 90) / 60.0;
  }
}
