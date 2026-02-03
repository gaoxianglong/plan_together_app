import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// 礼花粒子数据
class ConfettiParticle {
  double x;
  double y;
  double vx; // x方向速度
  double vy; // y方向速度
  double rotation;
  double rotationSpeed;
  double size;
  Color color;
  double opacity;
  int shapeType; // 0: 圆形, 1: 心形, 2: 星形

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
    required this.color,
    required this.shapeType,
    this.opacity = 1.0,
  });
}

/// 礼花动画组件 - Minimal Peach 风格
class ConfettiAnimation extends StatefulWidget {
  final Duration duration;
  final VoidCallback? onComplete;

  const ConfettiAnimation({
    super.key,
    this.duration = const Duration(milliseconds: 3000),
    this.onComplete,
  });

  @override
  State<ConfettiAnimation> createState() => _ConfettiAnimationState();
}

class _ConfettiAnimationState extends State<ConfettiAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<ConfettiParticle> _particles = [];
  final Random _random = Random();

  // Minimal Peach 温柔配色
  static const List<Color> _colors = [
    AppColors.primary,      // 主粉红
    AppColors.priorityP0,   // 深粉红
    AppColors.priorityP1,   // 淡粉红
    AppColors.primaryLight, // 浅粉
    Color(0xFFFFB6C1),      // 浅粉红
    Color(0xFFFFC0CB),      // 粉红
    Colors.white,           // 白色点缀
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _controller.addListener(() {
      _updateParticles();
      if (mounted) setState(() {});
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    // 初始化粒子
    _initParticles();
    _controller.forward();
  }

  void _initParticles() {
    const particleCount = 80; // 减少数量，更精致

    for (int i = 0; i < particleCount; i++) {
      // 从屏幕多个位置飘落
      final startX = _random.nextDouble();
      final startY = -0.1 - _random.nextDouble() * 0.3; // 从顶部上方开始
      
      _particles.add(
        ConfettiParticle(
          x: startX,
          y: startY,
          vx: (_random.nextDouble() - 0.5) * 0.005, // 轻微水平飘动
          vy: 0.003 + _random.nextDouble() * 0.004, // 缓慢下落
          rotation: _random.nextDouble() * 2 * pi,
          rotationSpeed: (_random.nextDouble() - 0.5) * 0.08,
          size: 6 + _random.nextDouble() * 10,
          color: _colors[_random.nextInt(_colors.length)],
          shapeType: _random.nextInt(3), // 随机形状
          opacity: 0.7 + _random.nextDouble() * 0.3,
        ),
      );
    }
  }

  void _updateParticles() {
    final progress = _controller.value;

    for (final particle in _particles) {
      // 更新位置 - 缓慢飘落
      particle.x += particle.vx + sin(progress * pi * 4 + particle.rotation) * 0.001;
      particle.y += particle.vy;

      // 轻微摆动效果
      particle.vx += ((_random.nextDouble() - 0.5) * 0.0005);

      // 旋转
      particle.rotation += particle.rotationSpeed;

      // 渐隐效果（后1/3开始渐隐）
      if (progress > 0.7) {
        particle.opacity = (1.0 - progress) / 0.3 * particle.opacity.clamp(0.0, 1.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ConfettiPainter(particles: _particles),
      ),
    );
  }
}

/// 礼花绘制器 - 绘制心形、圆形、星形
class _ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;

  _ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      if (particle.opacity <= 0) continue;

      final paint = Paint()
        ..color = particle.color.withValues(alpha: particle.opacity)
        ..style = PaintingStyle.fill;

      final x = particle.x * size.width;
      final y = particle.y * size.height;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation);

      switch (particle.shapeType) {
        case 0:
          // 圆形
          canvas.drawCircle(Offset.zero, particle.size * 0.4, paint);
          break;
        case 1:
          // 心形
          _drawHeart(canvas, particle.size * 0.5, paint);
          break;
        case 2:
          // 星形
          _drawStar(canvas, particle.size * 0.4, paint);
          break;
      }

      canvas.restore();
    }
  }

  void _drawHeart(Canvas canvas, double size, Paint paint) {
    final path = Path();
    
    // 心形路径
    path.moveTo(0, size * 0.3);
    path.cubicTo(
      -size * 0.5, -size * 0.3,
      -size, size * 0.2,
      0, size,
    );
    path.cubicTo(
      size, size * 0.2,
      size * 0.5, -size * 0.3,
      0, size * 0.3,
    );
    
    canvas.drawPath(path, paint);
  }

  void _drawStar(Canvas canvas, double size, Paint paint) {
    final path = Path();
    const int points = 5;
    final double outerRadius = size;
    final double innerRadius = size * 0.4;

    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = (i * pi / points) - pi / 2;
      final x = cos(angle) * radius;
      final y = sin(angle) * radius;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
