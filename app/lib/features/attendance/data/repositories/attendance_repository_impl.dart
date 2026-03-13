import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';
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
      final totalMin = time.difference(checkInTime).inMinutes - 90; // trừ 90 phút nghỉ
      hours = totalMin / 60.0;
    }

    final updates = <String, dynamic>{
      'checkOut': Timestamp.fromDate(time),
      if (hours != null) 'hoursWorked': hours,
      if (earlyLeaveReason != null) 'earlyLeaveReason': earlyLeaveReason,
    };
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
  }) async {
    final ref = _records(userId).doc(recordId);
    final snap = await ref.get();
    final existing = AttendanceRecordModel.fromDoc(snap);

    final newCheckIn = checkIn ?? existing.checkIn;
    final newCheckOut = checkOut ?? existing.checkOut;
    double? hours;
    if (newCheckIn != null && newCheckOut != null) {
      final totalMin = newCheckOut.difference(newCheckIn).inMinutes - 90;
      hours = totalMin / 60.0;
    }

    final updates = <String, dynamic>{
      if (checkIn != null) 'checkIn': Timestamp.fromDate(checkIn),
      if (checkOut != null) 'checkOut': Timestamp.fromDate(checkOut),
      if (hours != null) 'hoursWorked': hours,
    };
    await ref.update(updates);

    final updated = await ref.get();
    return AttendanceRecordModel.fromDoc(updated);
  }
}
