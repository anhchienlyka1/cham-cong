import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/themes/app_colors.dart';
import '../../domain/entities/attendance_record.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_state.dart';

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
          return _EdgeSwipeBack(
            child: Scaffold(
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
  List<AttendanceRecord> _recordsForMonth(AttendanceState state) {
    final all = <AttendanceRecord>[];
    if (state.todayRecord != null) all.add(state.todayRecord!);
    all.addAll(state.history);

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
                const Spacer(),
                // Legend
                _LegendDot(color: const Color(0xFF22C55E), label: 'Đúng giờ'),
                const SizedBox(width: 8),
                _LegendDot(color: const Color(0xFFF59E0B), label: 'Muộn'),
                const SizedBox(width: 8),
                _LegendDot(color: const Color(0xFFEF4444), label: 'Vắng'),
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

                  Color circleColor;
                  if (isFuture || isWeekend) {
                    circleColor = const Color(0xFFE5E7EB);
                  } else if (status == AttendanceStatus.present) {
                    circleColor = const Color(0xFF22C55E);
                  } else if (status == AttendanceStatus.late) {
                    circleColor = const Color(0xFFF59E0B);
                  } else if (status == AttendanceStatus.absent) {
                    circleColor = const Color(0xFFEF4444);
                  } else if (status == AttendanceStatus.onLeave) {
                    circleColor = const Color(0xFF3B82F6);
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
                                color: (isFuture || isWeekend || status == null)
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

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
        ),
      ],
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
              itemBuilder: (_, i) => _DayTile(record: records[i]),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  final AttendanceRecord record;
  const _DayTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final (accentColor, badgeLabel, badgeColor) = _statusInfo(record.status);

    // Format hours like "8h 30m"
    String hoursLabel = '0h';
    if (record.hoursWorked != null && record.hoursWorked! > 0) {
      final h = record.hoursWorked!.floor();
      final m = ((record.hoursWorked! - h) * 60).round();
      hoursLabel = m > 0 ? '${h}h ${m}m' : '${h}h';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent bar
            Container(
              width: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    // Date
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
                    // Check-in / check-out
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
                    // Hours
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
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badgeLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ),
          ],
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
        return (const Color(0xFF3B82F6), 'Nghỉ phép', const Color(0xFF3B82F6));
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

// ─────────────────────────────────────────────────────────────────────────────
// Edge Swipe Back Gesture
// ─────────────────────────────────────────────────────────────────────────────
class _EdgeSwipeBack extends StatefulWidget {
  final Widget child;
  const _EdgeSwipeBack({required this.child});

  @override
  State<_EdgeSwipeBack> createState() => _EdgeSwipeBackState();
}

class _EdgeSwipeBackState extends State<_EdgeSwipeBack> {
  bool _isEdgeSwipe = false;
  double _dragDistance = 0;

  static const _edgeWidth = 40.0;
  static const _dragThreshold = 80.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (details) {
        final dx = details.globalPosition.dx;
        final screenWidth = MediaQuery.sizeOf(context).width;
        // Detect swipe starting from left or right edge
        _isEdgeSwipe = dx < _edgeWidth || dx > screenWidth - _edgeWidth;
        _dragDistance = 0;
      },
      onHorizontalDragUpdate: (details) {
        if (!_isEdgeSwipe) return;
        _dragDistance += details.delta.dx.abs();
      },
      onHorizontalDragEnd: (details) {
        if (!_isEdgeSwipe) return;
        final velocity = details.primaryVelocity ?? 0;
        // Pop if dragged enough distance or fast enough
        if (_dragDistance > _dragThreshold || velocity.abs() > 800) {
          HapticFeedback.lightImpact();
          Navigator.maybePop(context);
        }
        _isEdgeSwipe = false;
        _dragDistance = 0;
      },
      child: widget.child,
    );
  }
}
