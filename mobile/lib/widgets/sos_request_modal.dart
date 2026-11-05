import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../services/sound_service.dart';

/// ForestGuard - SOS Request Modal for Rangers
/// Shown when a tourist sends an SOS request.
/// Displays tourist info, location, and Verify/Acknowledge actions.
class SOSRequestModal extends StatelessWidget {
  final Map<String, dynamic> sosData;
  final VoidCallback? onVerify;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onViewOnMap;

  const SOSRequestModal({
    super.key,
    required this.sosData,
    this.onVerify,
    this.onAcknowledge,
    this.onViewOnMap,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> sosData,
    VoidCallback? onVerify,
    VoidCallback? onAcknowledge,
    VoidCallback? onViewOnMap,
  }) {
    SoundService.instance.playAlertSound();
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
        return SOSRequestModal(
          sosData: sosData,
          onVerify: onVerify,
          onAcknowledge: onAcknowledge,
          onViewOnMap: onViewOnMap,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final touristName = sosData['tourist_name'] ?? 'Tourist';
    final lat = (sosData['latitude'] is num)
        ? (sosData['latitude'] as num).toDouble()
        : 11.5690;
    final lng = (sosData['longitude'] is num)
        ? (sosData['longitude'] as num).toDouble()
        : 76.6320;
    final message = sosData['message'] ?? 'Emergency assistance needed!';
    final sosId = sosData['sos_id'] ?? sosData['id'] ?? '';
    final status = (sosData['status'] ?? 'unverified').toString();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 24,
      backgroundColor: const Color(0xFF1A0A0A),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: const Color(0xFF1A0A0A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.error.withValues(alpha: 0.7),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.error.withValues(alpha: 0.3),
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
              // SOS Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.error,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppTheme.sosShadow,
                    ),
                    child: const Center(
                      child: Icon(Icons.emergency_rounded,
                          color: Colors.white, size: 28),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SOS EMERGENCY',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.error,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Tourist Requesting Help',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: status == 'verified'
                          ? AppTheme.secondary
                          : AppTheme.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tourist Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_rounded,
                            color: AppTheme.error, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          touristName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.message_rounded,
                            color: Colors.white54, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            message,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // High-visibility Tourist Location Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.error.withValues(alpha: 0.5), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on_rounded, color: AppTheme.error, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'TOURIST GPS LOCATION',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.gps_fixed_rounded, color: Colors.amberAccent, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${lat.toStringAsFixed(4)}° N, ${lng.toStringAsFixed(4)}° E',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Sector 4 • Mudumalai National Park Buffer Zone',
                      style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Column(
                children: [
                  // Verify Button (if unverified)
                  if (status == 'unverified')
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 6,
                        ),
                        onPressed: () async {
                          SoundService.instance.stopSound();
                          try {
                            await ApiService()
                                .dio
                                .patch('/api/sos/$sosId/verify');
                          } catch (_) {}
                          if (context.mounted) Navigator.of(context).pop();
                          if (onVerify != null) onVerify!();
                        },
                        icon: const Icon(Icons.verified_rounded, size: 20),
                        label: const Text(
                          'VERIFY SOS REQUEST',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5),
                        ),
                      ),
                    ),

                  // Acknowledge Button (if verified)
                  if (status == 'verified')
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 6,
                        ),
                        onPressed: () async {
                          SoundService.instance.stopSound();
                          try {
                            await ApiService()
                                .dio
                                .patch('/api/sos/$sosId/acknowledge');
                          } catch (_) {}
                          if (context.mounted) Navigator.of(context).pop();
                          if (onAcknowledge != null) onAcknowledge!();
                        },
                        icon: const Icon(Icons.check_circle_rounded, size: 20),
                        label: const Text(
                          'ACKNOWLEDGE & RESOLVE',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5),
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
                            side: const BorderSide(
                                color: AppTheme.primaryFixed, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            SoundService.instance.stopSound();
                            Navigator.of(context).pop();
                            if (onViewOnMap != null) onViewOnMap!();
                          },
                          icon: const Icon(Icons.map_rounded, size: 16),
                          label: const Text('View on Map',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white54,
                            side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            SoundService.instance.stopSound();
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Dismiss',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700)),
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
}
