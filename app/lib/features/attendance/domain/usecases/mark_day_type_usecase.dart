import '../entities/attendance_record.dart';
import '../repositories/attendance_repository.dart';

class MarkDayTypeUseCase {
  final AttendanceRepository _repository;
  MarkDayTypeUseCase(this._repository);

  Future<AttendanceRecord> call({
    required String userId,
    required AttendanceStatus status,
  }) {
    return _repository.markDayType(userId: userId, status: status);
  }
}
