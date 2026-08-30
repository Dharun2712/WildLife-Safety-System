import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text('🌲', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 16),
              const Text(
                'Welcome to\nForestGuard',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.2),
              ),
              const SizedBox(height: 8),
              Text(
                'Select your role to continue',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
              ),
              const Spacer(),
              // Tourist Card
              _RoleCard(
                icon: '🏕️',
                title: 'Tourist',
                description: 'View safety zones, receive wildlife alerts, and stay protected during your forest visit.',
                color: AppTheme.forestGreen,
                onTap: () => context.go('/login?role=tourist'),
              ),
              const SizedBox(height: 16),
              // Ranger Card
              _RoleCard(
                icon: '🛡️',
                title: 'Ranger',
                description: 'Monitor wildlife detections, manage alerts, and coordinate tourist safety operations.',
                color: const Color(0xFF1565C0),
                onTap: () => context.go('/login?role=ranger'),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(child: Text(icon, style: const TextStyle(fontSize: 28))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.7), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
