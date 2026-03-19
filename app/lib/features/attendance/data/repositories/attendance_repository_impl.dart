import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/utils/shift_parser.dart';
import '../../domain/utils/work_hours_calculator.dart';
import '../models/attendance_record_model.dart';

/// Firestore implementation của [AttendanceRepository].
///
/// Đường dẫn collection:
///   attendance/{userId}/records/{recordId}
class AttendanceRepositoryImpl implements AttendanceRepository {
  final FirebaseFirestore _db;

  AttendanceRepositoryImpl({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _records(String userId) =>
      _db.collection('attendance').doc(userId).collection('records');

  // ──────────────────────────────────────────── getTodayRecord ──

  @override
  Future<AttendanceRecord?> getTodayRecord(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = _records(userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .limit(1);

    QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await query.get().timeout(const Duration(seconds: 5));
    } catch (_) {
      // Offline fallback: đọc từ cache
      snap = await query.get(const GetOptions(source: Source.cache));
    }

    if (snap.docs.isEmpty) return null;
    return AttendanceRecordModel.fromDoc(snap.docs.first);
  }

  // ──────────────────────────────────────────── getHistory ──────

  @override
  Future<List<AttendanceRecord>> getHistory({
    required String userId,
    required int month,
    required int year,
  }) async {
    final startOfMonth = DateTime(year, month);
    final endOfMonth = DateTime(year, month + 1);

    final query = _records(userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
        .orderBy('date', descending: true);

    QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await query.get().timeout(const Duration(seconds: 5));
    } catch (_) {
      // Offline fallback: đọc từ cache
      snap = await query.get(const GetOptions(source: Source.cache));
    }

    return snap.docs.map(AttendanceRecordModel.fromDoc).toList();
  }

  // ──────────────────────────────────────────── checkIn ─────────

  @override
  Future<AttendanceRecord> checkIn({
    required String userId,
    required DateTime time,
    required String location,
    String? lateReason,
  }) async {
    final date = DateTime(time.year, time.month, time.day);
    final status = time.isAfter(DateTime(date.year, date.month, date.day, 8, 30))
        ? AttendanceStatus.late
        : AttendanceStatus.present;

    final model = AttendanceRecordModel(
      id: '', // Firestore sẽ tự tạo ID
      date: date,
      checkIn: time,
      location: location,
      status: status,
      lateReason: lateReason,
      isLateFlag: status == AttendanceStatus.late,
    );

    final ref = await _records(userId).add(model.toFirestore());
    final snap = await ref.get();
    return AttendanceRecordModel.fromDoc(snap);
  }

  // ──────────────────────────────────────────── checkOut ────────

  @override
  Future<AttendanceRecord> checkOut({
    required String userId,
    required String recordId,
    required DateTime time,
    String? earlyLeaveReason,
  }) async {
    final ref = _records(userId).doc(recordId);
    final snap = await ref.get();
    if (!snap.exists) throw Exception('Record không tồn tại: $recordId');

    final existing = AttendanceRecordModel.fromDoc(snap);
    final checkInTime = existing.checkIn;
    double? hours;
    if (checkInTime != null) {
      hours = WorkHoursCalculator.calculate(checkInTime, time);
    }

    final updates = <String, dynamic>{
      'checkOut': Timestamp.fromDate(time),
      'hoursWorked': ?hours,
      'earlyLeaveReason': ?earlyLeaveReason,
    };

    // Nếu có earlyLeaveReason → là về sớm, cập nhật status
    if (earlyLeaveReason != null) {
      updates['status'] = 'earlyLeave';
      updates['isEarlyLeaveFlag'] = true;
    }

    await ref.update(updates);

    final updated = await ref.get();
    return AttendanceRecordModel.fromDoc(updated);
  }

  // ──────────────────────────────────────────── updateRecord ────

  @override
  Future<AttendanceRecord> updateRecord({
    required String userId,
    required String recordId,
    DateTime? checkIn,
    DateTime? checkOut,
    String? lateReason,
    String? earlyLeaveReason,
    String? note,
    TimeOfDay shiftStart = const TimeOfDay(hour: 8, minute: 30),
    TimeOfDay shiftEnd = const TimeOfDay(hour: 17, minute: 30),
  }) async {
    final ref = _records(userId).doc(recordId);
    final snap = await ref.get();
    final existing = AttendanceRecordModel.fromDoc(snap);

    final newCheckIn = checkIn ?? existing.checkIn;
    final newCheckOut = checkOut ?? existing.checkOut;

    // Tính lại hoursWorked
    double? hours;
    if (newCheckIn != null && newCheckOut != null) {
      hours = WorkHoursCalculator.calculate(newCheckIn, newCheckOut);
    }

    // Tính lại status flags dựa trên ca thực tế
    // actual end = shiftStart + 8h làm + 1.5h nghỉ trưa (ví dụ 8:30 → 18:00)
    final actualEnd = ShiftParser.actualShiftEnd(shiftStart);
    final isLate = ShiftParser.isLate(newCheckIn, shiftStart);
    final isEarly = ShiftParser.isEarlyLeave(newCheckOut, actualEnd);
    final primaryStatus = ShiftParser.calculatePrimaryStatus(
      checkIn: newCheckIn,
      checkOut: newCheckOut,
      shiftStart: shiftStart,
      shiftEnd: actualEnd,
    );

    final updates = <String, dynamic>{
      if (checkIn != null) 'checkIn': Timestamp.fromDate(checkIn),
      if (checkOut != null) 'checkOut': Timestamp.fromDate(checkOut),
      'hoursWorked': ?hours,
      'status': primaryStatus,
      'isLateFlag': isLate,
      'isEarlyLeaveFlag': isEarly,
    };

    // Cập nhật lý do (cho phép xóa bằng cách truyền null)
    if (isLate && lateReason != null) {
      updates['lateReason'] = lateReason;
    } else if (!isLate) {
      updates['lateReason'] = FieldValue.delete();
    }

    if (isEarly && earlyLeaveReason != null) {
      updates['earlyLeaveReason'] = earlyLeaveReason;
    } else if (!isEarly) {
      updates['earlyLeaveReason'] = FieldValue.delete();
    }

    // Ghi chú chung — chỉ cập nhật nếu được truyền vào
    if (note != null) {
      updates['note'] = note.isEmpty ? FieldValue.delete() : note;
    }

    await ref.update(updates);

    final updated = await ref.get();
    return AttendanceRecordModel.fromDoc(updated);
  }

  // ──────────────────────────────────────────── deleteRecord ────

  @override
  Future<void> deleteRecord({
    required String userId,
    required String recordId,
  }) async {
    await _records(userId).doc(recordId).delete();
  }

  // ──────────────────────────────────────────── submitForgotPunch ──

  @override
  Future<AttendanceRecord> submitForgotPunch({
    required String userId,
    required DateTime date,
    required DateTime checkIn,
    required DateTime checkOut,
    required String reason,
  }) async {
    // Khi auto-detect (checkIn == checkOut == date 00:00),
    // lưu null để UI không hiển thị giờ ảo.
    final isAutoDetect = checkIn.isAtSameMomentAs(checkOut) &&
        checkIn.isAtSameMomentAs(date);

    final model = AttendanceRecordModel(
      id: '',
      date: DateTime(date.year, date.month, date.day),
      checkIn: isAutoDetect ? null : checkIn,
      checkOut: isAutoDetect ? null : checkOut,
      hoursWorked: 0,
      status: AttendanceStatus.forgotPunch,
      note: reason,
      isLateFlag: false,
      isEarlyLeaveFlag: false,
    );

    final ref = await _records(userId).add(model.toFirestore());
    final snap = await ref.get();
    return AttendanceRecordModel.fromDoc(snap);
  }

  // ──────────────────────────────────────────── markDayType ────────

  @override
  Future<AttendanceRecord> markDayType({
    required String userId,
    required AttendanceStatus status,
  }) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Kiểm tra nếu đã có record hôm nay → update, ngược lại → tạo mới
    final existing = await _records(userId)
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      final docRef = existing.docs.first.reference;
      await docRef.update({'status': status.name});
      final updated = await docRef.get();
      return AttendanceRecordModel.fromDoc(updated);
    }

    // Tạo record mới
    final model = AttendanceRecordModel(
      id: '',
      date: startOfDay,
      hoursWorked: 0,
      status: status,
      isLateFlag: false,
      isEarlyLeaveFlag: false,
    );
    final ref = await _records(userId).add(model.toFirestore());
    final snap = await ref.get();
    return AttendanceRecordModel.fromDoc(snap);
  }
}

