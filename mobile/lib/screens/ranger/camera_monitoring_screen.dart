import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// ForestGuard - Desktop Camera Monitoring Screen (Image 4)
class CameraMonitoringScreen extends StatefulWidget {
  const CameraMonitoringScreen({super.key});

  @override
  State<CameraMonitoringScreen> createState() => _CameraMonitoringScreenState();
}

class _CameraMonitoringScreenState extends State<CameraMonitoringScreen> {
  int _activeCameraIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Row(
        children: [
          // Left Sidebar (Image 4)
          Container(
            width: 220,
            color: AppTheme.surfaceContainerLow,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppTheme.primary, size: 24),
                    SizedBox(width: 8),
                    Text('ForestGuard', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppTheme.primary)),
                  ],
                ),
                const SizedBox(height: 32),
                _buildSidebarItem(Icons.home_outlined, 'Home', false),
                _buildSidebarItem(Icons.map_outlined, 'Map', false),
                _buildSidebarItem(Icons.videocam, 'Cameras', true),
                _buildSidebarItem(Icons.warning_amber_rounded, 'Alerts', false),
                _buildSidebarItem(Icons.shield_outlined, 'Safety', false),
                const Spacer(),
                _buildSidebarItem(Icons.person_outline, 'Profile', false),
              ],
            ),
          ),

          // Main Center View & Right Panel (Image 4)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header (Image 4)
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Camera Monitoring', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                          SizedBox(height: 2),
                          Text('Live telemetry and AI detections across active zones.', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                        ],
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
                            icon: const Icon(Icons.tune_rounded, size: 16, color: AppTheme.primary),
                            label: const Text('Filter Cameras', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: const StadiumBorder(), elevation: 0),
                            icon: const Icon(Icons.grid_view_rounded, size: 16),
                            label: const Text('Grid View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main Camera Video Container (Image 4)
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Stack(
                                    children: [
                                      // Camera Video Image (Infrared Deer Feed - Image 4)
                                      Image.network(
                                        'https://images.unsplash.com/photo-1547970810-dc0eac25ee85?auto=format&fit=crop&w=1000&q=80',
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),

                                      // Top Badges Overlay (Image 4)
                                      Positioned(
                                        top: 16,
                                        left: 16,
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                                              child: const Row(
                                                children: [
                                                  Icon(Icons.circle, color: Colors.white, size: 8),
                                                  SizedBox(width: 4),
                                                  Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(6)),
                                              child: const Text('CAM C-01 • North Ridge', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                      ),

                                      Positioned(
                                        top: 16,
                                        right: 16,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(6)),
                                          child: const Text('2023/10/28 00:47:32 AM | FPS: 29.97 | 1080p HD', style: TextStyle(color: Colors.white, fontSize: 10)),
                                        ),
                                      ),

                                      // Bounding Boxes Overlays (Elk 94% & Fox 72% - Image 4)
                                      Positioned(
                                        top: 120,
                                        left: 160,
                                        child: Container(
                                          width: 140,
                                          height: 220,
                                          decoration: BoxDecoration(
                                            border: Border.all(color: const Color(0xFFA0F4C8), width: 2),
                                          ),
                                          child: Align(
                                            alignment: Alignment.topLeft,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              color: const Color(0xFFA0F4C8),
                                              child: const Text('Elk 94%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Bottom Telemetry Footer (Image 4)
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          color: Colors.black.withValues(alpha: 0.8),
                                          child: const Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('LAT: 44.4280, LON: W -110.3482 | TEMP: 2°C | MOTION DETECTED', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                              Text('Model: YOLOv8x-Wildlife-v3', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Bottom Camera Thumbnails Row (Image 4)
                              SizedBox(
                                height: 70,
                                child: Row(
                                  children: [
                                    _buildCameraThumbnail(0, 'CAM C-01 (main)', 'https://images.unsplash.com/photo-1547970810-dc0eac25ee85?auto=format&fit=crop&w=300&q=80'),
                                    const SizedBox(width: 12),
                                    _buildCameraThumbnail(1, 'C-02 (river)', 'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=300&q=80'),
                                    const SizedBox(width: 12),
                                    _buildCameraThumbnail(2, 'C-03 (canopy)', 'https://images.unsplash.com/photo-1511497584788-876761465586?auto=format&fit=crop&w=300&q=80'),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),
                            ],
                          ),
                        ),

                        const SizedBox(width: 20),

                        // Right Sidebar: Recent Detections List (Image 4)
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: AppTheme.ambientShadow,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Recent Detections', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                                const SizedBox(height: 16),
                                _buildDetectionTile('Elk (Adult)', 'Confidence: 94%', 'Just now', Icons.pets, const Color(0xFFE5F7ED), AppTheme.secondary),
                                const Divider(height: 20),
                                _buildDetectionTile('Unidentified Motion', 'Possible Poacher/Fox', '2m ago', Icons.warning_amber_rounded, const Color(0xFFFFDAD6), const Color(0xFFBA1A1A)),
                                const Divider(height: 20),
                                _buildDetectionTile('Bird Sp.', 'Confidence: 45% (Ignored)', '15m ago', Icons.flutter_dash, AppTheme.surfaceContainerHigh, AppTheme.onSurfaceVariant),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String label, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? Colors.white : AppTheme.primary, size: 20),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isActive ? Colors.white : AppTheme.primary)),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraThumbnail(int index, String name, String imageUrl) {
    final isSelected = _activeCameraIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeCameraIndex = index),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppTheme.primary : Colors.transparent, width: 2),
            image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
          ),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              color: Colors.black.withValues(alpha: 0.6),
              child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetectionTile(String title, String subtitle, String time, IconData icon, Color bg, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
            ],
          ),
        ),
        Text(time, style: const TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant)),
      ],
    );
  }
}
