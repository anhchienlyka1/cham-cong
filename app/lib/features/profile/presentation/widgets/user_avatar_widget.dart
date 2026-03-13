import 'package:flutter/material.dart';

/// Avatar hiển thị chữ cái đầu của tên người dùng.
/// Nếu [avatarUrl] được cung cấp sẽ tải ảnh mạng; ngược lại dùng initials.
class UserAvatarWidget extends StatelessWidget {
  final String fullName;
  final String? avatarUrl;
  final double size;
  final bool showEditBadge;
  final VoidCallback? onEditTap;

  const UserAvatarWidget({
    super.key,
    required this.fullName,
    this.avatarUrl,
    this.size = 96,
    this.showEditBadge = true,
    this.onEditTap,
  });

  // ── helpers ──────────────────────────────────────────────────
  String get _initials {
    // Guard: tên rỗng hoàn toàn
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return '?';

    final parts = trimmed
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty) // bỏ phần rỗng sau split
        .toList();

    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    // Lấy chữ cái đầu của từ đầu tiên và từ cuối cùng
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  /// Sinh màu gradient từ tên (nhất quán — cùng tên → cùng màu)
  List<Color> _gradientColors() {
    final hash = fullName.codeUnits.fold(0, (h, c) => (h * 31 + c) & 0x7FFFFFFF);
    final hue = (hash % 360).toDouble();
    return [
      HSLColor.fromAHSL(1.0, hue, 0.70, 0.55).toColor(),
      HSLColor.fromAHSL(1.0, (hue + 30) % 360, 0.65, 0.40).toColor(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final badgeSize = size * 0.30;

    return Stack(
      alignment: Alignment.bottomRight,
      clipBehavior: Clip.none,
      children: [
        // ── Avatar circle ────────────────────────────────────
        _AvatarCircle(
          size: size,
          avatarUrl: avatarUrl,
          initials: _initials,
          gradientColors: _gradientColors(),
        ),

        // ── Edit badge ───────────────────────────────────────
        if (showEditBadge)
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: onEditTap,
              child: _EditBadge(size: badgeSize),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Avatar circle — ảnh hoặc initials
// ─────────────────────────────────────────────────────────────
class _AvatarCircle extends StatelessWidget {
  final double size;
  final String? avatarUrl;
  final String initials;
  final List<Color> gradientColors;

  const _AvatarCircle({
    required this.size,
    this.avatarUrl,
    required this.initials,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: avatarUrl == null
            ? LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: avatarUrl != null ? Colors.white : null,
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: avatarUrl != null
            ? Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => _InitialsContent(
                  initials: initials,
                  size: size,
                  colors: gradientColors,
                ),
              )
            : _InitialsContent(
                initials: initials,
                size: size,
                colors: gradientColors,
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Initials nội dung
// ─────────────────────────────────────────────────────────────
class _InitialsContent extends StatefulWidget {
  final String initials;
  final double size;
  final List<Color> colors;

  const _InitialsContent({
    required this.initials,
    required this.size,
    required this.colors,
  });

  @override
  State<_InitialsContent> createState() => _InitialsContentState();
}

class _InitialsContentState extends State<_InitialsContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = widget.size * 0.32;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Soft inner glow ring
            Container(
              width: widget.size * _pulse.value * 0.75,
              height: widget.size * _pulse.value * 0.75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            // Initials text
            Text(
              widget.initials,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.5,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Edit badge (camera icon)
// ─────────────────────────────────────────────────────────────
class _EditBadge extends StatelessWidget {
  final double size;
  const _EditBadge({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: const Color(0xFFFF5900), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.camera_alt_rounded,
        size: size * 0.52,
        color: const Color(0xFFFF5900),
      ),
    );
  }
}
