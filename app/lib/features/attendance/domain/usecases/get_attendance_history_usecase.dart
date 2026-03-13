import '../entities/attendance_record.dart';
import '../repositories/attendance_repository.dart';

class GetAttendanceHistoryUseCase {
  final AttendanceRepository _repo;
  GetAttendanceHistoryUseCase(this._repo);

  Future<List<AttendanceRecord>> call({
    required String userId,
    required int month,
    required int year,
  }) =>
      _repo.getHistory(userId: userId, month: month, year: year);
}
