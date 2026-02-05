import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../services/auth_service.dart';
import '../../services/audio_service.dart';
import '../../services/locale_service.dart';
import '../../theme/app_colors.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _register() async {
    AudioService.instance.playButton();

    final email = _emailController.text.trim();
    final nickname = _nicknameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // 前端校验
    if (email.isEmpty ||
        nickname.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      setState(() => _error = tr('all_fields_required'));
      return;
    }

    if (password != confirmPassword) {
      setState(() => _error = tr('password_mismatch'));
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await AuthService.instance.register(
        email: email,
        password: password,
        nickname: nickname,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        // 注册成功，显示成功浮层后跳转到登录页
        _showSuccessDialog();
      } else {
        // 显示错误信息（AuthService 已返回国际化消息）
        setState(() => _error = result.errorMessage ?? tr('registration_failed'));
      }
    } catch (e) {
      // 打印详细错误以便调试
      debugPrint('Register error: $e');
      setState(() => _error = tr('network_error'));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 显示注册成功浮层
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 成功图标
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.priorityP0, AppColors.priorityP1],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              // 标题
              Text(
                tr('registration_successful'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              // 描述
              Text(
                tr('redirect_to_login'),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              // 进度指示
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // 1.5 秒后自动跳转到登录页
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pop(); // 关闭浮层
        Navigator.of(context).pop(); // 返回登录页
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nicknameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            AudioService.instance.playButton();
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        tr('create_account'),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tr('sign_up_to_start'),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Email Field
                      _buildTextField(
                        controller: _emailController,
                        label: tr('email'),
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // Nickname Field
                      _buildTextField(
                        controller: _nicknameController,
                        label: tr('nickname'),
                        icon: Icons.person_outline,
                        maxLength: 20,
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      _buildTextField(
                        controller: _passwordController,
                        label: tr('password'),
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                        obscureText: _obscurePassword,
                        onToggleVisibility: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password Field
                      _buildTextField(
                        controller: _confirmPasswordController,
                        label: tr('confirm_password'),
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                        obscureText: _obscureConfirmPassword,
                        onToggleVisibility: () {
                          setState(() =>
                              _obscureConfirmPassword = !_obscureConfirmPassword);
                        },
                      ),

                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppColors.error,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 32),

                      // Register Button
                      GestureDetector(
                        onTap: _isLoading ? null : _register,
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.priorityP0,
                                AppColors.priorityP1,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.priorityP0.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isLoading)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              else ...[
                                Text(
                                  tr('register'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Already have account
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            tr('have_account'),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              AudioService.instance.playButton();
                              Navigator.pop(context);
                            },
                            child: Text(
                              tr('login'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Spacer to push badge to bottom
                      const Spacer(),

                      // Made in China badge
                      _buildMadeInChinaBadge(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? obscureText : false,
        keyboardType: keyboardType,
        maxLength: maxLength,
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          prefixIcon: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
          border: InputBorder.none,
          counterText: '', // 隐藏字符计数
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        onChanged: (_) {
          // 输入时清除错误
          if (_error != null) {
            setState(() => _error = null);
          }
        },
      ),
    );
  }

  /// Made in China badge widget
  Widget _buildMadeInChinaBadge() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'assets/images/zh_cn.svg',
          width: 24,
          height: 16,
        ),
        const SizedBox(width: 8),
        Text(
          tr('made_in_china'),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
