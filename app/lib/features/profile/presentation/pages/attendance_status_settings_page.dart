import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../config/themes/app_colors.dart';

// ── Model ────────────────────────────────────────────────────────────────────

class AttendanceStatusConfig {
  final String id;
  final String label;
  final String description;
  final Color color;
  final IconData icon;
  bool isEnabled;
  int? lateThresholdMinutes; // dành riêng cho trạng thái "đi muộn"
  int? earlyLeaveThresholdMinutes; // dành riêng cho "về sớm"

  AttendanceStatusConfig({
    required this.id,
    required this.label,
    required this.description,
    required this.color,
    required this.icon,
    this.isEnabled = true,
    this.lateThresholdMinutes,
    this.earlyLeaveThresholdMinutes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'isEnabled': isEnabled,
        if (lateThresholdMinutes != null)
          'lateThresholdMinutes': lateThresholdMinutes,
        if (earlyLeaveThresholdMinutes != null)
          'earlyLeaveThresholdMinutes': earlyLeaveThresholdMinutes,
      };

  AttendanceStatusConfig copyWith({
    bool? isEnabled,
    int? lateThresholdMinutes,
    int? earlyLeaveThresholdMinutes,
  }) =>
      AttendanceStatusConfig(
        id: id,
        label: label,
        description: description,
        color: color,
        icon: icon,
        isEnabled: isEnabled ?? this.isEnabled,
        lateThresholdMinutes:
            lateThresholdMinutes ?? this.lateThresholdMinutes,
        earlyLeaveThresholdMinutes:
            earlyLeaveThresholdMinutes ?? this.earlyLeaveThresholdMinutes,
      );
}

// ── Page ─────────────────────────────────────────────────────────────────────

class AttendanceStatusSettingsPage extends StatefulWidget {
  const AttendanceStatusSettingsPage({super.key});

