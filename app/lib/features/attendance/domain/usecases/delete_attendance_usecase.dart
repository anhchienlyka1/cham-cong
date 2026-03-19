import '../repositories/attendance_repository.dart';

class DeleteAttendanceUseCase {
  final AttendanceRepository _repository;

  const DeleteAttendanceUseCase(this._repository);

  Future<void> call({
    required String userId,
    required String recordId,
  }) =>
      _repository.deleteRecord(userId: userId, recordId: recordId);
}
