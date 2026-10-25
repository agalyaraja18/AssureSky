import 'package:flutter/material.dart';
import '../home/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnim =
        CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6EEFF),
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                ScaleTransition(
                  scale: _scaleAnim,
                  child: const Text(
                    '🌤️',
                    style: TextStyle(fontSize: 90),
                  ),
                ),
                const SizedBox(height: 24),

                // App name
                const Text(
                  'AssureSky',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3A5C),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),

                // Tagline
                const Text(
                  'Know your day; Own your day',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5A7A9A),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 64),

                // Progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 80),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white.withValues(alpha: 0.4),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF00BCD4)),
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Loading label
                const Text(
                  'Loading weather data...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5A7A9A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
