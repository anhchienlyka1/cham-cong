import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../config/themes/app_colors.dart';
import '../../../../config/themes/app_text_styles.dart';
import '../bloc/auth_bloc.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // AuthBloc đã được provide ở root (App widget),
    // không cần tạo BlocProvider mới ở đây.
    return const _LoginView();
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  static const _kSavedEmailKey = 'saved_email';
  static const _kRememberMeKey = 'remember_me';

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  /// Đọc email đã lưu từ SharedPreferences khi mở màn login
  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_kRememberMeKey) ?? false;
    if (remember) {
      final savedEmail = prefs.getString(_kSavedEmailKey) ?? '';
      setState(() {
        _rememberMe = true;
        _emailController.text = savedEmail;
      });
    }
  }

  /// Lưu hoặc xoá email tuỳ theo checkbox
  Future<void> _saveCredentials(String email) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString(_kSavedEmailKey, email);
      await prefs.setBool(_kRememberMeKey, true);
    } else {
      await prefs.remove(_kSavedEmailKey);
      await prefs.setBool(_kRememberMeKey, false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_formKey.currentState?.validate() ?? false) {
      _saveCredentials(email);
      context.read<AuthBloc>().add(
            AuthLoginRequested(
              email: email,
              password: password,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.authenticated) {
            context.go(RouteNames.home);
          } else if (state.status == AuthStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Đã có lỗi xảy ra'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Scaffold(
          // resizeToAvoidBottomInset: false để tránh keyboard đẩy layout
          resizeToAvoidBottomInset: true,
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
            // LayoutBuilder để biết chính xác chiều cao khả dụng
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  // padding đảm bảo không bị che bởi system bars
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top,
                    bottom: MediaQuery.of(context).padding.bottom,
                  ),
                  child: ConstrainedBox(
                    // minHeight = chiều cao toàn màn hình trừ system bars
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Logo / App icon ──────────────────────────
                            _buildLogo(),
                            const SizedBox(height: 12),

                            // ── App name ─────────────────────────────────
                            Text(
                              'Chấm Công',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.h1.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Đăng nhập để tiếp tục',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                            const SizedBox(height: 40),

                            // ── Glass card chứa form ─────────────────────
                            _buildGlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Email / Username
                                  _buildLabel('Tài khoản'),
                                  const SizedBox(height: 8),
                                  _buildGlassTextField(
                                    controller: _emailController,
                                    hint: 'Nhập email hoặc tên đăng nhập',
                                    icon: Icons.person_outline_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Vui lòng nhập tài khoản';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  // Password
                                  _buildLabel('Mật khẩu'),
                                  const SizedBox(height: 8),
                                  _buildGlassTextField(
                                    controller: _passwordController,
                                    hint: 'Nhập mật khẩu',
                                    icon: Icons.lock_outline_rounded,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _onLogin(),
                                    suffixIcon: GestureDetector(
                                      onTap: () => setState(
                                        () =>
                                            _obscurePassword =
                                                !_obscurePassword,
                                      ),
                                      child: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: Colors.white
                                            .withValues(alpha: 0.65),
                                        size: 20,
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Vui lòng nhập mật khẩu';
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 12),

                                  // ── Ghi nhớ đăng nhập + Quên mật khẩu ──
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Checkbox ghi nhớ
                                      GestureDetector(
                                        onTap: () => setState(
                                          () => _rememberMe = !_rememberMe,
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: Checkbox(
                                                value: _rememberMe,
                                                onChanged: (v) => setState(
                                                  () =>
                                                      _rememberMe = v ?? false,
                                                ),
                                                activeColor: Colors.white,
                                                checkColor: AppColors.primary,
                                                side: BorderSide(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.65),
                                                  width: 1.5,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Ghi nhớ đăng nhập',
                                              style: AppTextStyles.labelMedium
                                                  .copyWith(
                                                color: Colors.white
                                                    .withValues(alpha: 0.85),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Quên mật khẩu
                                      GestureDetector(
                                        onTap: () {
                                          // TODO: Navigate to forgot password
                                        },
                                        child: Text(
                                          'Quên mật khẩu?',
                                          style: AppTextStyles.labelMedium
                                              .copyWith(
                                            color: Colors.white
                                                .withValues(alpha: 0.85),
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: Colors.white
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ── Login button ─────────────────────────────
                            BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                final isLoading =
                                    state.status == AuthStatus.loading;
                                return _buildLoginButton(isLoading);
                              },
                            ),
                            const SizedBox(height: 24),

                            // ── Register link ────────────────────────────
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Chưa có tài khoản? ',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color:
                                        Colors.white.withValues(alpha: 0.75),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    // TODO: Navigate to register page
                                  },
                                  child: Text(
                                    'Đăng ký',
                                    style: AppTextStyles.labelLarge.copyWith(
                                      color: Colors.white,
                                      decoration: TextDecoration.underline,
                                      decorationColor:
                                          Colors.white.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ── Logo icon with glass background ──────────────────────────────────────
  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 2,
          ),
        ),
        child: const Icon(
          Icons.access_time_filled_rounded,
          size: 44,
          color: Colors.white,
        ),
      ),
    );
  }

  // ── Glass card container ─────────────────────────────────────────────────
  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  // ── Field label ───────────────────────────────────────────────────────────
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.labelMedium.copyWith(
        color: Colors.white.withValues(alpha: 0.85),
        letterSpacing: 0.3,
      ),
    );
  }

  // ── Glass text field ──────────────────────────────────────────────────────
  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: Colors.white.withValues(alpha: 0.45),
        ),
        prefixIcon:
            Icon(icon, color: Colors.white.withValues(alpha: 0.65), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.12),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.7),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFFFCDD2), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFFFCDD2), width: 1.5),
        ),
        errorStyle: AppTextStyles.caption
            .copyWith(color: const Color(0xFFFFCDD2)),
      ),
    );
  }

  // ── Login button ──────────────────────────────────────────────────────────
  Widget _buildLoginButton(bool isLoading) {
    return GestureDetector(
      onTap: isLoading ? null : _onLogin,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                )
              : Text(
                  'Đăng nhập',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}
