import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// ForestGuard - Active Cameras Screen (Image 1)
class CameraMonitoringScreen extends StatelessWidget {
  const CameraMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppTheme.primary),
          onPressed: () {},
        ),
        title: const Text(
          'ForestGuard',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: AppTheme.primary),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'RM',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header Row (Image 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Cameras',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Sector 4 – South Valley',
                    style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F7ED),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(radius: 4, backgroundColor: AppTheme.secondary),
                    SizedBox(width: 6),
                    Text(
                      'System Optimal',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Camera 1: C-01 (River Bend) with Detection Overlay (Image 1)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFFDAD6), width: 1.5),
              boxShadow: AppTheme.ambientShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Live Stream Camera Feed Box with Bounding Box Overlay
                Stack(
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage('https://images.unsplash.com/photo-1561731216-c3a4d99437d5?auto=format&fit=crop&w=800&q=80'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Yellow Bounding Box Overlay (Image 1)
                    Positioned(
                      top: 40,
                      left: 70,
                      right: 70,
                      bottom: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.yellowAccent, width: 2.5),
                        ),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            color: Colors.yellowAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: const Text(
                              'Tiger 94%',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Detection Tag & Online Badge
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFBA1A1A),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text('DETECTION', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0E6C4A),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text('ONLINE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RichText(
                            text: const TextSpan(
                              text: 'C–01 ',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primary),
                              children: [
                                TextSpan(
                                  text: '(River Bend)',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: AppTheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text('Model: YOLOv8n', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.bug_report_outlined, color: Color(0xFFBA1A1A), size: 18),
                              SizedBox(width: 6),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Tiger Detected', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFBA1A1A))),
                                  Text('Today, 10:35 AM', style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
                                ],
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.surfaceContainerHigh,
                              foregroundColor: AppTheme.onSurface,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('View Stream', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Camera 2: C-02 (North Ridge) (Image 1)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
              boxShadow: AppTheme.ambientShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage('https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=800&q=80'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: const TextSpan(
                          text: 'C–02 ',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primary),
                          children: [
                            TextSpan(
                              text: '(North Ridge)',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: AppTheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text('Model: YOLOv8n', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: AppTheme.secondary, size: 20),
                              SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('No Activity', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
                                  Text('Last check: 2 mins ago', style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
                                ],
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.surfaceContainerHigh,
                              foregroundColor: AppTheme.onSurface,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('View Stream', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
