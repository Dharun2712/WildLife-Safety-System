import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../config/theme.dart';
import 'sos_active_dialog.dart';

/// ForestGuard - Proximity Warning & Detection Alert Modal
/// High-fidelity implementation matching exact Google Stitch `proximity_warning` photo spec.
class DetectionAlertModal extends StatelessWidget {
  final Map<String, dynamic> detection;
  final VoidCallback? onViewOnMap;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onTriggerSOS;
  final bool isRanger;

  const DetectionAlertModal({
    super.key,
    required this.detection,
    this.onViewOnMap,
    this.onAcknowledge,
    this.onTriggerSOS,
    this.isRanger = false,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> detection,
    VoidCallback? onViewOnMap,
    VoidCallback? onAcknowledge,
    VoidCallback? onTriggerSOS,
    bool isRanger = false,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (ctx, anim, secondaryAnim) {
        return DetectionAlertModal(
          detection: detection,
          onViewOnMap: onViewOnMap,
          onAcknowledge: onAcknowledge,
          onTriggerSOS: onTriggerSOS,
          isRanger: isRanger,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final animalType = (detection['animal_type'] ?? 'wildlife').toString().toLowerCase();
    final confidence = (detection['confidence'] is num)
        ? (detection['confidence'] as num).toDouble()
        : 0.98;
    final confidencePct = (confidence * 100).round();
    final animalName = AppConstants.animalNames[animalType] ?? animalType.toUpperCase();
    final distanceMeters = detection['distance_meters'] ?? 450;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 24,
      backgroundColor: const Color(0xFF1E2420),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2420),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.error.withValues(alpha: 0.8),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.error.withValues(alpha: 0.25),
              blurRadius: 36,
              spreadRadius: 4,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Proximity Warning Header
              const Row(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: AppTheme.error,
                    size: 28,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'PROXIMITY WARNING',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.error,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Wildlife Card Container
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFDAD6),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.error.withValues(alpha: 0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.pets_rounded,
                          color: Color(0xFF93000A),
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$animalName Detected',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                'Distance: ${distanceMeters}m',
                                style: const TextStyle(
                                  color: Color(0xFFFF6B6B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Text('  •  ', style: TextStyle(color: Colors.white38, fontSize: 12)),
                              Text(
                                'Confidence: $confidencePct%',
                                style: const TextStyle(
                                  color: Color(0xFFA0F4C8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Immediate Actions Checklist
              const Text(
                'IMMEDIATE ACTIONS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white54,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),

              _buildActionTile(
                icon: Icons.directions_walk_rounded,
                text: 'Stay on the designated trail.',
                iconColor: const Color(0xFFFFB703),
              ),
              const SizedBox(height: 8),
              _buildActionTile(
                icon: Icons.do_not_step_rounded,
                text: 'Do not run or make sudden movements.',
                iconColor: const Color(0xFFFF6B6B),
              ),
              const SizedBox(height: 8),
              _buildActionTile(
                icon: Icons.volume_up_rounded,
                text: 'Keep noise levels steady.',
                iconColor: const Color(0xFFA0F4C8),
              ),

              const SizedBox(height: 22),

              // Trigger SOS Red Button
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    if (onTriggerSOS != null) {
                      onTriggerSOS!();
                    } else {
                      SOSActiveDialog.show(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    elevation: 6,
                  ),
                  icon: const Text('SOS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white)),
                  label: const Text(
                    'TRIGGER SOS',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.8),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Notify Ranger Station Button
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    if (onViewOnMap != null) onViewOnMap!();
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFF27312A),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFA0F4C8), width: 1.5),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFFA0F4C8), size: 20),
                  label: const Text(
                    'Notify Ranger Station',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Dismiss Link
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (onAcknowledge != null) onAcknowledge!();
                  },
                  child: const Text(
                    'Dismiss Alert (I am safe)',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String text,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
