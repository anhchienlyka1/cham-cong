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
                      color: Color(0xFFF9FAFB),
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
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF07030), AppColors.primary],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Tháng $month/$year',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Divider(
                      color: AppColors.divider,
                      thickness: 1,
                    ),
                  ),
                ],
              ),
            ),
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



// ── History card ─────────────────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final AttendanceRecord record;
  final VoidCallback onTap;

  const _HistoryCard({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          splashColor: AppColors.primarySurface,
          highlightColor: AppColors.primarySurface.withValues(alpha: 0.6),
          child: Row(
            children: [
              // Left accent bar
              Container(
                width: 4,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: _accentColors(record.status),
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),

              // Date badge
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  width: 48,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        record.date.day.toString(),
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        _monthShort(record.date.month),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            record.dayOfWeek,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          _StatusBadge(status: record.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _TimeChip(
                            icon: Icons.login_rounded,
                            time: record.formattedCheckIn,
                            color: AppColors.success,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                          _TimeChip(
                            icon: Icons.logout_rounded,
                            time: record.formattedCheckOut,
                            color: AppColors.error,
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              record.formattedHours,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Chevron
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
    );
  }

  List<Color> _accentColors(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return [AppColors.success, Color(0xFF6EE7B7)];
      case AttendanceStatus.late:
        return [AppColors.warning, Color(0xFFFDE68A)];
      case AttendanceStatus.absent:
        return [AppColors.error, Color(0xFFFCA5A5)];
      case AttendanceStatus.halfDay:
        return [AppColors.info, Color(0xFF93C5FD)];
      case AttendanceStatus.onLeave:
        return [AppColors.secondary, Color(0xFFC4B5FD)];
    }
  }

  String _monthShort(int month) {
    const months = [
      'Th1', 'Th2', 'Th3', 'Th4', 'Th5', 'Th6',
      'Th7', 'Th8', 'Th9', 'Th10', 'Th11', 'Th12',
    ];
    return months[month - 1];
  }
}

// ── Time chip ────────────────────────────────────────────────────────────────
class _TimeChip extends StatelessWidget {
  final IconData icon;
  final String time;
  final Color color;

  const _TimeChip({
    required this.icon,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          time,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
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
        bg = AppColors.secondary.withValues(alpha: 0.12);
        fg = AppColors.secondary;
        label = 'Nghỉ phép';
        icon = Icons.beach_access_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
