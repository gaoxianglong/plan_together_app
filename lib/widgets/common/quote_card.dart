import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// 樱花飘落励志名言卡片组件
class QuoteCard extends StatefulWidget {
  final String quote;

  const QuoteCard({super.key, required this.quote});

  @override
  State<QuoteCard> createState() => _QuoteCardState();
}

class _QuoteCardState extends State<QuoteCard> with TickerProviderStateMixin {
  late AnimationController _petalController;
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  final List<_SakuraPetal> _petals = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // 樱花飘落动画控制器
    _petalController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // 文字呼吸动画
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _breathAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    // 生成樱花花瓣
    _generatePetals();
  }

  void _generatePetals() {
    for (int i = 0; i < 12; i++) {
      _petals.add(
        _SakuraPetal(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: _random.nextDouble() * 8 + 6,
          speed: _random.nextDouble() * 0.3 + 0.2,
          swayAmount: _random.nextDouble() * 0.1 + 0.05,
          swaySpeed: _random.nextDouble() * 2 + 1,
          rotation: _random.nextDouble() * 2 * pi,
          rotationSpeed: _random.nextDouble() * 0.5 + 0.2,
          opacity: _random.nextDouble() * 0.4 + 0.3,
        ),
      );
    }
  }

  @override
  void dispose() {
    _petalController.dispose();
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.priorityP1.withValues(alpha: 0.15),
            AppColors.primaryLight.withValues(alpha: 0.25),
            AppColors.priorityP0.withValues(alpha: 0.1),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryLight.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 樱花飘落动画层
            AnimatedBuilder(
              animation: _petalController,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(double.infinity, 100),
                  painter: _SakuraPainter(
                    petals: _petals,
                    progress: _petalController.value,
                  ),
                );
              },
            ),

            // 装饰性光晕
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.priorityP1.withValues(alpha: 0.2),
                      AppColors.priorityP1.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // 底部装饰光晕
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.priorityP0.withValues(alpha: 0.15),
                      AppColors.priorityP0.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // 名言内容
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Center(
                  child: AnimatedBuilder(
                    animation: _breathAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _breathAnimation.value,
                        child: child,
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 装饰性引号
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildPetalDot(),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.format_quote,
                              size: 16,
                              color: AppColors.priorityP0.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildPetalDot(),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // 名言文字
                        Text(
                          widget.quote,
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary.withValues(
                              alpha: 0.85,
                            ),
                            height: 1.6,
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // 底部装饰
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildPetalDot(size: 4),
                            const SizedBox(width: 6),
                            _buildPetalDot(size: 6),
                            const SizedBox(width: 6),
                            _buildPetalDot(size: 4),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetalDot({double size = 5}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.priorityP1.withValues(alpha: 0.6),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// 樱花花瓣数据
class _SakuraPetal {
  double x;
  double y;
  final double size;
  final double speed;
  final double swayAmount;
  final double swaySpeed;
  double rotation;
  final double rotationSpeed;
  final double opacity;

  _SakuraPetal({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.swayAmount,
    required this.swaySpeed,
    required this.rotation,
    required this.rotationSpeed,
    required this.opacity,
  });
}

/// 樱花绘制器
class _SakuraPainter extends CustomPainter {
  final List<_SakuraPetal> petals;
  final double progress;

  _SakuraPainter({required this.petals, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (var petal in petals) {
      // 计算当前位置
      final currentY = (petal.y + progress * petal.speed) % 1.2 - 0.1;
      final swayOffset =
          sin(progress * petal.swaySpeed * 2 * pi) * petal.swayAmount;
      final currentX = petal.x + swayOffset;
      final currentRotation =
          petal.rotation + progress * petal.rotationSpeed * 2 * pi;

      // 转换为实际坐标
      final x = currentX * size.width;
      final y = currentY * size.height;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(currentRotation);

      // 绘制樱花花瓣形状
      _drawPetal(canvas, petal.size, petal.opacity);

      canvas.restore();
    }
  }

  void _drawPetal(Canvas canvas, double size, double opacity) {
    final paint = Paint()
      ..color = AppColors.priorityP1.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final path = Path();

    // 花瓣形状 - 心形变体
    path.moveTo(0, -size / 2);
    path.quadraticBezierTo(size / 2, -size / 2, size / 2, 0);
    path.quadraticBezierTo(size / 2, size / 3, 0, size / 2);
    path.quadraticBezierTo(-size / 2, size / 3, -size / 2, 0);
    path.quadraticBezierTo(-size / 2, -size / 2, 0, -size / 2);
    path.close();

    canvas.drawPath(path, paint);

    // 添加高光
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.5)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(-size / 6, -size / 6), size / 6, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _SakuraPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
