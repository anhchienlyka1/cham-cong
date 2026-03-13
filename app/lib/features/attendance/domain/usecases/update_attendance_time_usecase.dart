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
  }) =>
      _repo.updateRecord(
        userId: userId,
        recordId: recordId,
        checkIn: checkIn,
        checkOut: checkOut,
      );
}
