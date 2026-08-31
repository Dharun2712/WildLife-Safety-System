import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../config/theme.dart';

/// ForestGuard - Proximity Warning & Detection Alert Modal
/// Ranger mode: Shows camera image snapshot.
/// Tourist mode: Words/text guidance only (no image).
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
      transitionDuration: const Duration(milliseconds: 250),
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
        : 0.85;
    final confidencePct = (confidence * 100).round();
    final verificationStatus = (detection['verification_status'] ??
            detection['status'] ??
            (confidence >= 0.70 ? 'VERIFIED' : 'NEEDS_VERIFICATION'))
        .toString()
        .toUpperCase();

    final animalName = AppConstants.animalNames[animalType] ?? animalType;

    final cameraId = detection['camera_id'] ?? 'C-01';
    final lat = (detection['latitude'] is num) ? (detection['latitude'] as num).toDouble() : 11.5690;
    final lng = (detection['longitude'] is num) ? (detection['longitude'] as num).toDouble() : 76.6320;
    final distanceMeters = detection['distance_meters'] ?? (isVerified ? 450 : 850);
    final snapshotUrl = '${AppConstants.apiBaseUrl.replaceAll('8000', '8501')}/api/camera/snapshot';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 24,
      backgroundColor: const Color(0xFF161C18),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: const Color(0xFF161C18),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isVerified ? AppTheme.error.withValues(alpha: 0.6) : AppTheme.tertiaryFixedDim.withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isVerified ? AppTheme.error : AppTheme.tertiaryFixedDim).withValues(alpha: 0.25),
              blurRadius: 40,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: isVerified ? AppTheme.error : AppTheme.tertiaryFixedDim,
                    size: 32,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'PROXIMITY WARNING',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isVerified ? AppTheme.error : AppTheme.tertiaryFixedDim,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // RANGER ONLY: Live Camera Feed Snapshot Image
              if (isRanger) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.black,
                    child: Image.network(
                      snapshotUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.black54,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 32),
                              SizedBox(height: 6),
                              Text('Sentinel Feed Snapshot Standby', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Wildlife Info Card (Text / Words for Tourist, Technical for Ranger)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$animalName Detected',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isVerified ? AppTheme.error : AppTheme.tertiaryFixedDim).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            verificationStatus,
                            style: TextStyle(
                              color: isVerified ? AppTheme.error : AppTheme.tertiaryFixedDim,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Distance: ${distanceMeters}m',
                          style: const TextStyle(
                            color: AppTheme.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const Text(' • ', style: TextStyle(color: Colors.white38)),
                        Text(
                          'Confidence: $confidencePct%',
                          style: const TextStyle(
                            color: AppTheme.secondaryFixedDim,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // TOURIST MODE: Words / Safety Instructions
              if (!isRanger) ...[
                const Text(
                  'SAFETY ADVISORY',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                _actionCheckItem(Icons.directions_walk_rounded, 'Remain calm and stay on designated path', AppTheme.tertiaryFixedDim),
                _actionCheckItem(Icons.do_not_step_rounded, 'Do not run or make sudden movements', AppTheme.error),
                _actionCheckItem(Icons.volume_up_rounded, 'Keep noise levels steady and alert rangers', AppTheme.secondaryFixedDim),
                const SizedBox(height: 16),
              ],

              // Location Telemetry Line
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.my_location_rounded, color: Colors.white54, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Cam $cameraId • Sector 4 (${lat.toStringAsFixed(4)}° N, ${lng.toStringAsFixed(4)}° E)',
                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Action Buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (onTriggerSOS != null) onTriggerSOS!();
                      },
                      icon: const Icon(Icons.sos_rounded, size: 22),
                      label: const Text(
                        'TRIGGER EMERGENCY SOS',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryFixed,
                            side: const BorderSide(color: AppTheme.primaryFixed, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            if (onViewOnMap != null) onViewOnMap!();
                          },
                          icon: const Icon(Icons.map_rounded, size: 16),
                          label: const Text('View Map', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            if (onAcknowledge != null) onAcknowledge!();
                          },
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: Text(isRanger ? 'Verify Alert' : 'Dismiss', style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionCheckItem(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
