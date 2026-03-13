import '../entities/attendance_record.dart';
import '../repositories/attendance_repository.dart';

class GetTodayRecordUseCase {
  final AttendanceRepository _repo;
  GetTodayRecordUseCase(this._repo);

  Future<AttendanceRecord?> call(String userId) =>
      _repo.getTodayRecord(userId);
}
