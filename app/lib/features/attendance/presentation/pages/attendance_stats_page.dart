import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/themes/app_colors.dart';
import '../../domain/entities/attendance_record.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_state.dart';
import '../widgets/edit_time_sheet.dart';

class AttendanceStatsPage extends StatefulWidget {
  const AttendanceStatsPage({super.key});

  @override
  State<AttendanceStatsPage> createState() => _AttendanceStatsPageState();
}

class _AttendanceStatsPageState extends State<AttendanceStatsPage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _prevMonth() =>
      setState(() => _month = DateTime(_month.year, _month.month - 1));

  void _nextMonth() {
    final next = DateTime(_month.year, _month.month + 1);
    if (!next.isAfter(DateTime.now())) {
      setState(() => _month = next);
    }
  }

  bool get _canGoNext =>
      !DateTime(_month.year, _month.month + 1).isAfter(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: BlocBuilder<AttendanceBloc, AttendanceState>(
        builder: (context, state) {
          final records = _recordsForMonth(state);
          return Scaffold(
            backgroundColor: const Color(0xFFF07030),
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(context),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9FAFB),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _CalendarHeatmap(month: _month, records: records),
                        const SizedBox(height: 20),
                        _DayList(records: records),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    const months = [
      'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4',
      'Tháng 5', 'Tháng 6', 'Tháng 7', 'Tháng 8',
      'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12',
    ];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF07030), Color(0xFFE05818)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Row(
            children: [
              // Prev month
              IconButton(
                onPressed: _prevMonth,
                icon: Icon(
                  Icons.chevron_left_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 26,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              // Month label
              Expanded(
                child: Text(
                  '${months[_month.month - 1]}, ${_month.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              // Next month
              IconButton(
                onPressed: _canGoNext ? _nextMonth : null,
                icon: Icon(
                  Icons.chevron_right_rounded,
                  color: _canGoNext
                      ? Colors.white.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.3),
                  size: 26,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ghép history + todayRecord, lọc theo tháng đang xem.
  /// Tránh trùng lặp: chỉ thêm todayRecord nếu chưa tồn tại trong history.
  List<AttendanceRecord> _recordsForMonth(AttendanceState state) {
    final all = <AttendanceRecord>[];

    // Thêm tất cả history trước
    all.addAll(state.history);

    // Chỉ thêm todayRecord nếu ID chưa có trong history
    if (state.todayRecord != null) {
      final alreadyExists = all.any((r) => r.id == state.todayRecord!.id);
      if (!alreadyExists) {
        all.add(state.todayRecord!);
      }
    }

    return all.where((r) {
      return r.date.year == _month.year && r.date.month == _month.month;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Calendar heatmap
// ─────────────────────────────────────────────────────────────────────────────
class _CalendarHeatmap extends StatelessWidget {
  final DateTime month;
  final List<AttendanceRecord> records;

  const _CalendarHeatmap({required this.month, required this.records});

  @override
  Widget build(BuildContext context) {
    // Map ngày → status
    final Map<int, AttendanceStatus> dayMap = {};
    for (final r in records) {
      dayMap[r.date.day] = r.status;
    }

    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstWeekday = DateTime(month.year, month.month, 1).weekday; // 1=Mon
    // Pad to start on Monday (index 0)
    final leadingBlanks = (firstWeekday - 1) % 7;
    final totalCells = leadingBlanks + daysInMonth;
    final rows = (totalCells / 7).ceil();

    const weekLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title
            Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFF07030), AppColors.primary],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Lịch điểm danh',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Week labels
            Row(
              children: weekLabels.map((d) {
                final isWeekend = d == 'T7' || d == 'CN';
                return Expanded(
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isWeekend
                          ? const Color(0xFFEF4444).withValues(alpha: 0.7)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 6),

            // Grid
            for (int row = 0; row < rows; row++) ...[
              Row(
                children: List.generate(7, (col) {
                  final cellIndex = row * 7 + col;
                  final dayNum = cellIndex - leadingBlanks + 1;
                  final isBlank = cellIndex < leadingBlanks || dayNum > daysInMonth;
                  if (isBlank) {
                    return const Expanded(child: SizedBox(height: 32));
                  }
                  final isWeekend = col >= 5; // T7, CN
                  final today = DateTime.now();
                  final isFuture = DateTime(month.year, month.month, dayNum)
                      .isAfter(DateTime(today.year, today.month, today.day));
                  final status = dayMap[dayNum];

                  // ── Weekend (ngày nghỉ theo quy định) ──
                  if (isWeekend) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF94A3B8).withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  '$dayNum',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                // Small "day off" indicator at top-right
                                Positioned(
                                  top: 1,
                                  right: 1,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF94A3B8),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.nightlight_round,
                                      size: 7,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  // ── Weekday ──
                  Color circleColor;
                  if (isFuture) {
                    circleColor = const Color(0xFFE5E7EB);
                  } else if (status == AttendanceStatus.present) {
                    circleColor = const Color(0xFF22C55E);
                  } else if (status == AttendanceStatus.late) {
                    circleColor = const Color(0xFFF59E0B);
                  } else if (status == AttendanceStatus.absent) {
                    circleColor = const Color(0xFFEF4444);
                  } else if (status == AttendanceStatus.earlyLeave) {
                    circleColor = const Color(0xFF3B82F6);
                  } else if (status == AttendanceStatus.onLeave) {
                    circleColor = const Color(0xFF06B6D4);
                  } else if (status == AttendanceStatus.sickLeave) {
                    circleColor = const Color(0xFFF97316);
                  } else if (status == AttendanceStatus.businessTrip) {
                    circleColor = const Color(0xFF78716C);
                  } else if (status == AttendanceStatus.workFromHome) {
                    circleColor = const Color(0xFF10B981);
                  } else if (status == AttendanceStatus.holiday) {
                    circleColor = const Color(0xFFF43F5E);
                  } else if (status == AttendanceStatus.overtime) {
                    circleColor = const Color(0xFF7C3AED);
                  } else if (status == AttendanceStatus.forgotPunch) {
                    circleColor = const Color(0xFF6B7280);
                  } else {
                    // Weekday without record
                    circleColor = const Color(0xFFE5E7EB);
                  }

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: circleColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$dayNum',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: (isFuture || status == null)
                                    ? const Color(0xFF9CA3AF)
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 2),
            ],
          ],
        ),
      ),
    );
  }
}




// ─────────────────────────────────────────────────────────────────────────────
// Day-by-day list
// ─────────────────────────────────────────────────────────────────────────────
class _DayList extends StatelessWidget {
  final List<AttendanceRecord> records;

  const _DayList({required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Center(
          child: Text(
            'Chưa có dữ liệu trong tháng này',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFF07030), AppColors.primary],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Chi tiết từng ngày',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: records.length,
              separatorBuilder: (context, _) => const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: Color(0xFFF3F4F6),
              ),
              itemBuilder: (ctx, i) => _DayTile(
                record: records[i],
                onTap: () => _openEditSheet(ctx, records[i]),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

void _openEditSheet(BuildContext context, AttendanceRecord record) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<AttendanceBloc>(),
      child: EditTimeSheet(record: record),
    ),
  );
}

class _DayTile extends StatelessWidget {
  final AttendanceRecord record;
  final VoidCallback? onTap;

  const _DayTile({required this.record, this.onTap});

  @override
  Widget build(BuildContext context) {
    final (accentColor, _, __) = _statusInfo(record.status);

    // Format hours
    String hoursLabel = '0h';
    if (record.hoursWorked != null && record.hoursWorked! > 0) {
      final h = record.hoursWorked!.floor();
      final m = ((record.hoursWorked! - h) * 60).round();
      hoursLabel = m > 0 ? '${h}h ${m}m' : '${h}h';
    }

    // Status badges
    final badges = <Widget>[];
    if (record.isLateFlag) {
      badges.add(_buildBadge('Muộn', const Color(0xFFF59E0B)));
    }
    if (record.isEarlyLeaveFlag) {
      badges.add(_buildBadge('Về sớm', const Color(0xFF3B82F6)));
    }
    if (badges.isEmpty) {
      final (_, badgeLabel, badgeColor) = _statusInfo(record.status);
      badges.add(_buildBadge(badgeLabel, badgeColor));
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: accentColor.withValues(alpha: 0.08),
      highlightColor: accentColor.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            record.dayOfWeek,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${record.date.day}/${record.date.month}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          _TimeChip(
                            icon: Icons.login_rounded,
                            time: record.formattedCheckIn,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 12,
                              color: Color(0xFFD1D5DB),
                            ),
                          ),
                          _TimeChip(
                            icon: Icons.logout_rounded,
                            time: record.formattedCheckOut,
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            hoursLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            alignment: WrapAlignment.end,
                            children: badges,
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFFD1D5DB),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  (Color, String, Color) _statusInfo(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return (const Color(0xFF22C55E), 'Đúng giờ', const Color(0xFF22C55E));
      case AttendanceStatus.late:
        return (const Color(0xFFF59E0B), 'Muộn', const Color(0xFFF59E0B));
      case AttendanceStatus.absent:
        return (const Color(0xFFEF4444), 'Vắng', const Color(0xFFEF4444));
      case AttendanceStatus.halfDay:
        return (const Color(0xFF8B5CF6), 'Nửa ngày', const Color(0xFF8B5CF6));
      case AttendanceStatus.onLeave:
        return (const Color(0xFF06B6D4), 'Nghỉ phép', const Color(0xFF06B6D4));
      case AttendanceStatus.earlyLeave:
        return (const Color(0xFF3B82F6), 'Về sớm', const Color(0xFF3B82F6));
      case AttendanceStatus.sickLeave:
        return (const Color(0xFFF97316), 'Nghỉ ốm', const Color(0xFFF97316));
      case AttendanceStatus.businessTrip:
        return (const Color(0xFF78716C), 'Công tác', const Color(0xFF78716C));
      case AttendanceStatus.workFromHome:
        return (const Color(0xFF10B981), 'WFH', const Color(0xFF10B981));
      case AttendanceStatus.holiday:
        return (const Color(0xFFF43F5E), 'Nghỉ lễ', const Color(0xFFF43F5E));
      case AttendanceStatus.overtime:
        return (const Color(0xFF7C3AED), 'Tăng ca', const Color(0xFF7C3AED));
      case AttendanceStatus.forgotPunch:
        return (const Color(0xFF6B7280), 'Quên CC', const Color(0xFF6B7280));
    }
  }
}

class _TimeChip extends StatelessWidget {
  final IconData icon;
  final String time;
  const _TimeChip({required this.icon, required this.time});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 10, color: const Color(0xFF9CA3AF)),
        const SizedBox(height: 2),
        Text(
          time,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
      ],
    );
  }
}

