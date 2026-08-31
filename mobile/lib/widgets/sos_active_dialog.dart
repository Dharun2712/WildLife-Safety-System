import 'package:flutter/material.dart';
import '../config/theme.dart';

/// ForestGuard - SOS Active Emergency Dialog
/// High-fidelity implementation matching Google Stitch `sos_active` spec.
class SOSActiveDialog extends StatefulWidget {
  const SOSActiveDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (ctx, anim, secondaryAnim) {
        return const SOSActiveDialog();
      },
    );
  }

  @override
  State<SOSActiveDialog> createState() => _SOSActiveDialogState();
}

class _SOSActiveDialogState extends State<SOSActiveDialog> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppTheme.surfaceContainerLowest,
      elevation: 24,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hero Pulsing Emergency Badge
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  final glowScale = 1.0 + (_pulseController.value * 0.15);
                  return Transform.scale(
                    scale: glowScale,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppTheme.error,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.sosShadow,
                      ),
                      child: const Center(
                        child: Icon(Icons.emergency_rounded, color: Colors.white, size: 40),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              const Text(
                'SOS ACTIVE',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.error,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your emergency alert has been broadcasted to all nearby ranger units.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Location Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.my_location_rounded, color: AppTheme.primary, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Zone A · Sector 4', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              SizedBox(height: 2),
                              Text('Lat: 11.5690° N, Lng: 76.6320° E', style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppTheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.local_police_rounded, color: AppTheme.secondary, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nearest Ranger', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              SizedBox(height: 2),
                              Text('Ranger Station B (1.8 km away)', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Response Status Stepper (matching Stitch spec)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Response Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),

                    _stepItem(
                      icon: Icons.check_circle_rounded,
                      color: AppTheme.primary,
                      title: 'SOS Received',
                      time: 'Just now',
                      isDone: true,
                    ),
                    _stepLine(),
                    _stepItem(
                      icon: Icons.check_circle_rounded,
                      color: AppTheme.primary,
                      title: 'Rangers Notified',
                      time: 'Just now',
                      isDone: true,
                    ),
                    _stepLine(),
                    _stepItem(
                      icon: Icons.radar_rounded,
                      color: AppTheme.secondary,
                      title: 'Rangers Responding',
                      time: 'Est. Arrival: 5 mins',
                      isDone: false,
                      isActive: true,
                    ),
                    _stepLine(),
                    _stepItem(
                      icon: Icons.shield_rounded,
                      color: Colors.grey,
                      title: 'Situation Resolved',
                      time: 'Pending',
                      isDone: false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('📞 Calling Ranger Station HQ...')),
                        );
                      },
                      icon: const Icon(Icons.call_rounded, size: 20),
                      label: const Text('Call Ranger HQ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel SOS', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepItem({
    required IconData icon,
    required Color color,
    required String title,
    required String time,
    bool isDone = false,
    bool isActive = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: isActive || isDone ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
              color: isActive || isDone ? AppTheme.onSurface : Colors.grey,
            ),
          ),
        ),
        Text(
          time,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontFamily: 'monospace'),
        ),
      ],
    );
  }

  Widget _stepLine() {
    return Container(
      margin: const EdgeInsets.only(left: 12, top: 2, bottom: 2),
      width: 2,
      height: 14,
      color: AppTheme.outlineVariant,
    );
  }
}
