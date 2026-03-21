// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.home_rounded,
                color: Color(0xFF3B82F6),
                size: 40,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(end: 1.05, duration: 1200.ms, curve: Curves.easeInOut),
            const SizedBox(height: 24),
            const Text(
              'Smart Home',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            const Text(
              'Đang kết nối...',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }
}
