import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A1F0C), Color(0xFF0D1B0F), Color(0xFF050D06)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),

                // Logo
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: AppTheme.emeraldGlow,
                    boxShadow: AppTheme.glowShadow(AppTheme.safeGreen, intensity: 0.2),
                  ),
                  child: const Center(
                    child: Icon(Icons.forest_rounded, color: Colors.white, size: 30),
                  ),
                ),
                const SizedBox(height: 24),

                // Welcome text
                const Text(
                  'Welcome to',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white54,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.white, Color(0xFFB9F6CA)],
                  ).createShader(bounds),
                  child: const Text(
                    'ForestGuard',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select your role to continue',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),

                const Spacer(),

                // Tourist Card
                _PremiumRoleCard(
                  iconData: Icons.explore_rounded,
                  title: 'Tourist',
                  description: 'View safety zones, receive wildlife alerts, and stay protected during your forest visit.',
                  gradient: AppTheme.emeraldGlow,
                  glowColor: AppTheme.safeGreen,
                  onTap: () => context.go('/login?role=tourist'),
                ),
                const SizedBox(height: 16),

                // Ranger Card
                _PremiumRoleCard(
                  iconData: Icons.security_rounded,
                  title: 'Ranger',
                  description: 'Monitor wildlife detections, manage alerts, and coordinate tourist safety operations.',
                  gradient: AppTheme.rangerGradient,
                  glowColor: AppTheme.rangerBlue,
                  onTap: () => context.go('/login?role=ranger'),
                ),

                const Spacer(),

                // Footer
                Center(
                  child: Text(
                    'Powered by AI • Wildlife Safety Platform',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.2),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumRoleCard extends StatefulWidget {
  final IconData iconData;
  final String title;
  final String description;
  final LinearGradient gradient;
  final Color glowColor;
  final VoidCallback onTap;

  const _PremiumRoleCard({
    required this.iconData,
    required this.title,
    required this.description,
    required this.gradient,
    required this.glowColor,
    required this.onTap,
  });

  @override
  State<_PremiumRoleCard> createState() => _PremiumRoleCardState();
}

class _PremiumRoleCardState extends State<_PremiumRoleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _controller.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _controller.reverse();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _controller.forward();
          widget.onTap();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _controller.forward();
        },
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: _isPressed ? 0.2 : 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: _isPressed ? 0.35 : 0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Center(
                  child: Icon(widget.iconData, color: Colors.white, size: 30),
                ),
              ),
              const SizedBox(width: 16),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
