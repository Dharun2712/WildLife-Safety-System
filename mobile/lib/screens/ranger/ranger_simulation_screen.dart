import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// ForestGuard - Ranger Simulation & Demo Detection Mode (Image 2)
class RangerSimulationScreen extends StatefulWidget {
  const RangerSimulationScreen({super.key});

  @override
  State<RangerSimulationScreen> createState() => _RangerSimulationScreenState();
}

class _RangerSimulationScreenState extends State<RangerSimulationScreen> {
  String _selectedAnimal = 'Tiger';

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
      body: Column(
        children: [
          // Banner: Simulation / Demo Detection Mode Active (Image 2)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: AppTheme.primary,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.science_outlined, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  'Simulation / Demo Detection Mode Active',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Column 1: Simulation Subjects (Image 2)
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Simulation Subjects', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                          const SizedBox(height: 12),
                          _buildSubjectCard('Simulate Tiger', 'Deploy virtual tracker for Panthera tigris.', 'Tiger'),
                          const SizedBox(height: 10),
                          _buildSubjectCard('Simulate Elephant', 'Deploy virtual tracker for Elephas maximus.', 'Elephant'),
                          const SizedBox(height: 10),
                          _buildSubjectCard('Simulate Lion', 'Deploy virtual tracker for Panthera leo.', 'Lion'),
                          const SizedBox(height: 10),
                          _buildSubjectCard('Simulate Leopard', 'Deploy virtual tracker for Panthera pardus.', 'Leopard'),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Column 2: Event Triggers & Simulation Map (Image 2)
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Event Triggers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 44,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Detection triggered for $_selectedAnimal!')),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: const StadiumBorder(), elevation: 0),
                                    icon: const Icon(Icons.location_on_outlined, size: 16),
                                    label: const Text('Create Detection', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SizedBox(
                                  height: 44,
                                  child: ElevatedButton.icon(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary, foregroundColor: Colors.white, shape: const StadiumBorder(), elevation: 0),
                                    icon: const Icon(Icons.trending_up_rounded, size: 16),
                                    label: const Text('Move Animal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFDAD6), foregroundColor: const Color(0xFFBA1A1A), shape: const StadiumBorder(), elevation: 0),
                              icon: const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFBA1A1A)),
                              label: const Text('Create Danger Zone', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFBA1A1A))),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 44,
                                  child: ElevatedButton.icon(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surfaceContainerHigh, foregroundColor: AppTheme.primary, shape: const StadiumBorder(), elevation: 0),
                                    icon: const Icon(Icons.campaign_outlined, size: 16),
                                    label: const Text('Trigger Tourist Warning', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SizedBox(
                                  height: 44,
                                  child: ElevatedButton.icon(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surfaceContainerHigh, foregroundColor: AppTheme.primary, shape: const StadiumBorder(), elevation: 0),
                                    icon: const Icon(Icons.shield_outlined, size: 16),
                                    label: const Text('Trigger Ranger Alert', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(side: BorderSide(color: AppTheme.outlineVariant), shape: const StadiumBorder()),
                              icon: const Icon(Icons.close_rounded, size: 16, color: AppTheme.primary),
                              label: const Text('Close Alert', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Simulation Aerial Map View Container (Image 2)
                Container(
                  height: 240,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: const DecorationImage(
                      image: NetworkImage('https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=1000&q=80'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(8)),
                          child: const Text('AMAZON BASIN SECTOR • DEMO MODE ACTIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AppTheme.ambientShadow),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.pets, color: AppTheme.secondary, size: 20),
                              SizedBox(width: 8),
                              Text('Simulation Map View', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                            ],
                          ),
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
    );
  }

  Widget _buildSubjectCard(String title, String subtitle, String animalName) {
    final isSelected = _selectedAnimal == animalName;
    return GestureDetector(
      onTap: () => setState(() => _selectedAnimal = animalName),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE5F7ED) : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppTheme.secondary : AppTheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0xFFA0F4C8), shape: BoxShape.circle),
              child: const Icon(Icons.pets, color: AppTheme.primary, size: 18),
            ),
            const SizedBox(width: 12),
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
          ],
        ),
      ),
    );
  }
}
