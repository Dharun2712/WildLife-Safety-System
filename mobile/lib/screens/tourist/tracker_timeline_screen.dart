import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// ForestGuard - Tiger Tracker Timeline Screen (Image 1)
class TrackerTimelineScreen extends StatelessWidget {
  const TrackerTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: const Icon(Icons.menu_rounded, color: AppTheme.primary),
        title: const Text(
          'ForestGuard',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppTheme.primary),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: AppTheme.primary, size: 28),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Animal Tracker Header Card (Image 1)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.ambientShadow,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1561731216-c3a4d99437d5?auto=format&fit=crop&w=200&q=80',
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tiger Tracker',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primary),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFDAD6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Danger', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFBA1A1A))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text('ID: TG-042 - Adult Male', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Active Monitoring', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Vertical Timeline (Image 1)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline Left Axis
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFFBA1A1A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text('10:48 AM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant)),
                  Container(width: 2, height: 280, color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('10:35 AM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant)),
                ],
              ),

              const SizedBox(width: 14),

              // Timeline Content Cards Column
              Expanded(
                child: Column(
                  children: [
                    // Timeline Card 1: Danger Zone Updated (Red outline - Image 1)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBA1A1A).withValues(alpha: 0.6), width: 1.5),
                        boxShadow: AppTheme.ambientShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Danger Zone Updated',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFBA1A1A)),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'New location detected via Perimeter Sensor. Proximity warning issued for Sector C-02.',
                            style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant, height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.location_on_outlined, size: 14, color: AppTheme.primary),
                                    SizedBox(width: 6),
                                    Text('Sector C-02', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                                  ],
                                ),
                                SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.my_location, size: 14, color: AppTheme.primary),
                                    SizedBox(width: 6),
                                    Text('27.5398° N, 83.9188° E', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppTheme.onSurfaceVariant)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              'https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?auto=format&fit=crop&w=600&q=80',
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Timeline Card 2: Initial Detection (Image 1)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
                        boxShadow: AppTheme.ambientShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Initial Detection',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Camera Trap Alpha triggered. Visual confirmation acquired.',
                            style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant, height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.videocam_outlined, size: 14, color: AppTheme.primary),
                                    SizedBox(width: 6),
                                    Text('Sector C-01', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                                  ],
                                ),
                                SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.my_location, size: 14, color: AppTheme.primary),
                                    SizedBox(width: 6),
                                    Text('27.5342° N, 83.9213° E', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppTheme.onSurfaceVariant)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=600&q=80',
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
