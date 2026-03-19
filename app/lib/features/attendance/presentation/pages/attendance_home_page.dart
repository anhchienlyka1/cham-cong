import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/themes/app_text_styles.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/utils/work_hours_calculator.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_state.dart';
import '../bloc/attendance_event.dart';


// ─────────────────────────────────────────────────────────────────────────────
// Main Page
// ─────────────────────────────────────────────────────────────────────────────
class AttendanceHomePage extends StatelessWidget {
  const AttendanceHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      // Loại bỏ Scaffold lồng – dùng MediaQuery override để cách ly
      // hoàn toàn layout khỏi bàn phím. Bàn phím sẽ "nổi" phía trên
      // mà không đẩy hay resize bất cứ thứ gì.
      child: Builder(
        builder: (context) {
          // Ghi đè viewInsets = zero → layout không biết keyboard tồn tại
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(viewInsets: EdgeInsets.zero),
            child: BlocBuilder<AttendanceBloc, AttendanceState>(
              builder: (context, state) {
                return Container(
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
                        // ── Header ────────────────────────────────────────
                        _buildHeader(context),

                        // ── Đồng hồ siêu lớn ─────────────────────────────
                        const Expanded(flex: 3, child: _SuperClock()),

                        // ── Nút CHẤM CÔNG + phụ trợ ──────────────────────
                        Expanded(
                          flex: 5,
                          child: _ActionZone(state: state),
                        ),

                        // ── Card trạng thái ───────────────────────────────
                        _buildStatusCard(context, state),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          const _GreetingChip(),
          const Spacer(),
          _HeaderIconButton(icon: Icons.notifications_outlined, onTap: () {}),
        ],
      ),
    );
  }

  // ── Status Card ────────────────────────────────────────────────────────────
  Widget _buildStatusCard(BuildContext context, AttendanceState state) {
    return _LiveStatusCard(state: state);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Live Status Card – cập nhật tổng giờ và tiến độ real-time khi đang làm việc
// ─────────────────────────────────────────────────────────────────────────────
class _LiveStatusCard extends StatefulWidget {
  final AttendanceState state;
  const _LiveStatusCard({required this.state});

  @override
  State<_LiveStatusCard> createState() => _LiveStatusCardState();
}

class _LiveStatusCardState extends State<_LiveStatusCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _LiveStatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _startTimerIfNeeded();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimerIfNeeded() {
    _timer?.cancel();
    // Chỉ chạy timer khi đang working (đã checkin, chưa checkout)
    if (widget.state.isWorking) {
      _timer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  /// Tính giờ làm việc real-time (hoặc dùng hoursWorked nếu đã checkout)
  double? _calcHours() {
    final record = widget.state.todayRecord;
    if (record == null || record.checkIn == null) return null;

    // Đã checkout → dùng hoursWorked
    if (record.hoursWorked != null) return record.hoursWorked;

    // Đang làm → tính real-time (chỉ nếu cùng ngày)
    final now = DateTime.now();
    final checkIn = record.checkIn!;
    final isSameDay = checkIn.year == now.year &&
        checkIn.month == now.month &&
        checkIn.day == now.day;
    if (!isSameDay) return null;

    final result = WorkHoursCalculator.calculate(checkIn, now);
    return result < 0 ? 0 : result;
  }

  String _formatHours(double? hours) {
    if (hours == null) return '--';
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  double _calcProgress(double? hours) {
    if (hours == null) return 0.0;
    return (hours / 8.0).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final now = DateTime.now();
    final monthNames = [
      '',
      'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4',
      'Tháng 5', 'Tháng 6', 'Tháng 7', 'Tháng 8',
      'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12',
    ];
    final dateLabel = '${now.day} ${monthNames[now.month]}';

    final hours = _calcHours();
    final progress = _calcProgress(hours);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + date
            Row(
              children: [
                Text(
                  'Trạng thái hôm nay',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    dateLabel,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Time columns
            Row(
              children: [
                _buildTimeColumn(
                  label: 'Giờ Vào',
                  time: state.todayRecord?.formattedCheckIn ?? '--:--',
                  badge: state.todayRecord?.isLate == true
                      ? (state.todayRecord?.lateReason != null
                          ? '⏰ Muộn'
                          : null)
                      : null,
                ),
                _buildTimeColumn(
                  label: 'Giờ Ra',
                  time: state.todayRecord?.formattedCheckOut ?? '--:--',
                  badge: state.todayRecord?.isEarlyLeave == true
                      ? (state.todayRecord?.earlyLeaveReason != null
                          ? '🏃 Sớm'
                          : null)
                      : null,
                ),
                _buildTimeColumn(
                  label: 'Tổng giờ',
                  time: _formatHours(hours),
                  isBold: true,
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Progress
            Row(
              children: [
                Text(
                  'Tiến độ làm việc',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const Spacer(),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeColumn({
    required String label,
    required String time,
    bool isBold = false,
    String? badge,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: AppTextStyles.h3.copyWith(
              color: Colors.white,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              fontSize: 20,
              letterSpacing: -0.5,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE8601C).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Super Clock – đồng hồ siêu lớn real-time
// ─────────────────────────────────────────────────────────────────────────────
class _SuperClock extends StatefulWidget {
  const _SuperClock();

  @override
  State<_SuperClock> createState() => _SuperClockState();
}

class _SuperClockState extends State<_SuperClock> {
  late DateTime _now;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final h = _twoDigits(_now.hour);
    final m = _twoDigits(_now.minute);
    final s = _twoDigits(_now.second);
    final secondFraction = _now.second / 60.0;

    final weekdays = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    final months = [
      '',
      'Tháng 1',
      'Tháng 2',
      'Tháng 3',
      'Tháng 4',
      'Tháng 5',
      'Tháng 6',
      'Tháng 7',
      'Tháng 8',
      'Tháng 9',
      'Tháng 10',
      'Tháng 11',
      'Tháng 12',
    ];
    final dayLabel =
        '${weekdays[_now.weekday - 1]}, ${_now.day} ${months[_now.month]}';

    return LayoutBuilder(
      builder: (context, constraints) {
        // Scale theo chiều cao có sẵn, tối đa 130px
        final maxH = constraints.maxHeight.isFinite ? constraints.maxHeight : 130.0;
        final scale = (maxH / 130.0).clamp(0.4, 1.0);
        final clockSize = (60.0 * scale).roundToDouble();
        final dateSize = (20.0 * scale).clamp(12.0, 20.0);
        final barWidth = (200.0 * scale).clamp(100.0, 200.0);

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // HH:MM:SS
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$h:$m',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: clockSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -3,
                      height: 1.0,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  TextSpan(
                    text: ':$s',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: clockSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -3,
                      height: 1.0,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: (10 * scale).roundToDouble()),

            // Progress bar giây
            SizedBox(
              width: barWidth,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Stack(
                  children: [
                    Container(
                      height: 3,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.linear,
                      height: 3,
                      width: barWidth * secondFraction,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: (8 * scale).roundToDouble()),

            Text(
              dayLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: dateSize,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Zone – nút chấm công + WFH + Nghỉ phép
// ─────────────────────────────────────────────────────────────────────────────
class _ActionZone extends StatefulWidget {
  final AttendanceState state;
  const _ActionZone({required this.state});

  @override
  State<_ActionZone> createState() => _ActionZoneState();
}

class _ActionZoneState extends State<_ActionZone> {
  // ── Chấm công ──────────────────────────────────────────────────────────────
  Future<void> _handleMainButton(BuildContext context) async {
    final state = widget.state;
    if (state.isCheckedOut) return;

    HapticFeedback.mediumImpact();

    // CHECK-OUT: kiểm tra về sớm + hiện khảo sát tâm trạng
    if (state.isCheckedIn) {
      String? earlyLeaveReason;

      // Kiểm tra về sớm (trước 17:30)
      final now = DateTime.now();
      final endCutoff = DateTime(now.year, now.month, now.day, 17, 30);
      if (now.isBefore(endCutoff)) {
        earlyLeaveReason = await _showEarlyLeaveReasonDialog(context);
        if (!context.mounted) return;
        if (earlyLeaveReason == null) return; // user huỷ
      }

      await _showMoodSurvey(context);
      if (!context.mounted) return;
      context
          .read<AttendanceBloc>()
          .add(AttendanceCheckOut(earlyLeaveReason: earlyLeaveReason));
      return;
    }

    // CHECK-IN: kiểm tra có muộn không (sau 8:30)
    String? lateReason;
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day, 8, 30);
    if (now.isAfter(cutoff)) {
      lateReason = await _showLateReasonDialog(context);
      if (!context.mounted) return;
      if (lateReason == null) return; // user hủy
    }

    if (!context.mounted) return;
    context
        .read<AttendanceBloc>()
        .add(AttendanceCheckIn(lateReason: lateReason));
  }

  // ── Dialog: nhập lý do đi muộn ─────────────────────────────────────────────
  Future<String?> _showLateReasonDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ReasonDialog(
        icon: Icons.access_time_rounded,
        title: 'Đi muộn',
        subtitle: 'Bạn check-in sau 8:30. Vui lòng nhập lý do để tiếp tục.',
        hintText: 'Ví dụ: Kẹt xe, họp khách hàng...',
        controller: ctrl,
      ),
    );
  }

  // ── Dialog: nhập lý do về sớm ──────────────────────────────────────────────
  Future<String?> _showEarlyLeaveReasonDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ReasonDialog(
        icon: Icons.directions_run_rounded,
        title: 'Về sớm',
        subtitle: 'Bạn check-out trước 17:30. Vui lòng nhập lý do để tiếp tục.',
        hintText: 'Ví dụ: Việc gia đình, khám bệnh...',
        controller: ctrl,
      ),
    );
  }

  // ── Dialog: khảo sát tâm trạng ─────────────────────────────────────────────
  Future<String?> _showMoodSurvey(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF3ED),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_emotions_outlined,
                  color: Color(0xFFE8601C),
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Hôm nay thế nào?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Cho chúng tôi biết tâm trạng của bạn trước khi về nhé!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _MoodButton(
                    emoji: '😄',
                    label: 'Tuyệt vời',
                    onTap: () => Navigator.pop(ctx, 'great'),
                  ),
                  _MoodButton(
                    emoji: '😐',
                    label: 'Bình thường',
                    onTap: () => Navigator.pop(ctx, 'neutral'),
                  ),
                  _MoodButton(
                    emoji: '😫',
                    label: 'Mệt mỏi',
                    onTap: () => Navigator.pop(ctx, 'tired'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'skip'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[500],
                ),
                child: const Text('Bỏ qua'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isDone = state.isCheckedOut;
    final isWorking = state.isCheckedIn && !isDone;
    final notStarted = !state.isCheckedIn;

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxHeight - (notStarted ? 100.0 : 0.0);
        final btnSize = available.clamp(140.0, 200.0);

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _MainCheckButton(
              size: btnSize,
              isDone: isDone,
              isWorking: isWorking,
              onTap: () => _handleMainButton(context),
            ),
            // 3 card nhanh – hiện khi chưa check-in
            if (notStarted) const SizedBox(height: 20),
            if (notStarted) const _QuickDayTypeRow(),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Check Button – khổng lồ, pulsing
// ─────────────────────────────────────────────────────────────────────────────
class _MainCheckButton extends StatefulWidget {
  final double size;
  final bool isDone;
  final bool isWorking;
  final VoidCallback onTap;

  const _MainCheckButton({
    required this.size,
    required this.isDone,
    required this.isWorking,
    required this.onTap,
  });

  @override
  State<_MainCheckButton> createState() => _MainCheckButtonState();
}

class _MainCheckButtonState extends State<_MainCheckButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _outerPulse;
  late Animation<double> _innerPulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _outerPulse = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _innerPulse = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _label {
    if (widget.isDone) return 'Hoàn thành';
    if (widget.isWorking) return 'CHẤM CÔNG';
    return 'CHẤM CÔNG';
  }

  String get _sublabel {
    if (widget.isDone) return '';
    if (widget.isWorking) return 'GIỜ RA';
    return 'GIỜ VÀO';
  }

  IconData get _icon {
    if (widget.isDone) return Icons.check_rounded;
    if (widget.isWorking) return Icons.logout_rounded;
    return Icons.fingerprint_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;           // dynamic size from LayoutBuilder
    final inner = s * 0.71;          // main circle
    final mid   = s * 0.84;          // middle ring
    final iconSz = (s * 0.27).clamp(26.0, 52.0);
    final labelSz = (s * 0.073).clamp(11.0, 16.0);

    return GestureDetector(
      onTap: widget.isDone ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return SizedBox(
            width: s,
            height: s,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow ring
                if (!widget.isDone)
                  Transform.scale(
                    scale: _outerPulse.value,
                    child: Container(
                      width: s,
                      height: s,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),

                // Middle ring
                Transform.scale(
                  scale: _innerPulse.value,
                  child: Container(
                    width: mid,
                    height: mid,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                ),

                // Main circle
                Container(
                  width: inner,
                  height: inner,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.45),
                      width: 2.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _icon,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: iconSz,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _label,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: labelSz,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (_sublabel.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          _sublabel,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: (labelSz * 0.7).clamp(9.0, 12.0),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Day Type Selector – 3 option trạng thái nghỉ: Nghỉ phép / Nghỉ KL / WFH
// ─────────────────────────────────────────────────────────────────────────────
class _DayTypeSelector extends StatefulWidget {
  const _DayTypeSelector();

  @override
  State<_DayTypeSelector> createState() => _DayTypeSelectorState();
}

class _DayTypeSelectorState extends State<_DayTypeSelector> {
  int? _selected; // 0=Nghỉ phép, 1=Nghỉ KL, 2=WFH

  static const _options = [
    _DayTypeOption(
      label: 'Nghỉ phép',
      icon: Icons.beach_access_rounded,
      color: Color(0xFF06B6D4),
      description: 'Ngày nghỉ có lương',
    ),
    _DayTypeOption(
      label: 'Nghỉ không lương',
      icon: Icons.money_off_rounded,
      color: Color(0xFFF97316),
      description: 'Ngày nghỉ không hưởng lương',
    ),
    _DayTypeOption(
      label: 'WFH',
      icon: Icons.home_work_rounded,
      color: Color(0xFF10B981),
      description: 'Làm việc tại nhà',
    ),
  ];

  void _onTap(BuildContext context, int index) {
    HapticFeedback.lightImpact();
    setState(() => _selected = index);
    _showConfirmDialog(context, index);
  }

  Future<void> _showConfirmDialog(BuildContext context, int index) async {
    final opt = _options[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: opt.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(opt.icon, color: opt.color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                'Đăng ký ${opt.label}?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                opt.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Hủy',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        backgroundColor: opt.color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Xác nhận',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
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

    if (!mounted) return;
    if (confirmed != true) {
      setState(() => _selected = null);
    } else {
      // Dispatch check-in với note loại ngày
      if (context.mounted) {
        context.read<AttendanceBloc>().add(
              AttendanceCheckIn(lateReason: opt.label),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Text(
              'Hoặc đăng ký trạng thái ngày',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          // 3 chip buttons
          Row(
            children: List.generate(_options.length, (i) {
              final opt = _options[i];
              final isActive = _selected == i;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => _onTap(context, i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                      decoration: BoxDecoration(
                        color: isActive
                            ? opt.color.withValues(alpha: 0.85)
                            : Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isActive
                              ? opt.color
                              : Colors.white.withValues(alpha: 0.28),
                          width: isActive ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            opt.icon,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            opt.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _DayTypeOption {
  final String label;
  final IconData icon;
  final Color color;
  final String description;
  const _DayTypeOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.description,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Mood Button (emoji + label)
// ─────────────────────────────────────────────────────────────────────────────
class _MoodButton extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _MoodButton({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3ED),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFFD4B8),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 30)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Greeting Chip
// ─────────────────────────────────────────────────────────────────────────────
class _GreetingChip extends StatelessWidget {
  const _GreetingChip();

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return '☀️  Chào buổi sáng!';
    if (hour >= 12 && hour < 14) return '🌤  Chào buổi trưa!';
    if (hour >= 14 && hour < 18) return '🌇  Chào buổi chiều!';
    if (hour >= 18 && hour < 22) return '🌙  Chào buổi tối!';
    return '🌜  Chúc ngủ ngon!';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Text(
        _greeting(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header Icon Button
// ─────────────────────────────────────────────────────────────────────────────
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reason Dialog – bắt buộc nhập lý do, không có nút Huỷ
// ─────────────────────────────────────────────────────────────────────────────
class _ReasonDialog extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String hintText;
  final TextEditingController controller;

  const _ReasonDialog({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.hintText,
    required this.controller,
  });

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  bool _showError = false;

  void _submit() {
    final text = widget.controller.text.trim();
    if (text.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    // Flutter's Dialog đã tự thêm MediaQuery.viewInsetsOf(context) vào padding.
    // KHÔNG cộng thêm bottom thủ công → sẽ bị tính 2 lần → dialog bay ra ngoài.
    return Dialog(
      insetPadding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF3ED),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.icon,
                color: const Color(0xFFE8601C),
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: widget.controller,
              autofocus: true,
              maxLines: 3,
              minLines: 2,
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              // scroll TextField lên phía trên bàn phím khi được focus
              scrollPadding: const EdgeInsets.only(bottom: 80),
              onChanged: (_) {
                if (_showError) setState(() => _showError = false);
              },
              decoration: InputDecoration(
                hintText: widget.hintText,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: _showError
                      ? const BorderSide(color: Color(0xFFE53935), width: 1.5)
                      : BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: _showError
                      ? const BorderSide(color: Color(0xFFE53935), width: 1.5)
                      : BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: _showError
                      ? const BorderSide(color: Color(0xFFE53935), width: 1.5)
                      : const BorderSide(color: Color(0xFFE8601C), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            if (_showError) ...[
              const SizedBox(height: 6),
              Row(
                children: const [
                  Icon(Icons.error_outline, color: Color(0xFFE53935), size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Vui lòng nhập lý do trước khi xác nhận.',
                    style: TextStyle(
                      color: Color(0xFFE53935),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8601C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Xác nhận & Tiếp tục',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE8601C),
                  side: const BorderSide(color: Color(0xFFE8601C), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Hủy',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Day Type Row – 3 card chấm công nhanh (chỉ hiện khi chưa check-in)
// ─────────────────────────────────────────────────────────────────────────────
class _QuickDayTypeRow extends StatelessWidget {
  const _QuickDayTypeRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _QuickDayCard(
            icon: Icons.beach_access_rounded,
            label: 'Nghỉ phép',
            sublabel: 'Có lương',
            color: const Color(0xFF06B6D4),
            onTap: () => _confirm(
              context,
              icon: Icons.beach_access_rounded,
              title: 'Nghỉ phép hôm nay?',
              subtitle: 'Ngày ${_todayLabel()} sẽ được ghi nhận là nghỉ phép có lương.',
              color: const Color(0xFF06B6D4),
              onConfirm: () => context
                  .read<AttendanceBloc>()
                  .add(const AttendanceMarkDayType(
                      dayType: AttendanceStatus.onLeave)),
            ),
          ),
          const SizedBox(width: 10),
          _QuickDayCard(
            icon: Icons.money_off_rounded,
            label: 'Nghỉ KL',
            sublabel: 'Không lương',
            color: const Color(0xFF64748B),
            onTap: () => _confirm(
              context,
              icon: Icons.money_off_rounded,
              title: 'Nghỉ không lương?',
              subtitle: 'Ngày ${_todayLabel()} sẽ được ghi nhận là nghỉ không lương.',
              color: const Color(0xFF64748B),
              onConfirm: () => context
                  .read<AttendanceBloc>()
                  .add(const AttendanceMarkDayType(
                      dayType: AttendanceStatus.unpaidLeave)),
            ),
          ),
          const SizedBox(width: 10),
          _QuickDayCard(
            icon: Icons.home_work_rounded,
            label: 'WFH',
            sublabel: 'Làm tại nhà',
            color: const Color(0xFF10B981),
            onTap: () => _confirm(
              context,
              icon: Icons.home_work_rounded,
              title: 'Làm việc tại nhà?',
              subtitle: 'Ngày ${_todayLabel()} sẽ được ghi nhận là Work From Home.',
              color: const Color(0xFF10B981),
              onConfirm: () => context
                  .read<AttendanceBloc>()
                  .add(const AttendanceMarkDayType(
                      dayType: AttendanceStatus.workFromHome)),
            ),
          ),
        ],
      ),
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }

  void _confirm(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onConfirm,
  }) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text('Hủy',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text('Xác nhận',
                          style: TextStyle(fontWeight: FontWeight.w700)),
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
}

class _QuickDayCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _QuickDayCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickDayCard> createState() => _QuickDayCardState();
}

class _QuickDayCardState extends State<_QuickDayCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.06,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.sublabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
