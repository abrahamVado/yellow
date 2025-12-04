import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../../../app/theme/theme_provider.dart';

/// Shared coral background + infinite wavy animation.
class AuthWaveBackground extends ConsumerStatefulWidget {
  final Widget child;

  const AuthWaveBackground({super.key, required this.child});

  @override
  ConsumerState<AuthWaveBackground> createState() => _AuthWaveBackgroundState();
}

class _AuthWaveBackgroundState extends ConsumerState<AuthWaveBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(themeConfigProvider);
    
    // Default colors if loading/error (though usually parent handles loading)
    final waveColor1 = config.waveColor1;
    final waveColor2 = config.waveColor2;

    return Scaffold(
      backgroundColor: waveColor2,
      body: Stack(
        children: [
          // Solid coral (or gradient) background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    waveColor1,
                    waveColor2,
                  ],
                ),
              ),
            ),
          ),

          // Animated Waves
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _WavePainter(
                    animationValue: _controller.value,
                    color: Colors.white.withOpacity(0.2),
                  ),
                );
              },
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _WavePainter(
                    animationValue: _controller.value + 0.5,
                    color: Colors.white.withOpacity(0.1),
                    offset: 50.0,
                  ),
                );
              },
            ),
          ),

          // Content
          SafeArea(
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double animationValue;
  final Color color;
  final double offset;

  _WavePainter({
    required this.animationValue,
    required this.color,
    this.offset = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    final waveHeight = 40.0;
    final waveLength = size.width;
    final yOffset = size.height * 0.85; // Waves at the bottom

    path.moveTo(0, yOffset);

    for (double x = 0; x <= size.width; x++) {
      final dx = x / waveLength * 2 * math.pi;
      final dy = math.sin(dx + (animationValue * 2 * math.pi) + offset) * waveHeight;
      path.lineTo(x, yOffset + dy);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
