import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/usecases/check_in_usecase.dart';
import '../../domain/usecases/check_out_usecase.dart';
import '../../domain/usecases/get_attendance_history_usecase.dart';
import '../../domain/usecases/get_today_record_usecase.dart';
import '../../domain/usecases/update_attendance_time_usecase.dart';
import '../../domain/utils/shift_parser.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final CheckInUseCase _checkInUseCase;
  final CheckOutUseCase _checkOutUseCase;
  final GetAttendanceHistoryUseCase _getHistoryUseCase;
  final GetTodayRecordUseCase _getTodayRecordUseCase;
  final UpdateAttendanceTimeUseCase _updateTimeUseCase;
  final AuthBloc _authBloc;

  AttendanceBloc({
    required CheckInUseCase checkInUseCase,
    required CheckOutUseCase checkOutUseCase,
    required GetAttendanceHistoryUseCase getHistoryUseCase,
    required GetTodayRecordUseCase getTodayRecordUseCase,
    required UpdateAttendanceTimeUseCase updateTimeUseCase,
    required AuthBloc authBloc,
  })  : _checkInUseCase = checkInUseCase,
        _checkOutUseCase = checkOutUseCase,
        _getHistoryUseCase = getHistoryUseCase,
        _getTodayRecordUseCase = getTodayRecordUseCase,
        _updateTimeUseCase = updateTimeUseCase,
        _authBloc = authBloc,
        super(const AttendanceState()) {
    on<AttendanceCheckIn>(_onCheckIn);
    on<AttendanceCheckOut>(_onCheckOut);
    on<AttendanceLoadHistory>(_onLoadHistory);
    on<AttendanceUpdateTime>(_onUpdateTime);
  }

  String get _userId => FirebaseAuth.instance.currentUser!.uid;

  // ── Sync record vào history ─────────────────────────────────────
  /// Thêm hoặc cập nhật [record] trong list history hiện tại,
  /// đồng thời tính lại monthlyHours & workingDays.
  AttendanceState _syncRecordToHistory(
    AttendanceState current,
    AttendanceRecord record,
  ) {
    final now = DateTime.now();
    final updatedHistory = List<AttendanceRecord>.from(current.history);

    // Tìm xem record đã tồn tại trong history chưa
    final existingIndex = updatedHistory.indexWhere((r) => r.id == record.id);
    if (existingIndex >= 0) {
      updatedHistory[existingIndex] = record;
    } else {
      // Chỉ thêm nếu record thuộc tháng hiện tại (history đang hiển thị)
      if (record.date.month == now.month && record.date.year == now.year) {
        updatedHistory.insert(0, record); // Thêm đầu danh sách (mới nhất)
      }
    }

    // Tính lại tổng giờ và số ngày đi làm trong tháng
    double monthlyHours = 0;
    int workingDays = 0;
    for (final r in updatedHistory) {
      if (r.hoursWorked != null) {
        monthlyHours += r.hoursWorked!;
      }
      if (r.isActiveWorkDay) {
        workingDays++;
      }
    }

    return current.copyWith(
      todayRecord: record,
      history: updatedHistory,
      monthlyHours: monthlyHours,
      workingDays: workingDays,
    );
  }

  // ── Check-in ────────────────────────────────────────────────────
  Future<void> _onCheckIn(
    AttendanceCheckIn event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      final record = await _checkInUseCase(
        userId: _userId,
        location: state.currentLocation,
        lateReason: event.lateReason,
      );
      emit(_syncRecordToHistory(state, record));
    } catch (e) {
      emit(state.copyWith(
        status: AttendancePageStatus.error,
        errorMessage: 'Check-in thất bại: $e',
      ));
    }
  }

  // ── Check-out ───────────────────────────────────────────────────
  Future<void> _onCheckOut(
    AttendanceCheckOut event,
    Emitter<AttendanceState> emit,
  ) async {
    if (state.todayRecord == null || state.todayRecord!.checkIn == null) return;
    if (state.todayRecord!.checkOut != null) return; // Đã checkout rồi

    try {
      final record = await _checkOutUseCase(
        userId: _userId,
        recordId: state.todayRecord!.id,
        earlyLeaveReason: event.earlyLeaveReason,
      );
      emit(_syncRecordToHistory(state, record));
    } catch (e) {
      emit(state.copyWith(
        status: AttendancePageStatus.error,
        errorMessage: 'Check-out thất bại: $e',
      ));
    }
  }

  // ── Load history + today record ─────────────────────────────────
  Future<void> _onLoadHistory(
    AttendanceLoadHistory event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(status: AttendancePageStatus.loading));

    try {
      final now = DateTime.now();

      // Tải song song: today record + history tháng hiện tại
      final results = await Future.wait([
        _getTodayRecordUseCase(_userId),
        _getHistoryUseCase(
          userId: _userId,
          month: now.month,
          year: now.year,
        ),
      ]);

      final todayRecord = results[0] as AttendanceRecord?;
      final history = results[1] as List<AttendanceRecord>;

      // Tính tổng giờ và số ngày đi làm trong tháng
      double monthlyHours = 0;
      int workingDays = 0;
      for (final r in history) {
        if (r.hoursWorked != null) {
          monthlyHours += r.hoursWorked!;
        }
        if (r.isActiveWorkDay) {
          workingDays++;
        }
      }

      emit(state.copyWith(
        status: AttendancePageStatus.loaded,
        todayRecord: todayRecord,
        history: history,
        monthlyHours: monthlyHours,
        workingDays: workingDays,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AttendancePageStatus.error,
        errorMessage: 'Tải dữ liệu thất bại: $e',
      ));
    }
  }

  // ── Update time (sửa giờ check-in / check-out) ─────────────────
  Future<void> _onUpdateTime(
    AttendanceUpdateTime event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      // Lấy shift từ AuthBloc
      final shift = _authBloc.state.user?.shift;
      final (shiftStart, shiftEnd) = ShiftParser.parse(shift);

      final updated = await _updateTimeUseCase(
        userId: _userId,
        recordId: event.recordId,
        checkIn: event.newCheckIn,
        checkOut: event.newCheckOut,
        lateReason: event.lateReason,
        earlyLeaveReason: event.earlyLeaveReason,
        note: event.note,
        shiftStart: shiftStart,
        shiftEnd: shiftEnd,
      );

      // Cập nhật trong history
      final updatedHistory = state.history.map((record) {
        return record.id == event.recordId ? updated : record;
      }).toList();

      // Cập nhật today record nếu trùng id
      final newTodayRecord =
          event.recordId == state.todayRecord?.id ? updated : state.todayRecord;

      emit(state.copyWith(
        todayRecord: newTodayRecord,
        history: updatedHistory,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AttendancePageStatus.error,
        errorMessage: 'Cập nhật thất bại: $e',
      ));
    }
  }
}

