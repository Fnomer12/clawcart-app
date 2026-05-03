import 'dart:async';
import 'package:flutter/material.dart';
import '../auth/auth_gate.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  int dotCount = 0;
  late Timer dotTimer;

  @override
  void initState() {
    super.initState();

    // Animate dots
    dotTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      setState(() {
        dotCount = (dotCount + 1) % 4; // 0 → 3 dots
      });
    });

    // Navigate after 2.5 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => const AuthGate(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    dotTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dots = '.' * dotCount;

    return Scaffold(
      backgroundColor: const Color(0xFF09090D),
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            'ClawCart$dots',
            key: ValueKey(dotCount),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF5A52),
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}