  @override
  State<AttendanceStatusSettingsPage> createState() =>
      _AttendanceStatusSettingsPageState();
}

class _AttendanceStatusSettingsPageState
    extends State<AttendanceStatusSettingsPage> {
  bool _isSaving = false;

  // Danh sách các trạng thái được quản lý
  late List<AttendanceStatusConfig> _statuses;

  @override
  void initState() {
    super.initState();
    _statuses = _defaultStatuses();
    _loadFromFirestore();
  }

  List<AttendanceStatusConfig> _defaultStatuses() => [
        AttendanceStatusConfig(
          id: 'present',
          label: 'Đúng giờ',
          description: 'Check-in trong khoảng thời gian quy định',
          color: const Color(0xFF10B981),
          icon: Icons.check_circle_rounded,
          isEnabled: true,
        ),
        AttendanceStatusConfig(
          id: 'late',
          label: 'Đi muộn',
          description: 'Check-in trễ hơn giờ bắt đầu ca',
          color: const Color(0xFFF59E0B),
          icon: Icons.watch_later_rounded,
          isEnabled: true,
          lateThresholdMinutes: 5,
        ),
        AttendanceStatusConfig(
          id: 'earlyLeave',
          label: 'Về sớm',
          description: 'Check-out trước giờ kết thúc ca',
          color: const Color(0xFF3B82F6),
          icon: Icons.directions_run_rounded,
          isEnabled: true,
          earlyLeaveThresholdMinutes: 5,
        ),
        AttendanceStatusConfig(
          id: 'absent',
          label: 'Vắng mặt',
          description: 'Không có bản ghi check-in trong ngày làm việc',
          color: const Color(0xFFEF4444),
          icon: Icons.cancel_rounded,
          isEnabled: true,
        ),
        AttendanceStatusConfig(
          id: 'halfDay',
          label: 'Nửa ngày',
          description: 'Làm việc ít hơn một nửa ca quy định',
          color: const Color(0xFF8B5CF6),
          icon: Icons.hourglass_top_rounded,
          isEnabled: true,
        ),
        AttendanceStatusConfig(
          id: 'overtime',
          label: 'Làm thêm giờ',
          description: 'Check-out sau giờ kết thúc ca hơn 2 tiếng',
          color: const Color(0xFFF07030),
          icon: Icons.trending_up_rounded,
          isEnabled: true,
        ),
        AttendanceStatusConfig(
          id: 'workFromHome',
          label: 'Làm tại nhà',
          description: 'Làm việc từ xa / Work from home',
          color: const Color(0xFF06B6D4),
          icon: Icons.home_work_rounded,
          isEnabled: true,
        ),
        AttendanceStatusConfig(
          id: 'onLeave',
          label: 'Nghỉ phép',
          description: 'Ngày nghỉ phép có phê duyệt',
          color: const Color(0xFF14B8A6),
          icon: Icons.beach_access_rounded,
          isEnabled: true,
        ),
        AttendanceStatusConfig(
          id: 'sickLeave',
          label: 'Nghỉ bệnh',
          description: 'Nghỉ do ốm đau, có hoặc không có giấy tờ',
          color: const Color(0xFFEC4899),
          icon: Icons.local_hospital_rounded,
          isEnabled: true,
        ),
        AttendanceStatusConfig(
          id: 'businessTrip',
          label: 'Công tác',
          description: 'Đi công tác, hội nghị, tập huấn',
          color: const Color(0xFF6366F1),
          icon: Icons.flight_rounded,
          isEnabled: true,
        ),
        AttendanceStatusConfig(
          id: 'forgotPunch',
          label: 'Quên chấm công',
          description: 'Không có dữ liệu check-in/out do quên',
          color: const Color(0xFF9CA3AF),
          icon: Icons.fingerprint_rounded,
          isEnabled: true,
        ),
        AttendanceStatusConfig(
          id: 'holiday',
          label: 'Ngày lễ',
          description: 'Ngày nghỉ lễ theo quy định nhà nước',
          color: const Color(0xFFF43F5E),
          icon: Icons.celebration_rounded,
          isEnabled: true,
        ),
      ];

  Future<void> _loadFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('attendance_statuses')
          .get();
      if (!doc.exists) return;

      final data = doc.data() ?? {};
      setState(() {
        for (final s in _statuses) {
          final saved = data[s.id];
          if (saved is Map<String, dynamic>) {
            final idx = _statuses.indexOf(s);
            _statuses[idx] = s.copyWith(
              isEnabled: saved['isEnabled'] as bool? ?? s.isEnabled,
              lateThresholdMinutes:
                  saved['lateThresholdMinutes'] as int? ??
                      s.lateThresholdMinutes,
              earlyLeaveThresholdMinutes:
                  saved['earlyLeaveThresholdMinutes'] as int? ??
                      s.earlyLeaveThresholdMinutes,
            );
          }
        }
      });
    } catch (_) {}
  }

  Future<void> _saveToFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _isSaving = true);
    try {
      final Map<String, dynamic> data = {};
      for (final s in _statuses) {
        data[s.id] = s.toMap();
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('attendance_statuses')
          .set(data, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Đã lưu cài đặt trạng thái'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Lưu thất bại, thử lại sau'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _toggleStatus(int index, bool value) {
    setState(() => _statuses[index] = _statuses[index].copyWith(isEnabled: value));
  }

  void _editThreshold(int index) {
    final s = _statuses[index];
    final isLate = s.id == 'late';
    final isEarly = s.id == 'earlyLeave';
    if (!isLate && !isEarly) return;

    final current = isLate
        ? (s.lateThresholdMinutes ?? 5)
        : (s.earlyLeaveThresholdMinutes ?? 5);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ThresholdPickerSheet(
        title: isLate
            ? 'Ngưỡng đi muộn (phút)'
            : 'Ngưỡng về sớm (phút)',
        subtitle: isLate
            ? 'Số phút sau giờ bắt đầu ca mới tính là đi muộn'
            : 'Số phút trước giờ kết thúc ca mới tính là về sớm',
        icon: s.icon,
        color: s.color,
        currentValue: current,
        onConfirm: (v) {
          setState(() {
            _statuses[index] = isLate
                ? s.copyWith(lateThresholdMinutes: v)
                : s.copyWith(earlyLeaveThresholdMinutes: v);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _buildInfoBanner(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _StatusCard(
                    config: _statuses[index],
                    onToggle: (v) => _toggleStatus(index, v),
                    onEditThreshold: () => _editThreshold(index),
                  ),
                  childCount: _statuses.length,
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: _buildSaveButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.black12,
      surfaceTintColor: Colors.white,
      automaticallyImplyLeading: false,
      title: const Text(
        'Quản lý trạng thái',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1F2937),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFE5E7EB)),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.info_rounded,
                size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Bật/tắt các trạng thái hiển thị trong báo cáo và lịch sử chấm công. '
              'Trạng thái tắt sẽ không xuất hiện trong thống kê.',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveToFirestore,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
            elevation: 8,
            shadowColor: AppColors.primary.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.save_rounded, size: 20, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Lưu cài đặt',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Status Card ───────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final AttendanceStatusConfig config;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEditThreshold;

  const _StatusCard({
    required this.config,
    required this.onToggle,
    required this.onEditThreshold,
  });

  bool get _hasThreshold =>
      config.id == 'late' || config.id == 'earlyLeave';

  String? get _thresholdText {
    if (config.id == 'late' && config.lateThresholdMinutes != null) {
      return 'Ngưỡng: ${config.lateThresholdMinutes} phút';
    }
    if (config.id == 'earlyLeave' &&
        config.earlyLeaveThresholdMinutes != null) {
      return 'Ngưỡng: ${config.earlyLeaveThresholdMinutes} phút';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: config.isEnabled
              ? config.color.withValues(alpha: 0.2)
              : const Color(0xFFE5E7EB),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: config.isEnabled
                ? config.color.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                // Icon
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: config.isEnabled
                        ? config.color.withValues(alpha: 0.12)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    config.icon,
                    color: config.isEnabled
                        ? config.color
                        : const Color(0xFFD1D5DB),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 13),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            config.label,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: config.isEnabled
                                  ? const Color(0xFF1F2937)
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (config.isEnabled)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: config.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Bật',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: config.color,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        config.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: config.isEnabled
                              ? const Color(0xFF6B7280)
                              : const Color(0xFFD1D5DB),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Toggle
                Switch.adaptive(
                  value: config.isEnabled,
                  onChanged: onToggle,
                  thumbColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return config.color;
                    }
                    return null;
                  }),
                  trackColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return config.color.withValues(alpha: 0.4);
                    }
                    return null;
                  }),
                ),
              ],
            ),
          ),
          // Threshold row (chỉ hiện cho đi muộn / về sớm)
          if (_hasThreshold && config.isEnabled)
            _ThresholdRow(
              text: _thresholdText ?? '',
              color: config.color,
              onTap: onEditThreshold,
            ),
        ],
      ),
    );
  }
}

