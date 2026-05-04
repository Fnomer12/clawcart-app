import 'dart:async';
import 'package:flutter/material.dart';
import '../auth/auth_gate.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  bool showImage = true;
  int dotCount = 0;
  Timer? dotTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    // Show full splash image first for 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      setState(() {
        showImage = false;
      });

      _controller.forward();

      dotTimer = Timer.periodic(const Duration(milliseconds: 420), (_) {
        if (!mounted) return;
        setState(() {
          dotCount = (dotCount + 1) % 4;
        });
      });
    });

    // Total splash/loading time = 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 700),
          pageBuilder: (_, __, ___) => const AuthGate(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    dotTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dots = '.' * dotCount;

    return Scaffold(
      backgroundColor: const Color(0xFF09090D),
      body: showImage
    ? LayoutBuilder(
        builder: (context, constraints) {
          return Image.asset(
            'assets/splash/clawcart_splash.png',
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          );
        },
      )
          : _buildPremiumLoader(dots),
    );
  }

  Widget _buildPremiumLoader(String dots) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: -120,
          left: -80,
          child: _GlowCircle(
            size: 260,
            color: const Color(0xFFFF5A52).withValues(alpha: 0.22),
          ),
        ),
        Positioned(
          bottom: -130,
          right: -90,
          child: _GlowCircle(
            size: 300,
            color: const Color(0xFFFFA000).withValues(alpha: 0.16),
          ),
        ),
        Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5A52).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFFFF5A52).withValues(alpha: 0.35),
                          blurRadius: 35,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shopping_cart_checkout_rounded,
                      color: Color(0xFFFF5A52),
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 26),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      'ClawCart$dots',
                      key: ValueKey(dotCount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Smart picks. Better buys.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.58),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 34),
                  Container(
                    width: 90,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeOutCubic,
                        width: 28 + (dotCount * 18),
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5A52),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF5A52)
                                  .withValues(alpha: 0.65),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 90,
            spreadRadius: 45,
          ),
        ],
      ),
    );
  }
}