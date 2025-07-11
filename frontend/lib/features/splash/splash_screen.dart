import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  bool _showHeadline = false;
  bool _showSub = false;

  @override
  void initState() {
    super.initState();

    _fadeController =
    AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showHeadline = true);
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showSub = true);
    });

    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedWaveBackground(),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔵 Circular Logo with border
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/icons/app_icon.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeTransition(
                    opacity: _fadeController,
                    child: Lottie.asset(
                      'assets/animations/mental_health.json',
                      width: 200,
                      repeat: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_showHeadline)
                    AnimatedTextKit(
                      isRepeatingAnimation: false,
                      animatedTexts: [
                        TyperAnimatedText(
                          'Perinatal Mental Health Directory',
                          textStyle: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003049),
                          ),
                          speed: Duration(milliseconds: 60),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  if (_showSub)
                    AnimatedTextKit(
                      isRepeatingAnimation: false,
                      animatedTexts: [
                        TyperAnimatedText(
                          'Your mental well-being matters',
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.normal,
                            color: Colors.black54,
                          ),
                          speed: Duration(milliseconds: 50),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedWaveBackground extends StatefulWidget {
  const AnimatedWaveBackground({super.key});

  @override
  State<AnimatedWaveBackground> createState() => _AnimatedWaveBackgroundState();
}

class _AnimatedWaveBackgroundState extends State<AnimatedWaveBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController =
    AnimationController(vsync: this, duration: const Duration(seconds: 5))
      ..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return CustomPaint(
          painter: WavePainter(_waveController.value),
          size: MediaQuery.of(context).size,
        );
      },
    );
  }
}

class WavePainter extends CustomPainter {
  final double animationValue;
  WavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final path1 = Path();
    paint.color = const Color(0xFFB2EBF2).withOpacity(0.6);
    path1.moveTo(0, size.height * 0.8);
    for (double i = 0; i <= size.width; i++) {
      path1.lineTo(
        i,
        size.height * 0.8 +
            10 * (0.5 * (1 + sin(i / size.width * 2 * pi + animationValue * 6))),
      );
    }
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint);

    final path2 = Path();
    paint.color = const Color(0xFFE0F7FA).withOpacity(0.6);
    path2.moveTo(0, size.height * 0.85);
    for (double i = 0; i <= size.width; i++) {
      path2.lineTo(
        i,
        size.height * 0.85 + 8 * 0.5 * (1 + cos(i / size.width * 2 * pi + animationValue * 4)),
      );

    }
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}