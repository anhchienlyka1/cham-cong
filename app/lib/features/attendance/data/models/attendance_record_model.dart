import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/attendance_record.dart';

/// Data model – ánh xạ giữa Firestore document và [AttendanceRecord].
class AttendanceRecordModel extends AttendanceRecord {
  const AttendanceRecordModel({
    required super.id,
    required super.date,
    super.checkIn,
    super.checkOut,
    super.location,
    super.hoursWorked,
    super.status,
    super.lateReason,
    super.earlyLeaveReason,
  });

  /// Chuyển Firestore document → model
  factory AttendanceRecordModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceRecordModel(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      checkIn: (data['checkIn'] as Timestamp?)?.toDate(),
      checkOut: (data['checkOut'] as Timestamp?)?.toDate(),
      location: data['location'] as String?,
      hoursWorked: (data['hoursWorked'] as num?)?.toDouble(),
      status: _statusFromString(data['status'] as String? ?? 'absent'),
      lateReason: data['lateReason'] as String?,
      earlyLeaveReason: data['earlyLeaveReason'] as String?,
    );
  }

  /// Chuyển model → Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      if (checkIn != null) 'checkIn': Timestamp.fromDate(checkIn!),
      if (checkOut != null) 'checkOut': Timestamp.fromDate(checkOut!),
      if (location != null) 'location': location,
      if (hoursWorked != null) 'hoursWorked': hoursWorked,
      'status': _statusToString(status),
      if (lateReason != null) 'lateReason': lateReason,
      if (earlyLeaveReason != null) 'earlyLeaveReason': earlyLeaveReason,
    };
  }

  static AttendanceStatus _statusFromString(String s) {
    return AttendanceStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => AttendanceStatus.absent,
    );
  }

  static String _statusToString(AttendanceStatus status) => status.name;
}
