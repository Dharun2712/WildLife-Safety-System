import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _controller = PageController();
  int _currentPage = 0;
  late AnimationController _bgAnimController;

  final _pages = [
    {
      'icon': '🐾',
      'title': 'AI Wildlife Detection',
      'desc': 'AI-powered cameras detect wildlife in real-time, keeping you informed about nearby animal activity.',
      'gradient': const [Color(0xFF0D2B0F), Color(0xFF1B5E20)],
      'accentColor': AppTheme.safeGreen,
    },
    {
      'icon': '🚨',
      'title': 'Real-time Safety Alerts',
      'desc': 'Receive instant notifications when you\'re near an active wildlife zone. Stay alert, stay safe.',
      'gradient': const [Color(0xFF1A0A00), Color(0xFFBF360C)],
      'accentColor': AppTheme.approachingAmber,
    },
    {
      'icon': '🛡️',
      'title': 'Ranger Protection',
      'desc': 'Professional forest rangers verify AI alerts and manage safety zones to keep you protected.',
      'gradient': const [Color(0xFF0A1929), Color(0xFF1565C0)],
      'accentColor': AppTheme.infoBlue,
    },
  ];

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _bgAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = (_pages[_currentPage]['gradient'] as List<Color>);

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradientColors[0], gradientColors[1], Colors.black],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 8),
                  child: _currentPage < _pages.length - 1
                      ? TextButton(
                          onPressed: () => context.go('/role-select'),
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : const SizedBox(height: 48),
                ),
              ),

              // Pages
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (_, i) => _buildPage(_pages[i], i),
                ),
              ),

              // Page indicators
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == i ? 32 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: _currentPage == i
                            ? LinearGradient(
                                colors: [
                                  (_pages[_currentPage]['accentColor'] as Color),
                                  (_pages[_currentPage]['accentColor'] as Color).withValues(alpha: 0.6),
                                ],
                              )
                            : null,
                        color: _currentPage == i ? null : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),

              // CTA Button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: _currentPage == _pages.length - 1
                          ? AppTheme.emeraldGlow
                          : LinearGradient(colors: [
                              Colors.white.withValues(alpha: 0.15),
                              Colors.white.withValues(alpha: 0.08),
                            ]),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _currentPage == _pages.length - 1
                            ? Colors.transparent
                            : Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          if (_currentPage < _pages.length - 1) {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOutCubic,
                            );
                          } else {
                            context.go('/role-select');
                          }
                        },
                        child: Center(
                          child: Text(
                            _currentPage < _pages.length - 1 ? 'Continue' : 'Get Started',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(Map<String, dynamic> page, int index) {
    final accentColor = page['accentColor'] as Color;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // Icon with glassmorphism container and glow
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.25),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.04),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  page['icon'] as String,
                  style: const TextStyle(fontSize: 64),
                ),
              ),
            ),
          ),

          const Spacer(),

          // Title
          Text(
            page['title'] as String,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            page['desc'] as String,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
