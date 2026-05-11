import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/providers/app_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _particleController;
  late AnimationController _exitController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _taglineFade;
  late Animation<double> _taglineSlide;
  late Animation<double> _exitScale;
  late Animation<double> _exitOpacity;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _logoController,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _logoController,
          curve: const Interval(0.5, 1.0, curve: Curves.easeOut)),
    );
    _taglineSlide = Tween<double>(begin: 0.3, end: 0.0).animate(
      CurvedAnimation(
          parent: _logoController,
          curve: const Interval(0.5, 1.0, curve: Curves.easeOutExpo)),
    );
    _exitScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _particleController.forward();
    await Future.delayed(const Duration(milliseconds: 1400));
    _exitController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) _navigate();
  }

  void _navigate() {
    final settings = ref.read(settingsProvider);
    if (!settings.onboardingComplete) {
      Navigator.of(context).pushReplacementNamed('/onboarding');
    } else if (settings.appLockEnabled) {
      Navigator.of(context).pushReplacementNamed('/lock');
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _particleController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _exitController,
        builder: (context, child) => Opacity(
          opacity: _exitOpacity.value,
          child: Transform.scale(scale: _exitScale.value, child: child),
        ),
        child: Container(
          decoration: const BoxDecoration(),
          child: Stack(
            children: [
              // Particle burst
              AnimatedBuilder(
                animation: _particleController,
                builder: (context, _) => CustomPaint(
                  painter: _ParticlePainter(
                    progress: _particleController.value,
                    isDark: isDark,
                  ),
                  size: Size.infinite,
                ),
              ),
              // Logo & text
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _logoController,
                      builder: (context, _) => Transform.scale(
                        scale: _logoScale.value,
                        child: Opacity(
                          opacity: _logoOpacity.value,
                          child: _buildLogo(context, isDark),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimatedBuilder(
                      animation: _logoController,
                      builder: (context, _) => Opacity(
                        opacity: _taglineFade.value,
                        child: Transform.translate(
                          offset: Offset(0, _taglineSlide.value * 30),
                          child: Text(
                            'Track every rupee,\nown your future.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : const Color(0xFF1A1A2E)
                                      .withValues(alpha: 0.6),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context, bool isDark) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(28),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image.asset(
          'assets/icon/app_icon.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  final bool isDark;
  final List<_Particle> _particles;

  _ParticlePainter({required this.progress, required this.isDark})
      : _particles = List.generate(80, (i) {
          final rng = Random(i * 7 + 13);
          return _Particle(
            angle: rng.nextDouble() * 2 * pi,
            speed: rng.nextDouble() * 180 + 60,
            size: rng.nextDouble() * 4 + 1.5,
            color: [
              const Color(0xFF6C63FF),
              const Color(0xFF00D4FF),
              const Color(0xFF00E5A0),
              Colors.white,
            ][rng.nextInt(4)],
          );
        });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (final p in _particles) {
      final dist = p.speed * progress;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      final dx = cos(p.angle) * dist;
      final dy = sin(p.angle) * dist;
      canvas.drawCircle(
        center + Offset(dx, dy),
        p.size * (1 - progress * 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final Color color;
  const _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });
}
