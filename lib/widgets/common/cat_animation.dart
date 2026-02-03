import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// 趴在按钮上的小猫动画组件
/// 风格：极简、温柔、治愈，符合 Minimal Peach 主题
class CatAnimation extends StatefulWidget {
  /// 是否被按下
  final bool isPressed;
  /// 猫咪大小（宽度，高度自动按比例计算）
  final double size;

  const CatAnimation({
    super.key,
    this.isPressed = false,
    this.size = 52,
  });

  @override
  State<CatAnimation> createState() => _CatAnimationState();
}

class _CatAnimationState extends State<CatAnimation>
    with TickerProviderStateMixin {
  // 呼吸动画控制器
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  // 尾巴摆动动画控制器
  late AnimationController _tailController;
  late Animation<double> _tailAnimation;

  // 打哈欠动画控制器
  late AnimationController _yawnController;
  late Animation<double> _yawnAnimation;

  // 按压动画控制器
  late AnimationController _pressController;
  late Animation<double> _pressAnimation;

  // 状态标记
  bool _isTailWagging = false;
  bool _isYawning = false;

  @override
  void initState() {
    super.initState();
    _initBreathAnimation();
    _initTailAnimation();
    _initYawnAnimation();
    _initPressAnimation();
    _startRandomTailWag();
    _startRandomYawn();
  }

  void _initBreathAnimation() {
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _breathAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
    _breathController.repeat(reverse: true);
  }

  void _initTailAnimation() {
    _tailController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _tailAnimation = Tween<double>(begin: -0.2, end: 0.2).animate(
      CurvedAnimation(parent: _tailController, curve: Curves.easeInOut),
    );
  }

  void _initYawnAnimation() {
    _yawnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    // 打哈欠动画曲线：慢慢张开 -> 保持 -> 慢慢闭合
    _yawnAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 35,
      ),
    ]).animate(_yawnController);
  }

  void _initPressAnimation() {
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _pressAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  // 随机触发尾巴摆动（低频，每6-12秒一次）
  void _startRandomTailWag() {
    Future.delayed(Duration(seconds: 6 + Random().nextInt(7)), () {
      if (mounted && !_isTailWagging) {
        _wagTail();
        _startRandomTailWag();
      }
    });
  }

  // 随机触发打哈欠（低频，每15-25秒一次）
  void _startRandomYawn() {
    Future.delayed(Duration(seconds: 15 + Random().nextInt(11)), () {
      if (mounted && !_isYawning) {
        _yawn();
        _startRandomYawn();
      }
    });
  }

  void _wagTail() {
    if (!mounted) return;
    _isTailWagging = true;
    // 尾巴摆动两次
    _tailController.forward().then((_) {
      if (mounted) {
        _tailController.reverse().then((_) {
          if (mounted) {
            _tailController.forward().then((_) {
              if (mounted) {
                _tailController.reverse().then((_) {
                  _isTailWagging = false;
                });
              }
            });
          }
        });
      }
    });
  }

  void _yawn() {
    if (!mounted) return;
    _isYawning = true;
    _yawnController.forward(from: 0).then((_) {
      if (mounted) {
        _isYawning = false;
      }
    });
  }

  @override
  void didUpdateWidget(CatAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 处理按压状态变化
    if (widget.isPressed != oldWidget.isPressed) {
      if (widget.isPressed) {
        _pressController.forward();
        _wagTail();
      } else {
        _pressController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    _tailController.dispose();
    _yawnController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _breathAnimation,
        _tailAnimation,
        _yawnAnimation,
        _pressAnimation,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pressAnimation.value,
          alignment: Alignment.bottomCenter,
          child: Transform.translate(
            // 呼吸起伏效果
            offset: Offset(0, -_breathAnimation.value * 2),
            child: SizedBox(
              width: widget.size,
              height: widget.size * 0.7,
              child: CustomPaint(
                painter: _CatPainter(
                  tailAngle: _tailAnimation.value,
                  breathOffset: _breathAnimation.value,
                  yawnProgress: _yawnAnimation.value,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Minimal Peach 风格小猫绘制器（带细黑线描边）
class _CatPainter extends CustomPainter {
  final double tailAngle;
  final double breathOffset;
  final double yawnProgress;

  _CatPainter({
    required this.tailAngle,
    required this.breathOffset,
    required this.yawnProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 主色调 - Minimal Peach 配色
    final bodyColor = AppColors.primaryLight; // 淡粉色身体
    final accentColor = AppColors.primary; // 粉红色重点
    final innerEarColor = AppColors.primary.withValues(alpha: 0.3);
    const outlineColor = Color(0xFF333333); // 细黑线描边

    final bodyPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final accentPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    final innerEarPaint = Paint()
      ..color = innerEarColor
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final bodyY = size.height * 0.6;

    // === 绘制尾巴 ===
    canvas.save();
    canvas.translate(centerX + size.width * 0.32, bodyY - size.height * 0.05);
    canvas.rotate(tailAngle);
    
    final tailPath = Path();
    tailPath.moveTo(0, 0);
    tailPath.quadraticBezierTo(
      size.width * 0.2,
      -size.height * 0.3,
      size.width * 0.15,
      -size.height * 0.5,
    );
    
    // 尾巴填充
    final tailFillPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(tailPath, tailFillPaint);
    
    // 尾巴描边
    final tailOutlinePaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(tailPath, tailOutlinePaint);
    canvas.restore();

    // === 绘制趴着的猫身体 ===
    final bodyRect = Rect.fromCenter(
      center: Offset(centerX, bodyY),
      width: size.width * 0.78,
      height: size.height * 0.42,
    );
    canvas.drawOval(bodyRect, bodyPaint);
    canvas.drawOval(bodyRect, outlinePaint);

    // === 绘制头部 ===
    final headRadius = size.width * 0.3;
    final headX = centerX - size.width * 0.06;
    final headY = bodyY - size.height * 0.18 - breathOffset * 1.5;
    canvas.drawCircle(Offset(headX, headY), headRadius, bodyPaint);
    canvas.drawCircle(Offset(headX, headY), headRadius, outlinePaint);

    // === 绘制耳朵 ===
    // 左耳外部
    final leftEarPath = Path();
    leftEarPath.moveTo(headX - headRadius * 0.55, headY - headRadius * 0.2);
    leftEarPath.lineTo(headX - headRadius * 0.85, headY - headRadius * 1.15);
    leftEarPath.lineTo(headX - headRadius * 0.1, headY - headRadius * 0.65);
    leftEarPath.close();
    canvas.drawPath(leftEarPath, bodyPaint);
    canvas.drawPath(leftEarPath, outlinePaint);

    // 左耳内部
    final leftInnerEarPath = Path();
    leftInnerEarPath.moveTo(headX - headRadius * 0.5, headY - headRadius * 0.35);
    leftInnerEarPath.lineTo(headX - headRadius * 0.7, headY - headRadius * 0.9);
    leftInnerEarPath.lineTo(headX - headRadius * 0.2, headY - headRadius * 0.55);
    leftInnerEarPath.close();
    canvas.drawPath(leftInnerEarPath, innerEarPaint);

    // 右耳外部
    final rightEarPath = Path();
    rightEarPath.moveTo(headX + headRadius * 0.55, headY - headRadius * 0.2);
    rightEarPath.lineTo(headX + headRadius * 0.85, headY - headRadius * 1.15);
    rightEarPath.lineTo(headX + headRadius * 0.1, headY - headRadius * 0.65);
    rightEarPath.close();
    canvas.drawPath(rightEarPath, bodyPaint);
    canvas.drawPath(rightEarPath, outlinePaint);

    // 右耳内部
    final rightInnerEarPath = Path();
    rightInnerEarPath.moveTo(headX + headRadius * 0.5, headY - headRadius * 0.35);
    rightInnerEarPath.lineTo(headX + headRadius * 0.7, headY - headRadius * 0.9);
    rightInnerEarPath.lineTo(headX + headRadius * 0.2, headY - headRadius * 0.55);
    rightInnerEarPath.close();
    canvas.drawPath(rightInnerEarPath, innerEarPaint);

    // === 绘制脸部特征 ===
    final eyePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    // 眼睛（打哈欠时眯得更紧）
    final eyeSquint = yawnProgress * 0.08;
    
    // 左眼
    final leftEyePath = Path();
    leftEyePath.moveTo(headX - headRadius * 0.38, headY + headRadius * 0.05);
    leftEyePath.quadraticBezierTo(
      headX - headRadius * 0.22,
      headY + headRadius * (0.2 - eyeSquint),
      headX - headRadius * 0.06,
      headY + headRadius * 0.05,
    );
    canvas.drawPath(leftEyePath, eyePaint);

    // 右眼
    final rightEyePath = Path();
    rightEyePath.moveTo(headX + headRadius * 0.06, headY + headRadius * 0.05);
    rightEyePath.quadraticBezierTo(
      headX + headRadius * 0.22,
      headY + headRadius * (0.2 - eyeSquint),
      headX + headRadius * 0.38,
      headY + headRadius * 0.05,
    );
    canvas.drawPath(rightEyePath, eyePaint);

    // 小鼻子（倒三角）
    final nosePath = Path();
    nosePath.moveTo(headX, headY + headRadius * 0.28);
    nosePath.lineTo(headX - headRadius * 0.1, headY + headRadius * 0.4);
    nosePath.lineTo(headX + headRadius * 0.1, headY + headRadius * 0.4);
    nosePath.close();
    canvas.drawPath(nosePath, accentPaint);

    // 嘴巴/打哈欠
    if (yawnProgress > 0.01) {
      // 打哈欠时张开的嘴巴（椭圆形）
      final mouthWidth = headRadius * 0.35 * yawnProgress;
      final mouthHeight = headRadius * 0.45 * yawnProgress;
      final mouthY = headY + headRadius * 0.55;
      
      // 嘴巴内部（深粉色）
      final mouthInnerPaint = Paint()
        ..color = AppColors.primary.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(headX, mouthY),
          width: mouthWidth,
          height: mouthHeight,
        ),
        mouthInnerPaint,
      );
      
      // 嘴巴描边
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(headX, mouthY),
          width: mouthWidth,
          height: mouthHeight,
        ),
        outlinePaint,
      );
    }

    // 胡须（加长）
    final whiskerPaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..strokeCap = StrokeCap.round;
    
    final whiskerY = headY + headRadius * 0.35;
    
    // 左边三根胡须（加长到 1.1 倍头部半径）
    canvas.drawLine(
      Offset(headX - headRadius * 0.2, whiskerY - headRadius * 0.08),
      Offset(headX - headRadius * 1.1, whiskerY - headRadius * 0.22),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(headX - headRadius * 0.22, whiskerY),
      Offset(headX - headRadius * 1.15, whiskerY),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(headX - headRadius * 0.2, whiskerY + headRadius * 0.08),
      Offset(headX - headRadius * 1.1, whiskerY + headRadius * 0.22),
      whiskerPaint,
    );
    
    // 右边三根胡须（加长到 1.1 倍头部半径）
    canvas.drawLine(
      Offset(headX + headRadius * 0.2, whiskerY - headRadius * 0.08),
      Offset(headX + headRadius * 1.1, whiskerY - headRadius * 0.22),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(headX + headRadius * 0.22, whiskerY),
      Offset(headX + headRadius * 1.15, whiskerY),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(headX + headRadius * 0.2, whiskerY + headRadius * 0.08),
      Offset(headX + headRadius * 1.1, whiskerY + headRadius * 0.22),
      whiskerPaint,
    );

    // 腮红
    final blushPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(headX - headRadius * 0.5, headY + headRadius * 0.25),
        width: headRadius * 0.35,
        height: headRadius * 0.2,
      ),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(headX + headRadius * 0.5, headY + headRadius * 0.25),
        width: headRadius * 0.35,
        height: headRadius * 0.2,
      ),
      blushPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CatPainter oldDelegate) {
    return oldDelegate.tailAngle != tailAngle ||
        oldDelegate.breathOffset != breathOffset ||
        oldDelegate.yawnProgress != yawnProgress;
  }
}
