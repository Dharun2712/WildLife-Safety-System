import 'package:flutter/material.dart';
import '../config/theme.dart';

/// ForestGuard - Emergency Alert + SOS Reported Dialog (Image 3)
class SOSActiveDialog extends StatefulWidget {
  const SOSActiveDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 300),
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

class _SOSActiveDialogState extends State<SOSActiveDialog> {
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      elevation: 24,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Red Header Bar (Image 3)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: const Color(0xFFBA1A1A),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.campaign_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'EMERGENCY ALERT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '14:02 IST',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // Card Body (Image 3)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiger Photo + Title Row (Image 3)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          'https://images.unsplash.com/photo-1561731216-c3a4d99437d5?auto=format&fit=crop&w=300&q=80',
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tiger Sighting +\nSOS Reported',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.onSurface,
                                height: 1.2,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Sector 7, North Corridor',
                              style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                            ),
                            SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: 12, color: AppTheme.onSurfaceVariant),
                                SizedBox(width: 4),
                                Text(
                                  '(Coordinates: 29.53N, 78.77E)',
                                  style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Metrics Container Row (Image 3: At Risk & Nearest Ranger)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'At Risk',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.groups_rounded, size: 18, color: Color(0xFFBA1A1A)),
                                  SizedBox(width: 6),
                                  Text(
                                    '3 Tourists',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFBA1A1A)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 36, color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nearest Ranger',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.badge_outlined, size: 18, color: AppTheme.primary),
                                    SizedBox(width: 6),
                                    Text(
                                      'Ranger Smith',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.primary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Status Alert Box (Image 3)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDAD6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(radius: 4, backgroundColor: Color(0xFFBA1A1A)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ACTIVE SOS - IMMEDIATE RESPONSE REQUIRED',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF93000A),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Action Button 1: Acknowledge Alert (Image 3)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _acknowledged = true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Alert Acknowledged. Dispatch units notified.')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _acknowledged ? AppTheme.secondary : const Color(0xFFBA1A1A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      icon: Icon(_acknowledged ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded, color: Colors.white),
                      label: Text(
                        _acknowledged ? 'Alert Acknowledged' : 'Acknowledge Alert',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Action Button 2: Navigate to Zone (Image 3)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.navigation_rounded, color: Colors.white, size: 18),
                      label: const Text('Navigate to Zone', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Bottom Action Row (Image 3: Contact Tourist | Update Location | Close)
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Calling Tourist Group Leader...')),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              side: const BorderSide(color: AppTheme.primary, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.phone_outlined, size: 16),
                            label: const Text('Contact Tourist', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Fetching Latest GPS Pins...')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.surfaceContainerHigh,
                              foregroundColor: AppTheme.onSurface,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.gps_fixed, size: 16, color: AppTheme.onSurface),
                            label: const Text('Update Location', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppTheme.onSurfaceVariant, size: 20),
                          onPressed: () => Navigator.pop(context),
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
    );
  }
}
