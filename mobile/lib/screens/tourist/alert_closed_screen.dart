import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// ForestGuard - Safety Alert Closed Screen (Image 3)
class AlertClosedScreen extends StatelessWidget {
  final Map<String, dynamic>? alert;
  final VoidCallback? onViewMap;

  const AlertClosedScreen({super.key, this.alert, this.onViewMap});

  @override
  Widget build(BuildContext context) {
    final zoneStr = alert?['zone'] ?? 'Zone A';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: AppTheme.primaryContainer,
            child: const Icon(Icons.forest_rounded, color: Colors.white, size: 18),
          ),
        ),
        title: const Text(
          'ForestGuard',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: AppTheme.primary),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppTheme.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Mint Green Hero Card (Image 3)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              decoration: BoxDecoration(
                color: const Color(0xFFA0F4C8),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFA0F4C8).withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Centered Checkmark Circle
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                    ),
                    child: const Icon(Icons.check_rounded, color: AppTheme.primary, size: 40),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'SAFETY ALERT CLOSED',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'The wildlife alert in $zoneStr has been closed by the forest ranger. Please continue following official forest instructions.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.primary,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // View Forest Map Button (Image 3)
                  SizedBox(
                    width: 200,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (onViewMap != null) {
                          onViewMap!();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      icon: const Icon(Icons.map_outlined, color: Colors.white, size: 20),
                      label: const Text('View Forest Map', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Footer Status
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.onSurfaceVariant),
                SizedBox(width: 4),
                Text('Status updated 2 minutes ago', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
