import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/themes/app_colors.dart';
import '../../../../config/themes/app_text_styles.dart';
import '../../domain/entities/attendance_record.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_state.dart';
import '../widgets/edit_time_sheet.dart';

class AttendanceHistoryPage extends StatelessWidget {
  const AttendanceHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF07030),
                Color(0xFFE8601C),
                Color(0xFFE05818),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // ── Custom header ─────────────────────────────────────
                _buildHeader(context),

                // ── White curved panel with list ──────────────────────
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F6FA),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      child: BlocBuilder<AttendanceBloc, AttendanceState>(
                        builder: (context, state) {
                          if (state.status == AttendancePageStatus.loading) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            );
                          }

                          final records = state.history;
                          if (records.isEmpty) {
                            return _buildEmptyState();
                          }

                          return _buildList(context, records);
                        },
                      ),
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

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Text(
        'Lịch sử điểm danh',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_busy_rounded,
              size: 38,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có lịch sử điểm danh',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Các bản ghi chấm công sẽ hiển thị ở đây',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── List ────────────────────────────────────────────────────────────────────
  Widget _buildList(BuildContext context, List<AttendanceRecord> records) {
    // Group records by month-year
    final Map<String, List<AttendanceRecord>> grouped = {};
    for (final r in records) {
      final key = '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(r);
    }
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // newest first

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      itemCount: sortedKeys.length,
      itemBuilder: (context, i) {
        final key = sortedKeys[i];
        final monthRecords = grouped[key]!;
        final parts = key.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month separator
            _MonthSeparator(month: month, year: year, records: monthRecords),
            // Records
            ...monthRecords.map(
              (r) => _HistoryCard(
                record: r,
                onTap: () => _showEditSheet(context, r),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditSheet(BuildContext context, AttendanceRecord record) {
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
}

// ── Month Separator ──────────────────────────────────────────────────────────
class _MonthSeparator extends StatelessWidget {
  final int month;
  final int year;
  final List<AttendanceRecord> records;

  const _MonthSeparator({
    required this.month,
    required this.year,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    final totalDays = records.length;
    final presentDays = records
        .where((r) => r.isActiveWorkDay)
        .length;

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF07030), AppColors.primary],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_month_rounded,
                    size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  'Tháng $month/$year',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$presentDays/$totalDays ngày',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(color: AppColors.divider, thickness: 1),
          ),
        ],
      ),
    );
  }
}

// ── History card ─────────────────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final AttendanceRecord record;
  final VoidCallback onTap;

  const _HistoryCard({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _statusInfo(record.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: statusInfo.color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // ── Left status strip ──────────────────────────────
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        statusInfo.color,
                        statusInfo.color.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),

                // ── Main content ───────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: date info + status badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Day number with weekday
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      record.dayOfWeek,
                                      style: AppTextStyles.labelLarge.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 9, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${record.date.day}/${record.date.month}',
                                        style:
                                            AppTextStyles.labelSmall.copyWith(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Spacer(),
                            // Status badge
                            _StatusBadge(status: record.status),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Bottom row: time info + total hours
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              // Check in
                              _TimeBlock(
                                label: 'Vào',
                                time: record.formattedCheckIn,
                                icon: Icons.login_rounded,
                                iconColor: AppColors.success,
                              ),

                              // Divider/Arrow
                              Expanded(
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(
                                        5,
                                        (index) => Container(
                                          width: 5,
                                          height: 2,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.textHint
                                                .withValues(alpha: 0.6),
                                            borderRadius:
                                                BorderRadius.circular(1),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 10,
                                      color: AppColors.textHint
                                          .withValues(alpha: 0.6),
                                    ),
                                  ],
                                ),
                              ),

                              // Check out
                              _TimeBlock(
                                label: 'Ra',
                                time: record.formattedCheckOut,
                                icon: Icons.logout_rounded,
                                iconColor: AppColors.error,
                                alignRight: true,
                              ),

                              // Vertical divider
                              Container(
                                width: 1,
                                height: 32,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                color: AppColors.divider,
                              ),

                              // Total hours
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Tổng',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    record.formattedHours,
                                    style: AppTextStyles.labelLarge.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Chevron ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _StatusInfo _statusInfo(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return _StatusInfo(AppColors.success);
      case AttendanceStatus.late:
        return _StatusInfo(AppColors.warning);
      case AttendanceStatus.absent:
        return _StatusInfo(AppColors.error);
      case AttendanceStatus.halfDay:
        return _StatusInfo(AppColors.info);
      case AttendanceStatus.onLeave:
        return _StatusInfo(const Color(0xFF06B6D4));
      case AttendanceStatus.earlyLeave:
        return _StatusInfo(const Color(0xFF3B82F6));
      case AttendanceStatus.sickLeave:
        return _StatusInfo(const Color(0xFFF97316));
      case AttendanceStatus.businessTrip:
        return _StatusInfo(const Color(0xFF78716C));
      case AttendanceStatus.workFromHome:
        return _StatusInfo(const Color(0xFF10B981));
      case AttendanceStatus.holiday:
        return _StatusInfo(const Color(0xFFF43F5E));
      case AttendanceStatus.overtime:
        return _StatusInfo(const Color(0xFF7C3AED));
      case AttendanceStatus.forgotPunch:
        return _StatusInfo(const Color(0xFF6B7280));
    }
  }
}

