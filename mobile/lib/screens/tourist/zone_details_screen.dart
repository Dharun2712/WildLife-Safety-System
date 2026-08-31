import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

/// ForestGuard - Zone Details Screen (Image 3)
class ZoneDetailsScreen extends StatelessWidget {
  final Map<String, dynamic>? zoneData;

  const ZoneDetailsScreen({super.key, this.zoneData});

  @override
  Widget build(BuildContext context) {
    final zoneName = zoneData?['name'] ?? 'Zone A';
    final subject = zoneData?['animal'] ?? 'Tiger';
    final radius = zoneData?['radius'] ?? '500m';
    final time = zoneData?['time'] ?? '10:35 AM';
    final location = zoneData?['location'] ?? 'Sector 4, North Ridge';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.primary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Zone Details',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppTheme.primary),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Top Map Circle Header (Image 3)
          Container(
            height: 220,
            width: double.infinity,
            color: AppTheme.surfaceContainerLow,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Red Dashed Circular Danger Radar Circle
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFFBA1A1A).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFBA1A1A), width: 2, style: BorderStyle.solid),
                  ),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFBA1A1A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.pets, color: Colors.white, size: 20),
                    ),
                  ),
                ),

                // Active Danger Zone Badge Strip across middle (Image 3)
                Positioned(
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBA1A1A),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emergency_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'ACTIVE DANGER ZONE',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.8),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Card 1: Identified Subject (Image 3)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.ambientShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.pets, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'IDENTIFIED SUBJECT',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.onSurfaceVariant, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subject,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primary),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Class 1 Predator. Protocol Alpha active.',
                              style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Card 2: Location Data (Image 3)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.ambientShadow,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: AppTheme.primary, size: 22),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'LOCATION DATA',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.onSurfaceVariant, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              zoneName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              location,
                              style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Card 3: Alert Parameters (Image 3)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.ambientShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.radar_rounded, color: AppTheme.primary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'ALERT PARAMETERS',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.onSurfaceVariant, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(radius, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                              const Text('Configured Radius', style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(time, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                              const Text('Created', style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Actions Section (Image 3)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.my_location, size: 18),
                    label: const Text('UPDATE LOCATION', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: () => context.pop(),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppTheme.surfaceContainerHigh,
                            side: BorderSide.none,
                            shape: const StadiumBorder(),
                          ),
                          icon: const Icon(Icons.timer_outlined, size: 16, color: AppTheme.primary),
                          label: const Text('KEEP ACTIVE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Zone alert closed.')),
                            );
                            context.pop();
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFDAD6),
                            side: BorderSide.none,
                            shape: const StadiumBorder(),
                          ),
                          icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFBA1A1A)),
                          label: const Text('CLOSE ALERT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFBA1A1A))),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
