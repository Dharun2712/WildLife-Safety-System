import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOut),
    );

    _mainController.forward();

    // Auth check delay
    Future.delayed(const Duration(seconds: 3), () async {
      await ref.read(authProvider.notifier).checkAuth();
      if (!mounted) return;
      final auth = ref.read(authProvider);
      if (auth.isAuthenticated) {
        if (auth.role == 'ranger' || auth.role == 'admin') {
          context.go('/ranger');
        } else {
          context.go('/tourist');
        }
      } else {
        context.go('/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage('https://images.unsplash.com/photo-1542273917363-3b1817f69a2d?auto=format&fit=crop&w=1200&q=80'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.white70, BlendMode.lighten),
          ),
        ),
        child: Stack(
          children: [
            // Soft white gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.7),
                    Colors.white.withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),

            // Main Content
            Center(
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // White Circular Shield Logo Container (Image 3)
                        Container(
                          width: 140,
                          height: 140,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 24,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shield_rounded, size: 54, color: Color(0xFF0E6C4A)),
                                SizedBox(height: 4),
                                Text(
                                  'ForestGuard',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF012D1D)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Title: ForestGuard (Image 3)
                        const Text(
                          'ForestGuard',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF012D1D),
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Motto Glass Pill Container (Image 3)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          margin: const EdgeInsets.symmetric(horizontal: 36),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF5F7).withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0E6C4A).withValues(alpha: 0.08),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: const Text(
                            'Stay aware. Stay safe.\nRespect wildlife.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0E6C4A),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Progress Indicator & INITIALIZING SYSTEMS (Image 3)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF012D1D),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'INITIALIZING SYSTEMS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.black45,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
