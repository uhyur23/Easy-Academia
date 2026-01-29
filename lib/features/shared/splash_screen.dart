import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatelessWidget {
  final String? message;
  const SplashScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Matches app theme background
      body: Stack(
        children: [
          // 1. Full-Screen Responsive Image
          Positioned.fill(
            child: Image.asset(
              'images/splash-image.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              // Adding a subtle fade-in for professional entrance
            ).animate().fadeIn(duration: 800.ms, curve: Curves.easeOut),
          ),

          // 2. Subtle Dark Layer to ensure any overlays or status text are readable
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(40),
                    Colors.transparent,
                    Colors.black.withAlpha(100),
                  ],
                ),
              ),
            ),
          ),

          // 3. Status/Message Area (Cleanly overlayed)
          if (message != null)
            Positioned(
              bottom: 120,
              left: 40,
              right: 40,
              child: Column(
                children: [
                  const SizedBox(
                    width: 150,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation(Colors.white70),
                      minHeight: 1,
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 16),
                  Text(
                    message!.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withAlpha(180),
                      letterSpacing: 2,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fadeIn(delay: 600.ms),
                ],
              ),
            ),

          // 4. Branding Marker
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'KUIBIT CREATIVE TECHNOLOGIES',
                style: TextStyle(
                  color: Colors.white.withAlpha(120),
                  fontSize: 8,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 1.seconds),
        ],
      ),
    );
  }
}
