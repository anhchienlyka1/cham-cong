import '../entities/attendance_record.dart';
import '../repositories/attendance_repository.dart';

class SubmitForgotPunchUseCase {
  final AttendanceRepository _repository;

  SubmitForgotPunchUseCase(this._repository);

  Future<AttendanceRecord> call({
    required String userId,
    required DateTime date,
    required DateTime checkIn,
    required DateTime checkOut,
    required String reason,
  }) {
    return _repository.submitForgotPunch(
      userId: userId,
      date: date,
      checkIn: checkIn,
      checkOut: checkOut,
      reason: reason,
    );
  }
}