class _StatusInfo {
  final Color color;
  const _StatusInfo(this.color);
}

// ── Time block ───────────────────────────────────────────────────────────────
class _TimeBlock extends StatelessWidget {
  final String label;
  final String time;
  final IconData icon;
  final Color iconColor;
  final bool alignRight;

  const _TimeBlock({
    required this.label,
    required this.time,
    required this.icon,
    required this.iconColor,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!alignRight) ...[
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            if (alignRight) ...[
              const SizedBox(width: 5),
              Icon(icon, size: 14, color: iconColor),
            ],
          ],
        ),
        const SizedBox(height: 3),
        Text(
          time,
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}

// ── Status badge ─────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final AttendanceStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status) {
      case AttendanceStatus.present:
        bg = AppColors.success.withValues(alpha: 0.12);
        fg = AppColors.success;
        label = 'Có mặt';
        icon = Icons.check_circle_outline_rounded;
        break;
      case AttendanceStatus.late:
        bg = AppColors.warning.withValues(alpha: 0.12);
        fg = AppColors.warning;
        label = 'Đi muộn';
        icon = Icons.schedule_rounded;
        break;
      case AttendanceStatus.absent:
        bg = AppColors.error.withValues(alpha: 0.12);
        fg = AppColors.error;
        label = 'Vắng';
        icon = Icons.cancel_outlined;
        break;
      case AttendanceStatus.halfDay:
        bg = AppColors.info.withValues(alpha: 0.12);
        fg = AppColors.info;
        label = 'Nửa ngày';
        icon = Icons.timelapse_rounded;
        break;
      case AttendanceStatus.onLeave:
        bg = const Color(0xFF06B6D4).withValues(alpha: 0.12);
        fg = const Color(0xFF06B6D4);
        label = 'Nghỉ phép';
        icon = Icons.beach_access_rounded;
        break;
      case AttendanceStatus.earlyLeave:
        bg = const Color(0xFF3B82F6).withValues(alpha: 0.12);
        fg = const Color(0xFF3B82F6);
        label = 'Về sớm';
        icon = Icons.directions_run_rounded;
        break;
      case AttendanceStatus.sickLeave:
        bg = const Color(0xFFF97316).withValues(alpha: 0.12);
        fg = const Color(0xFFF97316);
        label = 'Nghỉ ốm';
        icon = Icons.local_hospital_rounded;
        break;
      case AttendanceStatus.businessTrip:
        bg = const Color(0xFF78716C).withValues(alpha: 0.12);
        fg = const Color(0xFF78716C);
        label = 'Công tác';
        icon = Icons.flight_takeoff_rounded;
        break;
      case AttendanceStatus.workFromHome:
        bg = const Color(0xFF10B981).withValues(alpha: 0.12);
        fg = const Color(0xFF10B981);
        label = 'WFH';
        icon = Icons.home_work_rounded;
        break;
      case AttendanceStatus.holiday:
        bg = const Color(0xFFF43F5E).withValues(alpha: 0.12);
        fg = const Color(0xFFF43F5E);
        label = 'Nghỉ lễ';
        icon = Icons.celebration_rounded;
        break;
      case AttendanceStatus.overtime:
        bg = const Color(0xFF7C3AED).withValues(alpha: 0.12);
        fg = const Color(0xFF7C3AED);
        label = 'Tăng ca';
        icon = Icons.more_time_rounded;
        break;
      case AttendanceStatus.forgotPunch:
        bg = const Color(0xFF6B7280).withValues(alpha: 0.12);
        fg = const Color(0xFF6B7280);
        label = 'Quên CC';
        icon = Icons.help_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
