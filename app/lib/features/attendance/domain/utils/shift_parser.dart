import 'package:flutter/material.dart';

/// Utility to parse shift string (e.g. "8:30 - 17:30") into TimeOfDay pairs.
///
/// Fallback defaults: 8:30 – 17:30 if the shift string is null or invalid.
class ShiftParser {
  static const _defaultStart = TimeOfDay(hour: 8, minute: 30);
  static const _defaultEnd = TimeOfDay(hour: 17, minute: 30);

  /// Parse a shift string like "8:30 - 17:30" into (start, end).
  static (TimeOfDay start, TimeOfDay end) parse(String? shift) {
    if (shift == null || shift.isEmpty) return (_defaultStart, _defaultEnd);

    final parts = shift.split('-').map((s) => s.trim()).toList();
    if (parts.length != 2) return (_defaultStart, _defaultEnd);

    final start = _parseTime(parts[0]);
    final end = _parseTime(parts[1]);
    if (start == null || end == null) return (_defaultStart, _defaultEnd);

    return (start, end);
  }

  static TimeOfDay? _parseTime(String s) {
    final segments = s.split(':');
    if (segments.length != 2) return null;
    final h = int.tryParse(segments[0]);
    final m = int.tryParse(segments[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  /// Check if [checkIn] is after [shiftStart] (= late).
  static bool isLate(DateTime? checkIn, TimeOfDay shiftStart) {
    if (checkIn == null) return false;
    final cutoff = DateTime(
      checkIn.year, checkIn.month, checkIn.day,
      shiftStart.hour, shiftStart.minute,
    );
    return checkIn.isAfter(cutoff);
  }

  /// Check if [checkOut] is before [shiftEnd] (= early leave).
  static bool isEarlyLeave(DateTime? checkOut, TimeOfDay shiftEnd) {
    if (checkOut == null) return false;
    final cutoff = DateTime(
      checkOut.year, checkOut.month, checkOut.day,
      shiftEnd.hour, shiftEnd.minute,
    );
    return checkOut.isBefore(cutoff);
  }

  /// Determine the primary status based on shift times.
  static String calculatePrimaryStatus({
    required DateTime? checkIn,
    required DateTime? checkOut,
    required TimeOfDay shiftStart,
    required TimeOfDay shiftEnd,
  }) {
    if (checkIn == null) return 'absent';

    final late = isLate(checkIn, shiftStart);
    final early = checkOut != null ? isEarlyLeave(checkOut, shiftEnd) : false;

    // Detect overtime: check-out > shiftEnd + 2 giờ
    if (checkOut != null) {
      final otCutoff = DateTime(
        checkOut.year, checkOut.month, checkOut.day,
        shiftEnd.hour + 2, shiftEnd.minute,
      );
      if (checkOut.isAfter(otCutoff)) return 'overtime';
    }

    if (late && early) return 'late'; // Priority: late
    if (late) return 'late';
    if (early) return 'earlyLeave';
    return 'present';
  }
}
