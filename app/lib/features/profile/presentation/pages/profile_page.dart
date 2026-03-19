import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../config/themes/app_colors.dart';
import '../../../../config/themes/app_text_styles.dart';
import '../../../../core/services/notification_service.dart';
import '../../../attendance/domain/utils/shift_parser.dart';
import '../../../attendance/presentation/bloc/attendance_bloc.dart';
import '../../../attendance/presentation/bloc/attendance_state.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../widgets/user_avatar_widget.dart';
import 'attendance_status_settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Ca làm việc: '8:00', '8:30', '9:00'
  String _selectedShift = '8:00';

  /// Lưu ca làm việc lên Firestore
  Future<void> _saveShiftToFirestore(String shift) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'shift': shift});
    } catch (e) {
      // Nếu document chưa tồn tại, tạo mới với merge
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'shift': shift}, SetOptions(merge: true));
    }
  }

  void _pickShift() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShiftPickerSheet(
        selected: _selectedShift,
        onPick: (v) async {
          setState(() => _selectedShift = v);
          _saveShiftToFirestore(v);
          // Cập nhật user state trong AuthBloc
          if (mounted) context.read<AuthBloc>().add(AuthShiftUpdated(shift: v));
          // Đặt lại thông báo theo ca mới (nhắc trước 5 phút đầu/cuối ca)
          await NotificationService.rescheduleForShift(
            shiftStart: v,
            shiftEnd: ShiftParser.endTime(v),
          );
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _openStatusSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AttendanceStatusSettingsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF07030),
        body: BlocListener<AuthBloc, AuthState>(
          listenWhen: (prev, curr) =>
              prev.user?.shift != curr.user?.shift,
          listener: (context, authState) {
            final shift = authState.user?.shift;
            if (shift != null && shift.isNotEmpty && shift != _selectedShift) {
              setState(() => _selectedShift = shift);
            }
          },
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              // Đồng bộ shift từ AuthBloc vào biến local (cho lần build đầu tiên)
              final userShift = authState.user?.shift;
              if (userShift != null && userShift.isNotEmpty && userShift != _selectedShift) {
                // Schedule microtask để tránh setState trong build
                Future.microtask(() {
                  if (mounted) setState(() => _selectedShift = userShift);
                });
              }
              return BlocBuilder<AttendanceBloc, AttendanceState>(
                builder: (context, attendanceState) {
                  return _ProfileBody(
                    state: attendanceState,
                    user: authState.user,
                    selectedShift: _selectedShift,
                    onPickShift: _pickShift,
                    onOpenStatusSettings: _openStatusSettings,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Main scrollable body ─────────────────────────────────────────────────────
class _ProfileBody extends StatelessWidget {
  final AttendanceState state;
  final UserEntity? user;
  final String selectedShift;
  final VoidCallback onPickShift;
  final VoidCallback onOpenStatusSettings;

  const _ProfileBody({
    required this.state,
    required this.user,
    required this.selectedShift,
    required this.onPickShift,
    required this.onOpenStatusSettings,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Gradient header (avatar + name + status)
        SliverToBoxAdapter(child: _buildHeader()),

        // White curved panel — all content lives here
        SliverFillRemaining(
          hasScrollBody: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildMonthlyStats(context, state),
                const SizedBox(height: 16),
                _buildSectionCard(
                  label: 'Thông tin cá nhân',
                  children: [
                    _InfoTile(
                      icon: Icons.badge_rounded,
                      iconColor: AppColors.primary,
                      label: 'Mã nhân viên',
                      value: user?.employeeId ?? '—',
                    ),
                    _InfoTile(
                      icon: Icons.business_center_rounded,
                      iconColor: AppColors.info,
                      label: 'Phòng ban',
                      value: user?.department ?? '—',
                    ),
                    _InfoTile(
                      icon: Icons.work_rounded,
                      iconColor: AppColors.secondary,
                      label: 'Chức vụ',
                      value: user?.position ?? '—',
                    ),
                    _InfoTile(
                      icon: Icons.phone_rounded,
                      iconColor: AppColors.success,
                      label: 'Số điện thoại',
                      value: user?.phoneNumber ?? '—',
                    ),
                    _InfoTile(
                      icon: Icons.location_on_rounded,
                      iconColor: AppColors.warning,
                      label: 'Địa điểm làm việc',
                      value: user?.workLocation ?? '—',
                      isLast: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  label: 'Cài đặt',
                  children: [
                    // Ca làm việc
                    _ShiftTile(
                      selected: selectedShift,
                      onTap: onPickShift,
                    ),
                    // Quản lý trạng thái chấm công
                    _SettingsTile(
                      icon: Icons.assignment_turned_in_rounded,
                      iconColor: const Color(0xFF6366F1),
                      label: 'Quản lý trạng thái',
                      subtitle: 'Đúng giờ, đi muộn, về sớm...',
                      onTap: onOpenStatusSettings,
                      isLast: true,
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Header (gradient zone) ─────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF07030), Color(0xFFE8601C), Color(0xFFE05818)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -20,
              right: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: -40,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),

            // Content — fully centered
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar — initials với gradient màu unique
                    UserAvatarWidget(
                      fullName: user?.fullName ?? '',
                      avatarUrl: user?.avatarUrl,
                      size: 96,
                      showEditBadge: true,
                    ),

                    const SizedBox(height: 14),

                    // Name
                    Text(
                      user?.fullName ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Email
                    Text(
                      user?.email ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Status pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF4ADE80),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Đang hoạt động',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Monthly stats card ─────────────────────────────────────────────────────
  Widget _buildMonthlyStats(BuildContext context, AttendanceState state) {
    final progress = state.totalWorkingDays > 0
        ? (state.workingDays / state.totalWorkingDays).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF4845F), Color(0xFFE8601C), Color(0xFFD14E0F)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.bar_chart_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Thống kê tháng này',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.access_time_rounded,
                    value: '${state.monthlyHours.toStringAsFixed(0)}h',
                    label: 'Tổng giờ',
                  ),
                ),
                _vDivider(),
                Expanded(
                  child: _StatItem(
                    icon: Icons.calendar_today_rounded,
                    value: '${state.workingDays}',
                    label: 'Ngày công',
                  ),
                ),
                _vDivider(),
                Expanded(
                  child: _StatItem(
                    icon: Icons.task_alt_rounded,
                    value: '${state.totalWorkingDays}',
                    label: 'Mục tiêu',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 7,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              '${state.workingDays}/${state.totalWorkingDays} ngày làm việc hoàn thành  •  ${(progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vDivider() => Container(
        width: 1,
        height: 56,
        color: Colors.white.withValues(alpha: 0.2),
      );

  // ── Generic white card section ─────────────────────────────────────────────
  Widget _buildSectionCard({
    required String label,
    required List<Widget> children,
  }) {
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                  Text(
                    label,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

}

// ── Stat item ────────────────────────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Info tile ────────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isLast;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: AppColors.divider),
          ),
      ],
    );
  }
}

// ── Shift tile – hiển thị ca hiện tại, nhấn để chọn lại ────────────────────
class _ShiftTile extends StatelessWidget {
  final String selected;
  final VoidCallback onTap;

  const _ShiftTile({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 12, 6),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.schedule_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ca làm việc',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Bắt đầu lúc $selected',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textHint,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Divider(height: 1, color: AppColors.divider),
        ),
      ],
    );
  }
}

// ── Generic settings tile ───────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLast;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 12, 6),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textHint,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: AppColors.divider),
          ),
      ],
    );
  }
}

// ── Shift picker bottom sheet ────────────────────────────────────────────────
class _ShiftPickerSheet extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onPick;

  const _ShiftPickerSheet({required this.selected, required this.onPick});

  static const _shifts = ['8:00', '8:30', '9:00'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.schedule_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Chọn ca làm việc',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Options
          ..._shifts.map((shift) {
            final isSelected = shift == selected;
            return GestureDetector(
              onTap: () => onPick(shift),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.5)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    // Clock icon
                    Icon(
                      Icons.access_time_rounded,
                      size: 20,
                      color: isSelected
                          ? AppColors.primary
                          : const Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ca $shift',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.primary
                                  : const Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Bắt đầu lúc $shift – kết thúc lúc ${ShiftParser.endTime(shift)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.75)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

