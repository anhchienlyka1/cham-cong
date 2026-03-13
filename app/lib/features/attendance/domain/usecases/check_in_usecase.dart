import '../entities/attendance_record.dart';
import '../repositories/attendance_repository.dart';

class CheckInUseCase {
  final AttendanceRepository _repo;
  CheckInUseCase(this._repo);

  Future<AttendanceRecord> call({
    required String userId,
    required String location,
    String? lateReason,
  }) =>
      _repo.checkIn(
        userId: userId,
        time: DateTime.now(),
        location: location,
        lateReason: lateReason,
      );
}
