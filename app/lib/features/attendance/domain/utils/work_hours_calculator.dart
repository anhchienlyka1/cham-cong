/// Utility class to calculate actual working hours with smart lunch break deduction.
///
/// Lunch break: 12:00 – 13:30 (90 minutes).
/// Only the overlapping portion between work time and lunch break is deducted.
class WorkHoursCalculator {
  /// Lunch break start: 12:00
  static const int lunchStartHour = 12;
  static const int lunchStartMinute = 0;

  /// Lunch break end: 13:30
  static const int lunchEndHour = 13;
  static const int lunchEndMinute = 30;

  /// Calculate the number of working hours between [checkIn] and [checkOut],
  /// automatically deducting only the overlapping lunch break time.
  ///
  /// Returns hours as a double (e.g., 7.5 for 7h 30m).
  static double calculate(DateTime checkIn, DateTime checkOut) {
    final totalMinutes = checkOut.difference(checkIn).inMinutes;
    final lunchDeduction = _lunchOverlapMinutes(checkIn, checkOut);
    return (totalMinutes - lunchDeduction) / 60.0;
  }

  /// Calculate how many minutes of the lunch break overlap with [start]–[end].
  ///
  /// Returns 0 if there's no overlap.
  static int _lunchOverlapMinutes(DateTime start, DateTime end) {
    // Build lunch window on the same day as checkIn
    final lunchStart = DateTime(
      start.year,
      start.month,
      start.day,
      lunchStartHour,
      lunchStartMinute,
    );
    final lunchEnd = DateTime(
      start.year,
      start.month,
      start.day,
      lunchEndHour,
      lunchEndMinute,
    );

    // Calculate overlap: max(0, min(end, lunchEnd) - max(start, lunchStart))
    final overlapStart = start.isAfter(lunchStart) ? start : lunchStart;
    final overlapEnd = end.isBefore(lunchEnd) ? end : lunchEnd;

    if (overlapStart.isBefore(overlapEnd)) {
      return overlapEnd.difference(overlapStart).inMinutes;
    }
    return 0; // No overlap
  }
}
