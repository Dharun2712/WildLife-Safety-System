import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

/// ForestGuard - Alert Details Screen (Image 2)
class AlertDetailsScreen extends StatelessWidget {
  const AlertDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          'Alert Details',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppTheme.primary),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppTheme.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Top Satellite Map Container with Red Circular Danger Zone Overlay (Image 2)
          Container(
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              image: const DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=800&q=80'),
                fit: BoxFit.cover,
              ),
              boxShadow: AppTheme.ambientShadow,
            ),
            child: Stack(
              children: [
                // Top Left ACTIVE DANGER ZONE Pill Badge
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDAD6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.circle, color: Color(0xFFBA1A1A), size: 8),
                        SizedBox(width: 6),
                        Text('ACTIVE DANGER ZONE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFBA1A1A), letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ),

                // Center Red Dashed Radar Circle Overlay
                Center(
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFFBA1A1A).withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFBA1A1A), width: 2),
                    ),
                    child: Center(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFFBA1A1A),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.pets, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // AI Wildlife Detection Card (Image 2)
          Container(
            padding: const EdgeInsets.all(20),
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
                    Icon(Icons.precision_manufacturing_outlined, size: 14, color: AppTheme.onSurfaceVariant),
                    SizedBox(width: 6),
                    Text('AI WILDLIFE DETECTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.onSurfaceVariant, letterSpacing: 0.5)),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Text('🐅', style: TextStyle(fontSize: 26)),
                    SizedBox(width: 8),
                    Text('Tiger Sighting', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Confidence', style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
                            SizedBox(height: 2),
                            Text('94%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Detected', style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
                            SizedBox(height: 2),
                            Text('10:35 AM', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Source & Distance Details Card (Image 2)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.ambientShadow,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: AppTheme.surfaceContainerHigh, shape: BoxShape.circle),
                      child: const Icon(Icons.videocam_outlined, color: AppTheme.primary, size: 20),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Source', style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
                        Text('Camera Trap C-01 (Sector 4)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: AppTheme.surfaceContainerHigh, shape: BoxShape.circle),
                      child: const Icon(Icons.location_on_outlined, color: AppTheme.primary, size: 20),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Distance from you', style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
                        Text('1.2 km North-East', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 16, color: AppTheme.onSurfaceVariant),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Disclaimer: AI identification may be inaccurate. Please proceed with caution and follow standard park safety protocols.',
                          style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // View Safety Instructions CTA Button (Image 2)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              icon: const Icon(Icons.shield_outlined, size: 18),
              label: const Text('View Safety Instructions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
