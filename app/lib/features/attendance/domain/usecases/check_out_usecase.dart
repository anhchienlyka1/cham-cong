import '../entities/attendance_record.dart';
import '../repositories/attendance_repository.dart';

class CheckOutUseCase {
  final AttendanceRepository _repo;
  CheckOutUseCase(this._repo);

  Future<AttendanceRecord> call({
    required String userId,
    required String recordId,
    String? earlyLeaveReason,
  }) =>
      _repo.checkOut(
        userId: userId,
        recordId: recordId,
        time: DateTime.now(),
        earlyLeaveReason: earlyLeaveReason,
      );
}
