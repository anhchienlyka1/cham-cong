import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/themes/app_colors.dart';
import '../../../../config/themes/app_text_styles.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/utils/shift_parser.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';

class EditTimeSheet extends StatefulWidget {
  final AttendanceRecord record;

  const EditTimeSheet({super.key, required this.record});

  @override
  State<EditTimeSheet> createState() => _EditTimeSheetState();
}

class _EditTimeSheetState extends State<EditTimeSheet>
    with SingleTickerProviderStateMixin {
  late TimeOfDay _checkInTime;
  late TimeOfDay _checkOutTime;
  bool _isEditing = false;
  bool _isEditingNotes = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Note controllers
  late TextEditingController _lateNoteCtrl;
  late TextEditingController _earlyNoteCtrl;
  late TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _checkInTime = widget.record.checkIn != null
        ? TimeOfDay.fromDateTime(widget.record.checkIn!)
        : const TimeOfDay(hour: 8, minute: 0);
    _checkOutTime = widget.record.checkOut != null
        ? TimeOfDay.fromDateTime(widget.record.checkOut!)
        : const TimeOfDay(hour: 17, minute: 0);

    _lateNoteCtrl =
        TextEditingController(text: widget.record.lateReason ?? '');
    _earlyNoteCtrl =
        TextEditingController(text: widget.record.earlyLeaveReason ?? '');
    _noteCtrl = TextEditingController(text: widget.record.note ?? '');

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _lateNoteCtrl.dispose();
    _earlyNoteCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context, bool isCheckIn) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isCheckIn ? _checkInTime : _checkOutTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInTime = picked;
        } else {
          _checkOutTime = picked;
        }
      });
    }
  }

  Future<void> _onSave() async {
    final date = widget.record.date;
    final newCheckIn = DateTime(
      date.year, date.month, date.day,
      _checkInTime.hour, _checkInTime.minute,
    );
    final newCheckOut = DateTime(
      date.year, date.month, date.day,
      _checkOutTime.hour, _checkOutTime.minute,
    );

    // Lấy shift time từ AuthBloc
    final shift = context.read<AuthBloc>().state.user?.shift;
    final (shiftStart, shiftEnd) = ShiftParser.parse(shift);

    final isLate = ShiftParser.isLate(newCheckIn, shiftStart);
    final isEarly = ShiftParser.isEarlyLeave(newCheckOut, shiftEnd);

    String? lateReason;
    String? earlyLeaveReason;

    // Hỏi lý do đi muộn — pre-fill từ controller
    if (isLate) {
      lateReason = await _showReasonDialog(
        title: 'Đi muộn',
        message:
            'Giờ vào ${_formatTime(_checkInTime)} sau giờ quy định ${_formatTime(shiftStart)}.\nVui lòng nhập lý do:',
        icon: Icons.schedule_rounded,
        color: AppColors.warning,
        initialText: _lateNoteCtrl.text,
      );
      if (lateReason == null) return;
    }

    // Hỏi lý do về sớm — pre-fill từ controller
    if (isEarly) {
      earlyLeaveReason = await _showReasonDialog(
        title: 'Về sớm',
        message:
            'Giờ ra ${_formatTime(_checkOutTime)} trước giờ quy định ${_formatTime(shiftEnd)}.\nVui lòng nhập lý do:',
        icon: Icons.directions_run_rounded,
        color: const Color(0xFF3B82F6),
        initialText: _earlyNoteCtrl.text,
      );
      if (earlyLeaveReason == null) return;
    }

    if (!mounted) return;

    // Cập nhật controller để phản ánh giá trị mới
    if (isLate && lateReason != null) _lateNoteCtrl.text = lateReason;
    if (isEarly && earlyLeaveReason != null)
      _earlyNoteCtrl.text = earlyLeaveReason;

    context.read<AttendanceBloc>().add(
          AttendanceUpdateTime(
            recordId: widget.record.id,
            newCheckIn: newCheckIn,
            newCheckOut: newCheckOut,
            lateReason: lateReason,
            earlyLeaveReason: earlyLeaveReason,
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          ),
        );

    Navigator.of(context).pop();
    _showSuccessSnackbar('Đã lưu thay đổi thời gian');
  }

  /// Lưu chỉ phần ghi chú, không thay đổi giờ.
  void _onSaveNotes() {
    if (!mounted) return;
    context.read<AttendanceBloc>().add(
          AttendanceUpdateTime(
            recordId: widget.record.id,
            newCheckIn: widget.record.checkIn,
            newCheckOut: widget.record.checkOut,
            lateReason: _lateNoteCtrl.text.trim().isEmpty
                ? null
                : _lateNoteCtrl.text.trim(),
            earlyLeaveReason: _earlyNoteCtrl.text.trim().isEmpty
                ? null
                : _earlyNoteCtrl.text.trim(),
            note: _noteCtrl.text.trim().isEmpty
                ? null
                : _noteCtrl.text.trim(),
          ),
        );
    setState(() => _isEditingNotes = false);
    _showSuccessSnackbar('Đã lưu ghi chú');
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              message,
              style: AppTextStyles.labelMedium
                  .copyWith(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Hiển thị dialog nhập lý do đi muộn / về sớm.
  /// Trả về lý do (có thể rỗng) hoặc null nếu user hủy.
  Future<String?> _showReasonDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    String initialText = '',
  }) async {
    final controller = TextEditingController(text: initialText);
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTextStyles.h4.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Nhập lý do...',
                  hintStyle: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F6FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: color, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text(
                'Hủy',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Xác nhận',
                style: AppTextStyles.button.copyWith(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _calculateHours() {
    final start = _checkInTime.hour * 60 + _checkInTime.minute;
    final end = _checkOutTime.hour * 60 + _checkOutTime.minute;
    final diff = end - start;
    if (diff <= 0) return '0 giờ';
    final netMinutes = diff - 90; // trừ 1.5h nghỉ trưa
    if (netMinutes <= 0) return '0 giờ';
    final h = netMinutes ~/ 60;
    final m = netMinutes % 60;
    if (m == 0) return '$h giờ';
    return '$h giờ $m phút';
  }

  @override
  Widget build(BuildContext context) {
    final statusInfo = _resolveStatus(widget.record.status);

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF5F6FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle + Header ──────────────────────────────────
              _buildHeader(statusInfo),

              // ── Scrollable Body ──────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Column(
                    children: [
                      // Info summary card
                      _buildInfoCard(statusInfo),
                      const SizedBox(height: 14),

                      // Time pickers
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _isEditing
                            ? _buildEditSection()
                            : _buildViewSection(),
                      ),

                      const SizedBox(height: 14),

                      // Notes — always visible
                      _buildNotesCard(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // ── Action buttons ───────────────────────────────────
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────
  Widget _buildHeader(_StatusInfo statusInfo) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Status indicator circle
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: statusInfo.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusInfo.icon,
                    color: statusInfo.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.record.dayOfWeek,
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      widget.record.formattedDate,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusInfo.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusInfo.icon, size: 13, color: statusInfo.color),
                    const SizedBox(width: 5),
                    Text(
                      statusInfo.label,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: statusInfo.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Info summary card ────────────────────────────────────────────
  Widget _buildInfoCard(_StatusInfo statusInfo) {
    return Container(
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
      child: Row(
        children: [
          _InfoStat(
            icon: Icons.login_rounded,
            iconColor: AppColors.success,
            label: 'Giờ vào',
            value: widget.record.formattedCheckIn,
          ),
          _VertDivider(),
          _InfoStat(
            icon: Icons.logout_rounded,
            iconColor: AppColors.error,
            label: 'Giờ ra',
            value: widget.record.formattedCheckOut,
          ),
          _VertDivider(),
          _InfoStat(
            icon: Icons.timer_outlined,
            iconColor: AppColors.primary,
            label: 'Tổng giờ',
            value: widget.record.formattedHours,
            valueColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  // ── View Section (read-only) ─────────────────────────────────────
  Widget _buildViewSection() {
    return Container(
      key: const ValueKey('view'),
      padding: const EdgeInsets.all(20),
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
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Chi tiết thời gian',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _isEditing = true),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF07030), AppColors.primary],
                    ),
                    borderRadius: BorderRadius.circular(10),
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
                      const Icon(Icons.edit_rounded,
                          size: 13, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(
                        'Chỉnh sửa',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Timeline
          _buildTimeline(),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column: dots and line
        Column(
          children: [
            _TimelineDot(color: AppColors.success),
            Container(
              width: 2,
              height: 48,
              color: AppColors.divider,
            ),
            _TimelineDot(color: AppColors.error),
          ],
        ),
        const SizedBox(width: 14),
        // Right column: times
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TimelineEntry(
                label: 'Check-in (Giờ vào)',
                time: widget.record.formattedCheckIn,
                color: AppColors.success,
              ),
              const SizedBox(height: 20),
              _TimelineEntry(
                label: 'Check-out (Giờ ra)',
                time: widget.record.formattedCheckOut,
                color: AppColors.error,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Edit Section ─────────────────────────────────────────────────
  Widget _buildEditSection() {
    return Container(
      key: const ValueKey('edit'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_calendar_rounded,
                    size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text(
                'Chỉnh sửa thời gian',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() {
                  _isEditing = false;
                  // Reset to original
                  _checkInTime = widget.record.checkIn != null
                      ? TimeOfDay.fromDateTime(widget.record.checkIn!)
                      : const TimeOfDay(hour: 8, minute: 0);
                  _checkOutTime = widget.record.checkOut != null
                      ? TimeOfDay.fromDateTime(widget.record.checkOut!)
                      : const TimeOfDay(hour: 17, minute: 0);
                }),
                child: const Icon(Icons.close_rounded,
                    size: 20, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Pickers
          Row(
            children: [
              Expanded(
                child: _buildTimePickerCard(
                  label: 'Giờ Vào',
                  time: _checkInTime,
                  icon: Icons.login_rounded,
                  color: AppColors.success,
                  onTap: () => _selectTime(context, true),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildTimePickerCard(
                  label: 'Giờ Ra',
                  time: _checkOutTime,
                  icon: Icons.logout_rounded,
                  color: AppColors.error,
                  onTap: () => _selectTime(context, false),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Calculated total
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer_outlined,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Dự tính: ${_calculateHours()}',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerCard({
    required String label,
    required TimeOfDay time,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _formatTime(time),
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Nhấn để sửa',
                style: AppTextStyles.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Notes card ───────────────────────────────────────────────────
  Widget _buildNotesCard() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      child: _isEditingNotes ? _buildNotesEditMode() : _buildNotesViewMode(),
    );
  }

  Widget _buildNotesViewMode() {
    final hasLate = _lateNoteCtrl.text.isNotEmpty;
    final hasEarly = _earlyNoteCtrl.text.isNotEmpty;
    final hasNote = _noteCtrl.text.isNotEmpty;
    final hasAny = hasLate || hasEarly || hasNote;

    return Container(
      key: const ValueKey('notes-view'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Icon(Icons.notes_rounded,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Ghi chú',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _isEditingNotes = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_rounded,
                          size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Sửa ghi chú',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (hasAny) ...[
            const SizedBox(height: 10),
            if (hasLate)
              _NoteItem(
                label: 'Lý do đi muộn',
                value: _lateNoteCtrl.text,
                color: AppColors.warning,
                icon: Icons.schedule_rounded,
              ),
            if (hasLate && (hasEarly || hasNote))
              const SizedBox(height: 8),
            if (hasEarly)
              _NoteItem(
                label: 'Lý do về sớm',
                value: _earlyNoteCtrl.text,
                color: const Color(0xFF3B82F6),
                icon: Icons.directions_run_rounded,
              ),
            if (hasEarly && hasNote) const SizedBox(height: 8),
            if (hasNote)
              _NoteItem(
                label: 'Ghi chú chung',
                value: _noteCtrl.text,
                color: AppColors.textSecondary,
                icon: Icons.sticky_note_2_rounded,
              ),
          ] else ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.add_comment_rounded,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 6),
                Text(
                  'Chưa có ghi chú',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textHint,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesEditMode() {
    return Container(
      key: const ValueKey('notes-edit'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_note_rounded,
                    size: 15, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Text(
                'Chỉnh sửa ghi chú',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  // Reset controllers về giá trị hiện tại của record
                  _lateNoteCtrl.text = widget.record.lateReason ?? '';
                  _earlyNoteCtrl.text = widget.record.earlyLeaveReason ?? '';
                  _noteCtrl.text = widget.record.note ?? '';
                  setState(() => _isEditingNotes = false);
                },
                child: const Icon(Icons.close_rounded,
                    size: 20, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Lý do đi muộn
          _buildNoteField(
            controller: _lateNoteCtrl,
            label: 'Lý do đi muộn',
            hint: 'Nhập lý do đi muộn...',
            icon: Icons.schedule_rounded,
            color: AppColors.warning,
          ),
          const SizedBox(height: 10),

          // Lý do về sớm
          _buildNoteField(
            controller: _earlyNoteCtrl,
            label: 'Lý do về sớm',
            hint: 'Nhập lý do về sớm...',
            icon: Icons.directions_run_rounded,
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 10),

          // Ghi chú chung
          _buildNoteField(
            controller: _noteCtrl,
            label: 'Ghi chú chung',
            hint: 'Thêm ghi chú...',
            icon: Icons.sticky_note_2_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildNoteField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          maxLines: 2,
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textHint,
            ),
            filled: true,
            fillColor: color.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color, width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  // ── Action buttons ───────────────────────────────────────────────
  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _isEditing
            ? _buildTimeEditActions()
            : _isEditingNotes
                ? _buildNoteEditActions()
                : _buildCloseAction(),
      ),
    );
  }

  Widget _buildTimeEditActions() {
    return Row(
      key: const ValueKey('time-actions'),
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => setState(() {
              _isEditing = false;
              _checkInTime = widget.record.checkIn != null
                  ? TimeOfDay.fromDateTime(widget.record.checkIn!)
                  : const TimeOfDay(hour: 8, minute: 0);
              _checkOutTime = widget.record.checkOut != null
                  ? TimeOfDay.fromDateTime(widget.record.checkOut!)
                  : const TimeOfDay(hour: 17, minute: 0);
            }),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.divider),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Hủy',
              style: AppTextStyles.button.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _onSave,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.save_rounded,
                    size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Lưu thời gian',
                  style: AppTextStyles.button.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteEditActions() {
    return Row(
      key: const ValueKey('note-actions'),
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              _lateNoteCtrl.text = widget.record.lateReason ?? '';
              _earlyNoteCtrl.text = widget.record.earlyLeaveReason ?? '';
              _noteCtrl.text = widget.record.note ?? '';
              setState(() => _isEditingNotes = false);
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.divider),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Hủy',
              style: AppTextStyles.button.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _onSaveNotes,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.note_alt_rounded,
                    size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Lưu ghi chú',
                  style: AppTextStyles.button.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCloseAction() {
    return SizedBox(
      key: const ValueKey('close-action'),
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: AppColors.divider),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          'Đóng',
          style: AppTextStyles.button.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  _StatusInfo _resolveStatus(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return _StatusInfo(
            AppColors.success, Icons.check_circle_outline_rounded, 'Có mặt');
      case AttendanceStatus.late:
        return _StatusInfo(
            AppColors.warning, Icons.schedule_rounded, 'Đi muộn');
      case AttendanceStatus.absent:
        return _StatusInfo(AppColors.error, Icons.cancel_outlined, 'Vắng');
      case AttendanceStatus.halfDay:
        return _StatusInfo(AppColors.info, Icons.timelapse_rounded, 'Nửa ngày');
      case AttendanceStatus.onLeave:
        return _StatusInfo(
            const Color(0xFF06B6D4), Icons.beach_access_rounded, 'Nghỉ phép');
      case AttendanceStatus.earlyLeave:
        return _StatusInfo(const Color(0xFF3B82F6),
            Icons.directions_run_rounded, 'Về sớm');
      case AttendanceStatus.sickLeave:
        return _StatusInfo(const Color(0xFFF97316),
            Icons.local_hospital_rounded, 'Nghỉ ốm');
      case AttendanceStatus.businessTrip:
        return _StatusInfo(const Color(0xFF78716C),
            Icons.flight_takeoff_rounded, 'Công tác');
      case AttendanceStatus.workFromHome:
        return _StatusInfo(
            const Color(0xFF10B981), Icons.home_work_rounded, 'WFH');
      case AttendanceStatus.holiday:
        return _StatusInfo(const Color(0xFFF43F5E),
            Icons.celebration_rounded, 'Nghỉ lễ');
      case AttendanceStatus.overtime:
        return _StatusInfo(
            const Color(0xFF7C3AED), Icons.more_time_rounded, 'Tăng ca');
      case AttendanceStatus.forgotPunch:
        return _StatusInfo(const Color(0xFF6B7280),
            Icons.help_outline_rounded, 'Quên CC');
    }
  }
}

// ── Helper models & widgets ──────────────────────────────────────────────────

class _StatusInfo {
  final Color color;
  final IconData icon;
  final String label;
  const _StatusInfo(this.color, this.icon, this.label);
}

class _InfoStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoStat({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.labelLarge.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 48,
      color: AppColors.divider,
    );
  }
}

class _TimelineDot extends StatelessWidget {
  final Color color;
  const _TimelineDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6),
        ],
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  final String label;
  final String time;
  final Color color;

  const _TimelineEntry({
    required this.label,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: AppTextStyles.h4.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _NoteItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _NoteItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
