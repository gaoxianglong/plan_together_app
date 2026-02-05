import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/audio_service.dart';
import '../../services/locale_service.dart';
import '../../widgets/common/auth_cat_logo.dart';
import '../main/main_page.dart';
import 'register_page.dart';

/// 登录页面
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _hasError = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_hasError) {
      setState(() {
        _hasError = false;
        _errorMessage = null;
      });
    }
  }

  Future<void> _handleLogin() async {
    AudioService.instance.playButton();
    _clearError();
    setState(() => _isLoading = true);

    final result = await AuthService.instance.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result.isSuccess) {
      // 登录成功，开启会话状态轮询
      AuthService.instance.startSessionPolling();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainPage()),
      );
    } else {
      setState(() {
        _hasError = true;
        _errorMessage = result.errorMessage;
      });
    }
  }

  void _navigateToRegister() {
    AudioService.instance.playButton();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  void _showForgotPasswordDialog() {
    AudioService.instance.playButton();
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isLoading = false;
        String? errorMessage;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: AppColors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 标题行 + X 按钮
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tr('retrieve_password'),
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            AudioService.instance.playButton();
                            Navigator.of(dialogContext).pop();
                          },
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tr('enter_email_reset'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 错误提示
                    if (errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    // 邮箱输入框
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: errorMessage != null 
                              ? AppColors.error.withValues(alpha: 0.5)
                              : AppColors.primaryLight.withValues(alpha: 0.5),
                        ),
                      ),
                      child: TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !isLoading,
                        style: const TextStyle(fontSize: 14),
                        onChanged: (_) {
                          if (errorMessage != null) {
                            setDialogState(() => errorMessage = null);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: tr('email'),
                          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: errorMessage != null ? AppColors.error : AppColors.primary,
                            size: 18,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 发送按钮
                    GestureDetector(
                      onTap: isLoading ? null : () async {
                        AudioService.instance.playButton();
                        
                        final email = emailController.text.trim();
                        if (email.isEmpty) {
                          setDialogState(() => errorMessage = tr('email_required'));
                          return;
                        }
                        
                        setDialogState(() {
                          isLoading = true;
                          errorMessage = null;
                        });
                        
                        final result = await AuthService.instance.forgotPassword(email);
                        
                        if (!dialogContext.mounted) return;
                        
                        if (result.isSuccess) {
                          Navigator.of(dialogContext).pop();
                          _showPasswordResetSuccessDialog();
                        } else {
                          setDialogState(() {
                            isLoading = false;
                            errorMessage = result.errorMessage;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: isLoading 
                              ? null
                              : const LinearGradient(
                                  colors: [AppColors.priorityP0, AppColors.priorityP1],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                          color: isLoading ? AppColors.textHint : null,
                          borderRadius: BorderRadius.circular(21),
                          boxShadow: isLoading ? null : [
                            BoxShadow(
                              color: AppColors.priorityP0.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: isLoading
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      tr('sending'),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  tr('send'),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 显示密码重置邮件发送成功的浮层
  void _showPasswordResetSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
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
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.priorityP0, AppColors.priorityP1],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.priorityP0.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              // 标题
              Text(
                tr('password_reset_email_sent'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              // 描述
              Text(
                tr('check_email_for_reset_link'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              // 确定按钮
              GestureDetector(
                onTap: () {
                  AudioService.instance.playButton();
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: double.infinity,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.priorityP0, AppColors.priorityP1],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      tr('confirm'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                    children: [
                      const SizedBox(height: 50),
              // Logo - 猫咪
              const AuthCatLogo(size: 160),
              const SizedBox(height: 8),
              // App 名称
              Text(
                tr('app_name'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tr('app_slogan'),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 36),
              // 错误提示
              if (_hasError && _errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // 账号输入框
              _buildTextField(
                controller: _emailController,
                hintText: tr('account'),
                prefixIcon: Icons.person_outline,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => _clearError(),
                hasError: _hasError,
              ),
              const SizedBox(height: 16),
              // 密码输入框
              _buildTextField(
                controller: _passwordController,
                hintText: tr('password'),
                prefixIcon: Icons.lock_outline,
                obscureText: _obscurePassword,
                onChanged: (_) => _clearError(),
                hasError: _hasError,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              const SizedBox(height: 12),
              // 找回密码
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _showForgotPasswordDialog,
                  child: Text(
                    tr('forgot_password'),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 登录按钮
              _buildLoginButton(),
              const SizedBox(height: 24),
              // 注册链接
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tr('no_account'),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _navigateToRegister,
                    child: Text(
                      tr('sign_up'),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
    bool hasError = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError ? AppColors.error : AppColors.primaryLight.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: hasError 
                ? AppColors.error.withValues(alpha: 0.1) 
                : AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 15,
          color: hasError ? AppColors.error : AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: hasError ? AppColors.error.withValues(alpha: 0.7) : AppColors.textHint,
            fontSize: 15,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: hasError ? AppColors.error : AppColors.primary,
            size: 20,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleLogin,
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
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else ...[
              Text(
                tr('login'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }
}