class _ThresholdRow extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onTap;

  const _ThresholdRow({
    required this.text,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(Icons.tune_rounded, size: 15, color: color),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const Spacer(),
            Text(
              'Chỉnh sửa',
              style: TextStyle(
                fontSize: 11.5,
                color: color.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}

// ── Threshold Picker Sheet ────────────────────────────────────────────────────

class _ThresholdPickerSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int currentValue;
  final ValueChanged<int> onConfirm;

  const _ThresholdPickerSheet({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.currentValue,
    required this.onConfirm,
  });

  @override
  State<_ThresholdPickerSheet> createState() => _ThresholdPickerSheetState();
}

class _ThresholdPickerSheetState extends State<_ThresholdPickerSheet> {
  static const _options = [0, 1, 2, 5, 10, 15, 20, 30];
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = _options.contains(widget.currentValue)
        ? widget.currentValue
        : _options.first;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 16,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: widget.color, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  Text(
                    widget.subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Grid options
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _options.map((v) {
              final isSelected = v == _selected;
              return GestureDetector(
                onTap: () => setState(() => _selected = v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 68,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? widget.color
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? widget.color
                          : const Color(0xFFE5E7EB),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$v',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF374151),
                        ),
                      ),
                      Text(
                        'phút',
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.8)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                widget.onConfirm(_selected);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.color,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Xác nhận',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
