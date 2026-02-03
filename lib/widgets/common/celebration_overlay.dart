import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../services/locale_service.dart';
import 'confetti_animation.dart';

/// 庆祝弹窗组件 - Minimal Peach 风格
/// 显示温柔的粉色礼花和随机鼓励文案
class CelebrationOverlay extends StatefulWidget {
  final VoidCallback? onDismiss;

  const CelebrationOverlay({super.key, this.onDismiss});

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  // 心形浮动动画
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  
  String _message = '';
  bool _showContent = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.elasticOut),
    );

    // 浮动动画
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _floatAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _floatController.repeat(reverse: true);

    _loadRandomMessage();
  }

  Future<void> _loadRandomMessage() async {
    try {
      // Load language-specific celebration messages
      final lang = LocaleService.instance.currentLanguage.code;
      String jsonPath = 'assets/celebrations_$lang.json';
      
      String jsonString;
      try {
        jsonString = await rootBundle.loadString(jsonPath);
      } catch (_) {
        // Fallback to English if language-specific file not found
        jsonString = await rootBundle.loadString('assets/celebrations.json');
      }
      
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final messages = List<String>.from(jsonData['messages'] ?? []);

      if (messages.isNotEmpty) {
        final random = Random();
        _message = messages[random.nextInt(messages.length)];
      } else {
        _message = tr('celebration_default');
      }
    } catch (e) {
      _message = tr('celebration_default');
    }

    // 延迟显示文案
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      setState(() {
        _showContent = true;
      });
      _fadeController.forward();
    }

    // 自动消失
    await Future.delayed(const Duration(milliseconds: 3000));
    if (mounted) {
      await _fadeController.reverse();
      widget.onDismiss?.call();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () async {
          await _fadeController.reverse();
          widget.onDismiss?.call();
        },
        child: Stack(
          children: [
            // 柔和的粉色渐变背景
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _showContent ? 1.0 : 0.0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primaryLight.withValues(alpha: 0.85),
                      AppColors.background.withValues(alpha: 0.9),
                    ],
                  ),
                ),
              ),
            ),

            // 礼花动画
            const Positioned.fill(child: ConfettiAnimation()),

            // 中心文案卡片
            if (_showContent)
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildMessageCard(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard() {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -4 + _floatAnimation.value * 8),
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.primaryLight,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 可爱的庆祝图标区域
            _buildCelebrationIcon(),
            const SizedBox(height: 20),
            // 主标题
            Text(
              tr('all_done'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            // 鼓励文案
            Text(
              _message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            // 装饰心形
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMiniHeart(AppColors.priorityP1, 8),
                const SizedBox(width: 6),
                _buildMiniHeart(AppColors.primary, 10),
                const SizedBox(width: 6),
                _buildMiniHeart(AppColors.priorityP1, 8),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCelebrationIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.priorityP0,
            AppColors.priorityP1,
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 主图标 - 星星
          const Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 36,
          ),
          // 小星星装饰
          Positioned(
            top: 8,
            right: 10,
            child: Icon(
              Icons.star,
              color: Colors.white.withValues(alpha: 0.7),
              size: 12,
            ),
          ),
          Positioned(
            bottom: 12,
            left: 8,
            child: Icon(
              Icons.star,
              color: Colors.white.withValues(alpha: 0.5),
              size: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniHeart(Color color, double size) {
    return Icon(
      Icons.favorite,
      color: color,
      size: size,
    );
  }
}

/// 显示庆祝弹窗的便捷方法
void showCelebrationOverlay(BuildContext context) {
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => CelebrationOverlay(
      onDismiss: () {
        overlayEntry.remove();
      },
    ),
  );

  Overlay.of(context).insert(overlayEntry);
}
