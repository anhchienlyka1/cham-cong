import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/usecases/check_in_usecase.dart';
import '../../domain/usecases/check_out_usecase.dart';
import '../../domain/usecases/get_attendance_history_usecase.dart';
import '../../domain/usecases/get_today_record_usecase.dart';
import '../../domain/usecases/delete_attendance_usecase.dart';
import '../../domain/usecases/update_attendance_time_usecase.dart';
import '../../domain/usecases/submit_forgot_punch_usecase.dart';
import '../../domain/usecases/mark_day_type_usecase.dart';
import '../../domain/utils/shift_parser.dart';
import '../../../../core/services/widget_service.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final CheckInUseCase _checkInUseCase;
  final CheckOutUseCase _checkOutUseCase;
  final GetAttendanceHistoryUseCase _getHistoryUseCase;
  final GetTodayRecordUseCase _getTodayRecordUseCase;
  final UpdateAttendanceTimeUseCase _updateTimeUseCase;
  final DeleteAttendanceUseCase _deleteUseCase;
  final SubmitForgotPunchUseCase _forgotPunchUseCase;
  final MarkDayTypeUseCase _markDayTypeUseCase;
  final AttendanceRepository _repository;
  final AuthBloc _authBloc;
  final WidgetService _widgetService;

  AttendanceBloc({
    required CheckInUseCase checkInUseCase,
    required CheckOutUseCase checkOutUseCase,
    required GetAttendanceHistoryUseCase getHistoryUseCase,
    required GetTodayRecordUseCase getTodayRecordUseCase,
    required UpdateAttendanceTimeUseCase updateTimeUseCase,
    required DeleteAttendanceUseCase deleteUseCase,
    required SubmitForgotPunchUseCase forgotPunchUseCase,
    required MarkDayTypeUseCase markDayTypeUseCase,
    required AttendanceRepository repository,
    required AuthBloc authBloc,
    required WidgetService widgetService,
  })  : _checkInUseCase = checkInUseCase,
        _checkOutUseCase = checkOutUseCase,
        _getHistoryUseCase = getHistoryUseCase,
        _getTodayRecordUseCase = getTodayRecordUseCase,
        _updateTimeUseCase = updateTimeUseCase,
        _deleteUseCase = deleteUseCase,
        _forgotPunchUseCase = forgotPunchUseCase,
        _markDayTypeUseCase = markDayTypeUseCase,
        _repository = repository,
        _authBloc = authBloc,
        _widgetService = widgetService,
        super(const AttendanceState()) {
    on<AttendanceCheckIn>(_onCheckIn);
    on<AttendanceCheckOut>(_onCheckOut);
    on<AttendanceLoadHistory>(_onLoadHistory);
    on<AttendanceUpdateTime>(_onUpdateTime);
    on<AttendanceDeleteRecord>(_onDeleteRecord);
    on<AttendanceMarkDayType>(_onMarkDayType);
  }

  String get _userId => FirebaseAuth.instance.currentUser!.uid;

  // ── Sync record vào history ─────────────────────────────────────
  AttendanceState _syncRecordToHistory(
    AttendanceState current,
    AttendanceRecord record,
  ) {
    final now = DateTime.now();
    final updatedHistory = List<AttendanceRecord>.from(current.history);

    final existingIndex = updatedHistory.indexWhere((r) => r.id == record.id);
    if (existingIndex >= 0) {
      updatedHistory[existingIndex] = record;
    } else {
      if (record.date.month == now.month && record.date.year == now.year) {
        updatedHistory.insert(0, record);
      }
    }

    double monthlyHours = 0;
    int workingDays = 0;
    for (final r in updatedHistory) {
      if (r.hoursWorked != null) monthlyHours += r.hoursWorked!;
      if (r.isActiveWorkDay) workingDays++;
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
      _widgetService.updateTodayAttendance(record);
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
    if (state.todayRecord!.checkOut != null) return;

    try {
      final record = await _checkOutUseCase(
        userId: _userId,
        recordId: state.todayRecord!.id,
        earlyLeaveReason: event.earlyLeaveReason,
      );
      emit(_syncRecordToHistory(state, record));
      _widgetService.updateTodayAttendance(record);
    } catch (e) {
      emit(state.copyWith(
        status: AttendancePageStatus.error,
        errorMessage: 'Check-out thất bại: $e',
      ));
    }
  }

  // ── Load history + today record + auto-detect forgot punch ──────
  Future<void> _onLoadHistory(
    AttendanceLoadHistory event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(status: AttendancePageStatus.loading));

    try {
      final now = DateTime.now();

      final results = await Future.wait([
        _getTodayRecordUseCase(_userId),
        _getHistoryUseCase(
          userId: _userId,
          month: now.month,
          year: now.year,
        ),
        // Lấy danh sách ngày đã bị xoá thủ công để bỏ qua khi auto-detect
        _repository.getDeletedDays(
          userId: _userId,
          month: now.month,
          year: now.year,
        ),
      ]);

      final todayRecord = results[0] as AttendanceRecord?;
      var history = results[1] as List<AttendanceRecord>;
      final deletedDays = results[2] as Set<DateTime>;

      // ── Auto-detect forgot punch ────────────────────────────
      // Quét các ngày làm việc từ đầu tháng đến hôm qua.
      // Nếu ngày nào không có record VÀ chưa bị xoá thủ công → tự tạo forgotPunch.
      final missingDays = _findMissingWorkDays(history, now, deletedDays);
      if (missingDays.isNotEmpty) {
        final newRecords = await _autoMarkForgotPunch(missingDays);
        if (newRecords.isNotEmpty) {
          history = [...history, ...newRecords]
            ..sort((a, b) => b.date.compareTo(a.date));
        }
      }

      double monthlyHours = 0;
      int workingDays = 0;
      for (final r in history) {
        if (r.hoursWorked != null) monthlyHours += r.hoursWorked!;
        if (r.isActiveWorkDay) workingDays++;
      }

      emit(state.copyWith(
        status: AttendancePageStatus.loaded,
        todayRecord: todayRecord,
        history: history,
        monthlyHours: monthlyHours,
        workingDays: workingDays,
      ));
      _widgetService.updateTodayAttendance(todayRecord);
    } catch (e) {
      emit(state.copyWith(
        status: AttendancePageStatus.error,
        errorMessage: 'Tải dữ liệu thất bại: $e',
      ));
    }
  }

  /// Tìm các ngày làm việc (T2–T6) từ ngày 1 đến hôm qua
  /// mà chưa có record nào trong [history] và chưa bị xoá thủ công.
  List<DateTime> _findMissingWorkDays(
    List<AttendanceRecord> history,
    DateTime now,
    Set<DateTime> deletedDays,
  ) {
    // Tập ngày đã có record (chỉ giữ ngày, bỏ giờ)
    final recorded = history
        .map((r) => DateTime(r.date.year, r.date.month, r.date.day))
        .toSet();

    final missing = <DateTime>[];
    final startOfMonth = DateTime(now.year, now.month, 1);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    // Nếu hôm nay là ngày 1 thì không có "hôm qua" trong tháng này
    if (yesterday.isBefore(startOfMonth)) return missing;

    var cursor = startOfMonth;
    while (!cursor.isAfter(yesterday)) {
      final isWeekend = cursor.weekday == DateTime.saturday ||
          cursor.weekday == DateTime.sunday;
      final dateOnly = DateTime(cursor.year, cursor.month, cursor.day);
      // Bỏ qua cuối tuần, ngày đã có record, và ngày đã bị xoá thủ công
      if (!isWeekend && !recorded.contains(dateOnly) && !deletedDays.contains(dateOnly)) {
        missing.add(dateOnly);
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return missing;
  }

  /// Gọi usecase để tạo record forgotPunch cho từng ngày bị thiếu.
  /// Lỗi từng record riêng lẻ sẽ bị bỏ qua (silent) để không block UI.
  Future<List<AttendanceRecord>> _autoMarkForgotPunch(
    List<DateTime> missingDays,
  ) async {
    final created = <AttendanceRecord>[];
    for (final day in missingDays) {
      try {
        final record = await _forgotPunchUseCase(
          userId: _userId,
          date: day,
          // checkIn/checkOut = 00:00 để đánh dấu "không có dữ liệu"
          checkIn: day,
          checkOut: day,
          reason: 'Tự động đánh dấu: không chấm công trong ngày làm việc',
        );
        created.add(record);
      } catch (_) {
        // Bỏ qua lỗi từng ngày, không block toàn bộ
      }
    }
    return created;
  }

  // ── Update time ─────────────────────────────────────────────────
  Future<void> _onUpdateTime(
    AttendanceUpdateTime event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
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

      final updatedHistory = state.history.map((record) {
        return record.id == event.recordId ? updated : record;
      }).toList();

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

  // ── Delete record ───────────────────────────────────────────────
  Future<void> _onDeleteRecord(
    AttendanceDeleteRecord event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      await _deleteUseCase(
        userId: _userId,
        recordId: event.recordId,
      );

      final updatedHistory =
          state.history.where((r) => r.id != event.recordId).toList();

      final newTodayRecord =
          state.todayRecord?.id == event.recordId ? null : state.todayRecord;

      double monthlyHours = 0;
      int workingDays = 0;
      for (final r in updatedHistory) {
        if (r.hoursWorked != null) monthlyHours += r.hoursWorked!;
        if (r.isActiveWorkDay) workingDays++;
      }

      emit(state.copyWith(
        todayRecord: newTodayRecord,
        history: updatedHistory,
        monthlyHours: monthlyHours,
        workingDays: workingDays,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AttendancePageStatus.error,
        errorMessage: 'Xoá thất bại: $e',
      ));
    }
  }

  // ── Mark day type (Nghỉ phép / NKL / WFH) ───────────────────────
  Future<void> _onMarkDayType(
    AttendanceMarkDayType event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      final record = await _markDayTypeUseCase(
        userId: _userId,
        status: event.dayType,
      );
      emit(_syncRecordToHistory(state, record));
    } catch (e) {
      emit(state.copyWith(
        status: AttendancePageStatus.error,
        errorMessage: 'Không thể cập nhật trạng thái: $e',
      ));
    }
  }
}
