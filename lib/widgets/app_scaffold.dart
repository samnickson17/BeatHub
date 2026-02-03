import 'dart:ui';
import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;

  const AppScaffold({
    super.key,
    required this.child,
    this.appBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: Stack(
        children: [
          // 🌑 BACKGROUND GRADIENT
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0E0E0E),
                  Color(0xFF1A1A1A),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 🔮 PURPLE GLOW
          Positioned(
            top: -120,
            left: -100,
            child: _glowCircle(260, Colors.deepPurple),
          ),

          // 🔥 ORANGE GLOW
          Positioned(
            bottom: -140,
            right: -100,
            child: _glowCircle(300, Colors.deepOrange),
          ),

          // 💎 GLASS LAYER
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              color: Colors.white.withOpacity(0.03),
            ),
          ),

          // 📦 PAGE CONTENT
          SafeArea(
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _glowCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.55),
      ),
    );
  }
}
