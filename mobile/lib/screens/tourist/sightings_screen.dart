import 'package:flutter/material.dart';
import '../../config/theme.dart';

class SightingsScreen extends StatefulWidget {
  const SightingsScreen({super.key});

  @override
  State<SightingsScreen> createState() => _SightingsScreenState();
}

class _SightingsScreenState extends State<SightingsScreen> {
  int _selectedFilter = 0; // 0: All, 1: Mammals, 2: Birds

  final List<Map<String, dynamic>> _sightings = [
    {
      'name': 'Bear',
      'match': '98%',
      'location': 'North Ridge Trail, Sec 7',
      'desc': 'Adult male observed foraging near the stream crossing. Remained calm, no aggressive posturing. Proceeded deep into forest.',
      'recordedBy': 'Ranger Smith',
      'time': 'Today, 06:42 AM',
      'image': 'https://images.unsplash.com/photo-1530595467537-0b5996c41f2d?auto=format&fit=crop&w=800&q=80',
      'type': 'mammal',
    },
    {
      'name': 'Great Horned Owl',
      'match': '95%',
      'location': 'Old Growth Sector',
      'time': 'Yesterday, 19:15',
      'image': 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?auto=format&fit=crop&w=800&q=80',
      'type': 'bird',
    },
    {
      'name': 'Deer',
      'match': '99%',
      'location': 'Meadow Crossing',
      'time': 'Yesterday, 14:30',
      'image': 'https://images.unsplash.com/photo-1484406566174-9da000fda645?auto=format&fit=crop&w=800&q=80',
      'type': 'mammal',
    },
    {
      'name': 'Green Tree Frog',
      'match': '92%',
      'location': 'Wetlands Area B',
      'time': 'Oct 24, 08:15 AM',
      'image': 'https://images.unsplash.com/photo-1550853024-fae8cd4be47f?auto=format&fit=crop&w=400&q=80',
      'type': 'amphibian',
      'isCompact': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: AppTheme.primaryContainer,
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ),
        title: const Text(
          'ForestGuard',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: AppTheme.primary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppTheme.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Recent Sightings',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: -0.5),
          ),
          const SizedBox(height: 6),
          const Text(
            'Verified wildlife activity reported by rangers and trusted guides in Sector 7 over the past 48 hours.',
            style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant, height: 1.4),
          ),

          const SizedBox(height: 16),

          // Filter Pills (Photo 1)
          Row(
            children: [
              _buildFilterPill(0, 'All'),
              const SizedBox(width: 8),
              _buildFilterPill(1, 'Mammals'),
              const SizedBox(width: 8),
              _buildFilterPill(2, 'Birds'),
            ],
          ),

          const SizedBox(height: 20),

          // Feed Items
          ..._sightings.where((s) {
            if (_selectedFilter == 1) return s['type'] == 'mammal';
            if (_selectedFilter == 2) return s['type'] == 'bird';
            return true;
          }).map((s) {
            if (s['isCompact'] == true) {
              return _buildCompactSightingCard(s);
            }
            return _buildFullSightingCard(s);
          }),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildFilterPill(int index, String label) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildFullSightingCard(Map<String, dynamic> s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: AppTheme.ambientShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with Match Badge
          Container(
            height: 200,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(s['image']),
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
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_rounded, size: 14, color: AppTheme.secondary),
                        const SizedBox(width: 4),
                        Text(
                          '${s['match']} Match',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      s['location'],
                      style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  s['name'],
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.onSurface),
                ),
                if (s['desc'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    s['desc'],
                    style: const TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant, height: 1.4),
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppTheme.surfaceContainer),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (s['recordedBy'] != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('RECORDED BY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.outline)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const CircleAvatar(radius: 8, backgroundColor: AppTheme.primary),
                              const SizedBox(width: 6),
                              Text(s['recordedBy'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
                            ],
                          ),
                        ],
                      )
                    else
                      Text(s['time'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                    if (s['recordedBy'] != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('TIME', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.outline)),
                          const SizedBox(height: 2),
                          Text(s['time'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
                        ],
                      )
                    else
                      const Row(
                        children: [
                          Text('Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.primary),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSightingCard(Map<String, dynamic> s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: AppTheme.ambientShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              image: DecorationImage(
                image: NetworkImage(s['image']),
                fit: BoxFit.cover,
              ),
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
                    Text(s['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.onSurface)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(s['match'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.onSecondaryContainer)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text('📍 ${s['location']}', style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(s['time'], style: const TextStyle(fontSize: 10, color: AppTheme.outline)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.secondary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}
