import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

/// ForestGuard - Destination & National Park Selection Screen (Image 3)
class ParkSelectionScreen extends StatefulWidget {
  const ParkSelectionScreen({super.key});

  @override
  State<ParkSelectionScreen> createState() => _ParkSelectionScreenState();
}

class _ParkSelectionScreenState extends State<ParkSelectionScreen> {
  int _selectedParkIndex = 0; // 0: Yosemite, 1: Yellowstone, 2: Banff

  final List<Map<String, dynamic>> _parks = [
    {
      'name': 'Yosemite National Park',
      'location': 'California, USA',
      'mapSize': '45 MB Map',
      'image': 'https://images.unsplash.com/photo-1426604966848-d7adac402bff?auto=format&fit=crop&w=600&q=80',
      'isRecent': true,
    },
    {
      'name': 'Yellowstone National Park',
      'location': 'Wyoming, USA',
      'mapSize': '63 MB Map',
      'image': 'https://images.unsplash.com/photo-1546587348-d12660c30c50?auto=format&fit=crop&w=600&q=80',
      'isRecent': false,
    },
    {
      'name': 'Banff National Park',
      'location': 'Alberta, Canada',
      'mapSize': '86 MB Map',
      'image': 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=600&q=80',
      'isRecent': false,
    },
  ];

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
          'ForestGuard',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: AppTheme.primary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Where are you\nvisiting?',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select a national park or forest region to download offline maps and local safety protocols before you go.',
                    style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant, height: 1.4),
                  ),

                  const SizedBox(height: 20),

                  // Search Field (Image 3)
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search parks, forests, or regions...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.onSurfaceVariant),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section 1: Recently Selected (Image 3)
                  const Text(
                    'Recently Selected',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 12),
                  _buildParkCard(0, _parks[0]),

                  const SizedBox(height: 24),

                  // Section 2: Popular Destinations (Image 3)
                  const Text(
                    'Popular Destinations',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 12),
                  _buildParkCard(1, _parks[1]),
                  const SizedBox(height: 14),
                  _buildParkCard(2, _parks[2]),

                  const SizedBox(height: 30),
                ],
              ),
            ),

            // Bottom CTA Button (Image 3)
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.go('/tourist'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Continue to Dashboard', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParkCard(int index, Map<String, dynamic> park) {
    final isSelected = _selectedParkIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedParkIndex = index),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.outlineVariant.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: AppTheme.ambientShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              park['image'] as String,
              height: 110,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        park['name'] as String,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 12, color: AppTheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(park['location'] as String, style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.map_outlined, size: 12, color: AppTheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              park['mapSize'] as String,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
                    size: 24,
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
