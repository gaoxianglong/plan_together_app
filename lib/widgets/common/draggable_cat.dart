import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/audio_service.dart';

/// 可拖动的猫咪组件
/// 可以被拖动到屏幕任意位置，松手后自动动画回到原位
class DraggableCat extends StatefulWidget {
  /// 猫咪大小
  final double size;
  /// 是否被按下（来自父组件的按钮状态）
  final bool isPressed;
  /// 原始位置（相对于屏幕）
  final Offset homePosition;

  const DraggableCat({
    super.key,
    this.size = 64,
    this.isPressed = false,
    required this.homePosition,
  });

  @override
  State<DraggableCat> createState() => _DraggableCatState();
}

class _DraggableCatState extends State<DraggableCat>
    with TickerProviderStateMixin {
  // 当前偏移量（相对于原位置）
  Offset _offset = Offset.zero;
  // 是否正在拖动
  bool _isDragging = false;

  // 回弹动画控制器
  late AnimationController _returnController;
  Animation<Offset>? _returnAnimation;

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
    _initReturnAnimation();
    _initBreathAnimation();
    _initTailAnimation();
    _initYawnAnimation();
    _initPressAnimation();
    _startRandomTailWag();
    _startRandomYawn();
  }

  void _initReturnAnimation() {
    _returnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _returnController.addListener(() {
      if (_returnAnimation != null) {
        setState(() {
          _offset = _returnAnimation!.value;
        });
      }
    });
    _returnController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _offset = Offset.zero;
        });
      }
    });
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

  void _startRandomTailWag() {
    Future.delayed(Duration(seconds: 6 + Random().nextInt(7)), () {
      if (mounted && !_isTailWagging) {
        _wagTail();
        _startRandomTailWag();
      }
    });
  }

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
  void didUpdateWidget(DraggableCat oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    _returnController.dispose();
    _breathController.dispose();
    _tailController.dispose();
    _yawnController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _returnController.stop();
    setState(() {
      _isDragging = true;
    });
    // 开始拖动时摆尾巴
    _wagTail();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _offset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
    // 动画回到原位
    _returnAnimation = Tween<Offset>(
      begin: _offset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _returnController,
      curve: Curves.elasticOut,
    ));
    _returnController.forward(from: 0);
  }

  void _onTap() {
    // Play cat meow sound when tapped
    AudioService.instance.playCatMeow();
    // Also wag tail when tapped
    _wagTail();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.homePosition.dx + _offset.dx - widget.size / 2,
      top: widget.homePosition.dy + _offset.dy - widget.size * 0.35,
      child: GestureDetector(
        onTap: _onTap,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _breathAnimation,
            _tailAnimation,
            _yawnAnimation,
            _pressAnimation,
          ]),
          builder: (context, child) {
            return Transform.scale(
              scale: _isDragging ? 1.1 : _pressAnimation.value,
              alignment: Alignment.bottomCenter,
              child: Transform.translate(
                offset: Offset(0, -_breathAnimation.value * 2),
                child: SizedBox(
                  width: widget.size,
                  height: widget.size * 0.7,
                  child: CustomPaint(
                    painter: _DraggableCatPainter(
                      tailAngle: _tailAnimation.value,
                      breathOffset: _breathAnimation.value,
                      yawnProgress: _yawnAnimation.value,
                      isDragging: _isDragging,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 可拖动猫咪绘制器
class _DraggableCatPainter extends CustomPainter {
  final double tailAngle;
  final double breathOffset;
  final double yawnProgress;
  final bool isDragging;

  _DraggableCatPainter({
    required this.tailAngle,
    required this.breathOffset,
    required this.yawnProgress,
    required this.isDragging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bodyColor = AppColors.primaryLight;
    final accentColor = AppColors.primary;
    final innerEarColor = AppColors.primary.withValues(alpha: 0.3);
    const outlineColor = Color(0xFF333333);

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

    final tailFillPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(tailPath, tailFillPaint);

    final tailOutlinePaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(tailPath, tailOutlinePaint);
    canvas.restore();

    // === 绘制身体 ===
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
    final leftEarPath = Path();
    leftEarPath.moveTo(headX - headRadius * 0.55, headY - headRadius * 0.2);
    leftEarPath.lineTo(headX - headRadius * 0.85, headY - headRadius * 1.15);
    leftEarPath.lineTo(headX - headRadius * 0.1, headY - headRadius * 0.65);
    leftEarPath.close();
    canvas.drawPath(leftEarPath, bodyPaint);
    canvas.drawPath(leftEarPath, outlinePaint);

    final leftInnerEarPath = Path();
    leftInnerEarPath.moveTo(headX - headRadius * 0.5, headY - headRadius * 0.35);
    leftInnerEarPath.lineTo(headX - headRadius * 0.7, headY - headRadius * 0.9);
    leftInnerEarPath.lineTo(headX - headRadius * 0.2, headY - headRadius * 0.55);
    leftInnerEarPath.close();
    canvas.drawPath(leftInnerEarPath, innerEarPaint);

    final rightEarPath = Path();
    rightEarPath.moveTo(headX + headRadius * 0.55, headY - headRadius * 0.2);
    rightEarPath.lineTo(headX + headRadius * 0.85, headY - headRadius * 1.15);
    rightEarPath.lineTo(headX + headRadius * 0.1, headY - headRadius * 0.65);
    rightEarPath.close();
    canvas.drawPath(rightEarPath, bodyPaint);
    canvas.drawPath(rightEarPath, outlinePaint);

    final rightInnerEarPath = Path();
    rightInnerEarPath.moveTo(headX + headRadius * 0.5, headY - headRadius * 0.35);
    rightInnerEarPath.lineTo(headX + headRadius * 0.7, headY - headRadius * 0.9);
    rightInnerEarPath.lineTo(headX + headRadius * 0.2, headY - headRadius * 0.55);
    rightInnerEarPath.close();
    canvas.drawPath(rightInnerEarPath, innerEarPaint);

    // === 绘制眼睛 ===
    final eyePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final eyeSquint = yawnProgress * 0.08;

    // 拖动时眼睛睁开（惊讶表情）
    if (isDragging) {
      // 睁开的圆眼睛
      final eyeRadius = headRadius * 0.12;
      canvas.drawCircle(
        Offset(headX - headRadius * 0.22, headY + headRadius * 0.05),
        eyeRadius,
        eyePaint,
      );
      canvas.drawCircle(
        Offset(headX + headRadius * 0.22, headY + headRadius * 0.05),
        eyeRadius,
        eyePaint,
      );
      // 眼珠
      final pupilPaint = Paint()
        ..color = outlineColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(headX - headRadius * 0.22, headY + headRadius * 0.05),
        eyeRadius * 0.5,
        pupilPaint,
      );
      canvas.drawCircle(
        Offset(headX + headRadius * 0.22, headY + headRadius * 0.05),
        eyeRadius * 0.5,
        pupilPaint,
      );
    } else {
      // 闭眼微笑
      final leftEyePath = Path();
      leftEyePath.moveTo(headX - headRadius * 0.38, headY + headRadius * 0.05);
      leftEyePath.quadraticBezierTo(
        headX - headRadius * 0.22,
        headY + headRadius * (0.2 - eyeSquint),
        headX - headRadius * 0.06,
        headY + headRadius * 0.05,
      );
      canvas.drawPath(leftEyePath, eyePaint);

      final rightEyePath = Path();
      rightEyePath.moveTo(headX + headRadius * 0.06, headY + headRadius * 0.05);
      rightEyePath.quadraticBezierTo(
        headX + headRadius * 0.22,
        headY + headRadius * (0.2 - eyeSquint),
        headX + headRadius * 0.38,
        headY + headRadius * 0.05,
      );
      canvas.drawPath(rightEyePath, eyePaint);
    }

    // === 鼻子 ===
    final nosePath = Path();
    nosePath.moveTo(headX, headY + headRadius * 0.28);
    nosePath.lineTo(headX - headRadius * 0.1, headY + headRadius * 0.4);
    nosePath.lineTo(headX + headRadius * 0.1, headY + headRadius * 0.4);
    nosePath.close();
    canvas.drawPath(nosePath, accentPaint);

    // === 嘴巴/打哈欠 ===
    if (yawnProgress > 0.01) {
      final mouthWidth = headRadius * 0.35 * yawnProgress;
      final mouthHeight = headRadius * 0.45 * yawnProgress;
      final mouthY = headY + headRadius * 0.55;

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

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(headX, mouthY),
          width: mouthWidth,
          height: mouthHeight,
        ),
        outlinePaint,
      );
    }

    // === 胡须 ===
    final whiskerPaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..strokeCap = StrokeCap.round;

    final whiskerY = headY + headRadius * 0.35;

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

    // === 腮红 ===
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
  bool shouldRepaint(covariant _DraggableCatPainter oldDelegate) {
    return oldDelegate.tailAngle != tailAngle ||
        oldDelegate.breathOffset != breathOffset ||
        oldDelegate.yawnProgress != yawnProgress ||
        oldDelegate.isDragging != isDragging;
  }
}
