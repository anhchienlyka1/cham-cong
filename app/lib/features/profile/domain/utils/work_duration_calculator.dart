/// Tính thời gian làm việc chính xác theo năm / tháng / ngày.
class WorkDurationCalculator {
  const WorkDurationCalculator._();

  /// Trả về `({int years, int months, int days})` khoảng cách
  /// từ [joinDate] đến [now].
  ///
  /// Nếu [joinDate] nằm trong tương lai, trả về tất cả = 0.
  static ({int years, int months, int days}) calculate(
    DateTime joinDate,
    DateTime now,
  ) {
    if (now.isBefore(joinDate)) return (years: 0, months: 0, days: 0);

    int years = now.year - joinDate.year;
    int months = now.month - joinDate.month;
    int days = now.day - joinDate.day;

    if (days < 0) {
      months -= 1;
      // Lấy số ngày còn lại của tháng trước
      final prevMonth = DateTime(now.year, now.month, 0); // ngày cuối tháng trước
      days += prevMonth.day;
    }

    if (months < 0) {
      years -= 1;
      months += 12;
    }

    return (years: years, months: months, days: days);
  }

  /// Trả về chuỗi hiển thị thân thiện, ví dụ: "1 năm 3 tháng 12 ngày".
  static String format(({int years, int months, int days}) duration) {
    final parts = <String>[];
    if (duration.years > 0) parts.add('${duration.years} năm');
    if (duration.months > 0) parts.add('${duration.months} tháng');
    parts.add('${duration.days} ngày');
    return parts.join(' ');
  }

  /// Trả về milestone tiếp theo (số năm) — 1, 2, 3, 5, 10, 15, 20 ...
  static int nextMilestone(int currentYears) {
    const milestones = [1, 2, 3, 5, 10, 15, 20, 25, 30];
    for (final m in milestones) {
      if (m > currentYears) return m;
    }
    return ((currentYears / 5).ceil() + 1) * 5;
  }
}
