import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../config/theme.dart';

/// Pop-up Alert Modal displayed when an animal is detected.
/// Displays animal type, emoji, confidence %, verification status badge,
/// snapshot image from camera, location info, AI disclaimer, and action buttons.
class DetectionAlertModal extends StatelessWidget {
  final Map<String, dynamic> detection;
  final VoidCallback? onViewOnMap;
  final VoidCallback? onAcknowledge;
  final bool isRanger;

  const DetectionAlertModal({
    super.key,
    required this.detection,
    this.onViewOnMap,
    this.onAcknowledge,
    this.isRanger = false,
  });

  /// Static helper to trigger the modal anywhere in the app
  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> detection,
    VoidCallback? onViewOnMap,
    VoidCallback? onAcknowledge,
    bool isRanger = false,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return DetectionAlertModal(
          detection: detection,
          onViewOnMap: onViewOnMap,
          onAcknowledge: onAcknowledge,
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

    final isVerified = verificationStatus == 'VERIFIED' || verificationStatus == 'ACTIVE';
    final emoji = AppConstants.animalEmojis[animalType] ?? '🐾';
    final animalName = AppConstants.animalNames[animalType] ?? animalType.toUpperCase();

    final cameraId = detection['camera_id'] ?? 'C-01';
    final lat = (detection['latitude'] is num) ? (detection['latitude'] as num).toDouble() : 11.5690;
    final lng = (detection['longitude'] is num) ? (detection['longitude'] as num).toDouble() : 76.6320;
    final timestamp = detection['timestamp'] ?? DateTime.now().toIso8601String().substring(11, 19);

    // Live Snapshot URL from Sentinel AI Camera
    final snapshotUrl = '${AppConstants.apiBaseUrl.replaceAll('8000', '8501')}/api/camera/snapshot';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 16,
      backgroundColor: Colors.grey.shade900,
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Threat Banner Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: isVerified ? Colors.red.shade900.withOpacity(0.4) : Colors.amber.shade900.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isVerified ? Colors.redAccent : Colors.amberAccent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$animalName DETECTED',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isVerified ? Colors.green : Colors.amber.shade700,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isVerified ? '✓ VERIFIED THREAT' : '⚠️ NEEDS VERIFICATION',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$confidencePct% Confidence',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Captured Image Snapshot Frame
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 190,
                  color: Colors.black,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        snapshotUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade800,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(emoji, style: const TextStyle(fontSize: 48)),
                                const SizedBox(height: 8),
                                const Text(
                                  'Camera Feed Snapshot Captured',
                                  style: TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                                Text(
                                  'Sentinel $cameraId • Zone A',
                                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      // HUD Overlay Tag
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.videocam, color: Colors.greenAccent, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                'CAM $cameraId • LIVE EDGE SNAPSHOT',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Telemetry Info Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF212121),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF424242)),
                ),
                child: Column(
                  children: [
                    _infoRow(Icons.location_on, 'Location:', 'Zone A (Mudumalai Perimeter)'),
                    const SizedBox(height: 4),
                    _infoRow(Icons.my_location, 'Coordinates:', '${lat.toStringAsFixed(4)}° N, ${lng.toStringAsFixed(4)}° E'),
                    const SizedBox(height: 4),
                    _infoRow(Icons.access_time, 'Time Captured:', timestamp),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Mandatory AI Disclaimer Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade900.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade700.withOpacity(0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amberAccent, size: 14),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'AI identification may be inaccurate. Ranger verification is authoritative.',
                        style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (onAcknowledge != null) onAcknowledge!();
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(isRanger ? 'Acknowledge' : 'Dismiss'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isVerified ? AppTheme.dangerRed : AppTheme.forestGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (onViewOnMap != null) onViewOnMap!();
                      },
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text('View on Map'),
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

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade400, size: 14),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
