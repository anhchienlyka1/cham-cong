import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/themes/app_colors.dart';
import '../../../../config/themes/app_text_styles.dart';
import '../../domain/entities/attendance_record.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';

class EditTimeSheet extends StatefulWidget {
  final AttendanceRecord record;

  const EditTimeSheet({super.key, required this.record});

  @override
  State<EditTimeSheet> createState() => _EditTimeSheetState();
}

class _EditTimeSheetState extends State<EditTimeSheet> {
  late TimeOfDay _checkInTime;
  late TimeOfDay _checkOutTime;

  @override
  void initState() {
    super.initState();
    _checkInTime = widget.record.checkIn != null
        ? TimeOfDay.fromDateTime(widget.record.checkIn!)
        : const TimeOfDay(hour: 8, minute: 0);
    _checkOutTime = widget.record.checkOut != null
        ? TimeOfDay.fromDateTime(widget.record.checkOut!)
        : const TimeOfDay(hour: 17, minute: 0);
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

  void _onSave() {
    final date = widget.record.date;
    final newCheckIn = DateTime(
      date.year, date.month, date.day,
      _checkInTime.hour, _checkInTime.minute,
    );
    final newCheckOut = DateTime(
      date.year, date.month, date.day,
      _checkOutTime.hour, _checkOutTime.minute,
    );

    context.read<AttendanceBloc>().add(
          AttendanceUpdateTime(
            recordId: widget.record.id,
            newCheckIn: newCheckIn,
            newCheckOut: newCheckOut,
          ),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Chỉnh sửa thời gian',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.record.formattedDate,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Time pickers row
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
                  const SizedBox(width: 16),
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
              const SizedBox(height: 24),

              // Calculated hours
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tổng: ${_calculateHours()} giờ',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
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
                      ),
                      child: Text(
                        'Lưu thay đổi',
                        style: AppTextStyles.button.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
          border: Border.all(
            color: color.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Nhấn để sửa',
              style: AppTextStyles.labelSmall.copyWith(
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _calculateHours() {
    final start = _checkInTime.hour * 60 + _checkInTime.minute;
    final end = _checkOutTime.hour * 60 + _checkOutTime.minute;
    final diff = end - start;
    if (diff <= 0) return '0.0';
    // Trừ 1.5h (90 phút) nghỉ trưa
    final netMinutes = diff - 90;
    if (netMinutes <= 0) return '0.0';
    return (netMinutes / 60).toStringAsFixed(1);
  }
}
