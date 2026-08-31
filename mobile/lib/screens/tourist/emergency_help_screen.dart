import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// ForestGuard - Emergency Help & Safety Protocols Screen (Image 5 & Image 1)
class EmergencyHelpScreen extends StatelessWidget {
  final bool isApproachingView; // If true, displays Image 1 Wildlife Approaching Alert hero
  const EmergencyHelpScreen({super.key, this.isApproachingView = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: const Row(
          children: [
            SizedBox(width: 16),
            Icon(Icons.forest_rounded, color: AppTheme.primary, size: 24),
            SizedBox(width: 8),
            Text('ForestGuard', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: AppTheme.primary)),
          ],
        ),
        leadingWidth: 200,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppTheme.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Image 1 Approaching Alert Hero View (if isApproachingView)
          if (isApproachingView) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: AppTheme.primary, size: 18),
                      SizedBox(width: 8),
                      Text('Central Reserve - Sector 4', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    ],
                  ),
                  Text('CHANGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: 0.5)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Pink Approaching Hero Card (Image 1)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDAD6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFBA1A1A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFBA1A1A),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '⚠️ WILDLIFE ALERT',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFBA1A1A), letterSpacing: 0.5),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'You are approaching an active wildlife safety zone.',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFBA1A1A)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tiger detected in Zone A.',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFBA1A1A)),
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.work_outline, size: 12, color: Color(0xFFBA1A1A)),
                            SizedBox(width: 4),
                            Text('Distance: 1.5km', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFBA1A1A))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBA1A1A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('View Safety Map', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Page Title & Subtitle (Image 5)
          const Text(
            'Emergency Help',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: -0.5),
          ),
          const SizedBox(height: 6),
          const Text(
            'Immediate assistance and critical safety protocols for wildlife encounters and park emergencies.',
            style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant, height: 1.4),
          ),

          const SizedBox(height: 24),

          // Section 1: Emergency Contacts (Image 5)
          const Row(
            children: [
              Icon(Icons.emergency_rounded, color: Color(0xFFBA1A1A), size: 18),
              SizedBox(width: 8),
              Text('Emergency Contacts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            ],
          ),
          const SizedBox(height: 12),

          // Card 1: Primary Contact (Image 5)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFBA1A1A).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 14, color: Color(0xFFBA1A1A)),
                    SizedBox(width: 6),
                    Text('PRIMARY CONTACT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFBA1A1A), letterSpacing: 0.5)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('Forest Authority HQ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                const SizedBox(height: 2),
                const Text(
                  'For immediate life-threatening wildlife encounters or severe injuries.',
                  style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBA1A1A),
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Call 911 / Park Emergency', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Card 2: Secondary Contact (Image 5)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.local_police_outlined, size: 14, color: AppTheme.secondary),
                    SizedBox(width: 6),
                    Text('SECONDARY CONTACT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.secondary, letterSpacing: 0.5)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('On-Duty Ranger Station', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                const SizedBox(height: 2),
                const Text(
                  'For non-life-threatening assistance, lost hikers, or trail hazards.',
                  style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Call Dispatch', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 2: Wildlife Emergency Steps (Image 5)
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 18, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Wildlife Emergency Steps', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _buildStepItem('1', 'Stay Calm & Do Not Run', 'Sudden movements can trigger prey drive. Maintain a calm demeanor and assess the situation without turning your back to the animal.'),
                const SizedBox(height: 16),
                _buildStepItem('2', 'Create Distance Slowly', 'Back away slowly, keeping the animal in your line of sight. If it\'s a bear, speak in a calm, low voice to identify yourself as human.'),
                const SizedBox(height: 16),
                _buildStepItem('3', 'Use Bear Spray If Approached', 'If a predator approaches aggressively and you have deterrent spray, prepare to use it when the animal is within 30 feet.'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 3: General Safety Guidance (Image 5)
          const Row(
            children: [
              Icon(Icons.shield_outlined, size: 18, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('General Safety Guidance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            ],
          ),
          const SizedBox(height: 12),

          _buildGuidanceCard('Always hike in groups.'),
          const SizedBox(height: 8),
          _buildGuidanceCard('Carry adequate water and supplies.'),
          const SizedBox(height: 8),
          _buildGuidanceCard('Stay on marked trails.'),
          const SizedBox(height: 8),
          _buildGuidanceCard('Inform someone of your plans.'),

          const SizedBox(height: 20),

          const Center(
            child: Text(
              'Emergency information is configured by forest authorities.',
              style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStepItem(String number, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: AppTheme.primary,
          child: Text(number, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primary)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuidanceCard(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: AppTheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }
}
