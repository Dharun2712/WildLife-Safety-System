import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../config/constants.dart';
import '../../widgets/forest_map_view.dart';
import '../../widgets/detection_alert_modal.dart';
import 'emergency_help_screen.dart';

class TouristShell extends ConsumerStatefulWidget {
  const TouristShell({super.key});

  @override
  ConsumerState<TouristShell> createState() => _TouristShellState();
}

class _TouristShellState extends ConsumerState<TouristShell> {
  int _currentIndex = 0;
  StreamSubscription? _wsSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenToWebSocketEvents();
    });
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }

  void _listenToWebSocketEvents() {
    final ws = ref.read(webSocketProvider);
    _wsSubscription = ws.events.listen((event) {
      final eventType = event['type'] ?? event['event'];
      if (eventType == 'wildlife_detected' ||
          eventType == 'danger_zone_created' ||
          eventType == 'tourist_warning' ||
          eventType == 'danger_zone_updated') {

        final data = event['data'] is Map ? Map<String, dynamic>.from(event['data']) : event;

        // Invalidate providers so map and alerts refresh reactively
        ref.invalidate(dangerZonesProvider);
        ref.invalidate(alertsProvider);
        ref.invalidate(safetyStatusProvider);

        if (mounted) {
          DetectionAlertModal.show(
            context,
            detection: data,
            isRanger: false,
            onViewOnMap: () {
              setState(() => _currentIndex = 1); // Switch to OpenStreetMap tab
            },
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _TouristHomeTab(auth: auth),
          const _TouristMapTab(),
          const _TouristAlertsTab(),
          const _TouristSafetyTab(),
          _TouristProfileTab(auth: auth, onLogout: () async {
            final router = GoRouter.of(context);
            await ref.read(authProvider.notifier).logout();
            router.go('/role-select');
          }),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map_rounded), label: 'Map'),
            NavigationDestination(icon: Icon(Icons.warning_amber_rounded), selectedIcon: Icon(Icons.warning_rounded), label: 'Alerts'),
            NavigationDestination(icon: Icon(Icons.shield_outlined), selectedIcon: Icon(Icons.shield_rounded), label: 'Safety'),
            NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// TOURIST HOME TAB — Premium Dashboard
// ═══════════════════════════════════════════════════
// ═══════════════════════════════════════════════════
// TOURIST HOME TAB — Premium Dashboard (Images 3, 4, 5)
// ═══════════════════════════════════════════════════
class _TouristHomeTab extends ConsumerWidget {
  final AuthState auth;
  const _TouristHomeTab({required this.auth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = auth.user?['full_name'] ?? 'Alex';
    final safetyAsync = ref.watch(safetyStatusProvider);
    final alertsAsync = ref.watch(alertsProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: CircleAvatar(
            backgroundColor: AppTheme.surfaceContainerHigh,
            backgroundImage: const NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFFBA1A1A),
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.sos_rounded, size: 22),
        label: const Text('SOS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(safetyStatusProvider);
          ref.invalidate(alertsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Greeting & Park Dropdown Selector (Image 4 & Image 5)
            Text(
              'Good Morning,\n$userName.',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.primary, height: 1.1, letterSpacing: -0.5),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ready for your trail walk.',
              style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),

            // Dropdown Park Selector Card (Image 4 & Image 5)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: NetworkImage('https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=400&q=80'),
                      ),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Current Zone', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant)),
                          Text('Redwoods National Park', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                        ],
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_drop_down, color: AppTheme.primary),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Hero Safety Banner (Image 4 Safe state vs Image 5 Danger state)
            safetyAsync.when(
              data: (status) {
                final isDanger = status['status'] == 'danger' || status['status'] == 'approaching';
                return isDanger ? _buildDangerHeroCard() : _buildSafeHeroCard();
              },
              loading: () => _buildSafeHeroCard(),
              error: (_, __) => _buildSafeHeroCard(),
            ),

            const SizedBox(height: 20),

            // Weather & Trail Status Row (Image 3)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.ambientShadow,
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(Icons.wb_sunny_outlined, color: AppTheme.onSurfaceVariant, size: 20),
                            Text('North Sector', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant)),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text('72°F', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                        SizedBox(height: 2),
                        Text('Moderate UV Index', style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.ambientShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(Icons.hiking_rounded, color: AppTheme.onSurfaceVariant, size: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5F7ED),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('• Open', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Trails Dry', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                        const SizedBox(height: 2),
                        const Text('Good visibility today.', style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Trail Traffic Banner Card (Image 4)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Image.network(
                        'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=600&q=80',
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        bottom: 8,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.location_on_outlined, color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text('Current: Northern Ridge Trail', style: TextStyle(color: Colors.white, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Trail Traffic', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                        SizedBox(height: 2),
                        Text('Light activity expected.', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Nearby Activity Header & Horizontal Cards (Image 3 & 4)
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Nearby Activity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                Text('Expand Map >', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
              ],
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildActivityCard('Mule Deer', '0.4 mi • West Trail', '15m ago', Icons.pets_rounded, const Color(0xFFE5F7ED), AppTheme.secondary),
                  const SizedBox(width: 12),
                  _buildActivityCard('Black Bear', '1.2 mi • Ridge Path', '30m ago', Icons.pets_rounded, const Color(0xFFFFDAD6), const Color(0xFFBA1A1A)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Safety Reminders List (Image 4)
            const Text('Safety Reminders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.ambientShadow,
              ),
              child: Column(
                children: [
                  _buildReminderTile(Icons.wb_sunny_outlined, 'Weather Advisory', 'Temperatures dropping after 4 PM.'),
                  const Divider(height: 1, indent: 60),
                  _buildReminderTile(Icons.water_drop_outlined, 'Hydration Station', 'Next refill point is 2 miles ahead on path.'),
                  const Divider(height: 1, indent: 60),
                  _buildReminderTile(Icons.groups_outlined, 'Stay Together', 'Keep groups tight in dense foliage.'),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Hero Mint Safe Card (Image 4)
  Widget _buildSafeHeroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFA0F4C8),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.ambientShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, color: AppTheme.secondary, size: 8),
                    SizedBox(width: 6),
                    Text('LIVE STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: 0.5)),
                  ],
                ),
              ),
              const Icon(Icons.shield_outlined, color: AppTheme.primary, size: 28),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primary,
                child: Icon(Icons.shield_rounded, color: Colors.white, size: 16),
              ),
              SizedBox(width: 10),
              Text(
                'YOU ARE SAFE',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: -0.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'No active wildlife safety alerts near your current location. Trail conditions are clear.',
            style: TextStyle(fontSize: 13, color: AppTheme.primary, height: 1.4),
          ),
          const SizedBox(height: 16),
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
              icon: const Icon(Icons.map_outlined, size: 16),
              label: const Text('View Forest Map', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // Hero Red Danger Zone Card (Image 5)
  Widget _buildDangerHeroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFBA1A1A),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text('ACTIVE WILDLIFE SAFETY ZONE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your current location is within an active wildlife safety zone.',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 3, height: 32, color: Colors.white70),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Remain at a safe location and follow official ranger instructions.',
                  style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFBA1A1A),
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              icon: const Icon(Icons.map_outlined, size: 16, color: Color(0xFFBA1A1A)),
              label: const Text('View Map', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFBA1A1A))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(String title, String subtitle, String time, IconData icon, Color bg, Color iconColor) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.ambientShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primary), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant), overflow: TextOverflow.ellipsis),
                Text(time, style: const TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppTheme.surfaceContainerHigh, shape: BoxShape.circle),
        child: Icon(icon, color: AppTheme.primary, size: 18),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
    );
  }
}

// Premium alert card with colored accent
class _PremiumAlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  const _PremiumAlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final animal = alert['animal_type'] ?? 'unknown';
    final emoji = AppConstants.animalEmojis[animal] ?? '🐾';
    final confidence = ((alert['confidence'] ?? 0) as num) * 100;
    final status = alert['status'] ?? '';
    final statusColor = AppTheme.getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Colored accent strip
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Animal emoji with colored background
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: (AppTheme.animalColors[animal] ?? Colors.grey).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${AppConstants.animalNames[animal] ?? animal} Detected',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Confidence: ${confidence.toStringAsFixed(0)}%',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                          letterSpacing: 0.5,
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
    );
  }
}

// Premium danger zone card
class _PremiumDangerZoneCard extends StatelessWidget {
  final Map<String, dynamic> zone;
  const _PremiumDangerZoneCard({required this.zone});

  @override
  Widget build(BuildContext context) {
    final animal = zone['animal_type'] ?? 'unknown';
    final emoji = AppConstants.animalEmojis[animal] ?? '🐾';
    final radius = zone['radius_meters'] ?? 0;
    final isSim = zone['is_simulation'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: const BoxDecoration(
                color: AppTheme.dangerRed,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.dangerRed.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${AppConstants.animalNames[animal]} Zone${isSim ? " (SIM)" : ""}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Radius: ${radius}m',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    // Pulsing danger indicator
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.dangerRed,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.dangerRed.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Empty state card
class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _EmptyStateCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// TOURIST MAP TAB
// ═══════════════════════════════════════════════════
class _TouristMapTab extends ConsumerWidget {
  const _TouristMapTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zonesAsync = ref.watch(dangerZonesProvider);
    final alertsAsync = ref.watch(alertsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Forest Map')),
      body: zonesAsync.when(
        data: (zones) {
          final alerts = alertsAsync.value ?? [];
          return Stack(
            children: [
              ForestMapView(
                dangerZones: zones,
                alerts: alerts,
                isRanger: false,
              ),
              if (zones.isNotEmpty)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 190),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Drag handle
                        Container(
                          margin: const EdgeInsets.only(top: 10, bottom: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shrinkWrap: true,
                            children: zones.map((z) => _PremiumDangerZoneCard(zone: z)).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Unable to load map data')),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// TOURIST ALERTS TAB (Matching Image 1: Approaching Wildlife Alert View)
// ═══════════════════════════════════════════════════
class _TouristAlertsTab extends StatelessWidget {
  const _TouristAlertsTab();

  @override
  Widget build(BuildContext context) {
    return const EmergencyHelpScreen(isApproachingView: true);
  }
}

// ═══════════════════════════════════════════════════
// TOURIST SAFETY TAB (Matching Image 5: Emergency Help & Safety Protocols)
// ═══════════════════════════════════════════════════
class _TouristSafetyTab extends StatelessWidget {
  const _TouristSafetyTab();

  @override
  Widget build(BuildContext context) {
    return const EmergencyHelpScreen(isApproachingView: false);
  }
}
// ═══════════════════════════════════════════════════
// TOURIST PROFILE TAB
// ═══════════════════════════════════════════════════
class _TouristProfileTab extends StatelessWidget {
  final AuthState auth;
  final VoidCallback onLogout;
  const _TouristProfileTab({required this.auth, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Gradient profile header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 28,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              gradient: AppTheme.forestGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: Colors.white.withValues(alpha: 0.15),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      (auth.user?['full_name'] ?? 'T').substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  auth.user?['full_name'] ?? 'Tourist',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  auth.user?['email'] ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: const Text(
                    'TOURIST',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Menu items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.elevatedShadow,
              ),
              child: Column(
                children: [
                  _menuItem(Icons.settings_rounded, 'Settings', () {}),
                  Divider(height: 1, indent: 56, color: Colors.grey.shade100),
                  _menuItem(Icons.help_outline_rounded, 'Help & Support', () {}),
                  Divider(height: 1, indent: 56, color: Colors.grey.shade100),
                  _menuItem(Icons.info_outline_rounded, 'About ForestGuard', () {}),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.elevatedShadow,
              ),
              child: _menuItem(
                Icons.logout_rounded,
                'Logout',
                onLogout,
                isDestructive: true,
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? AppTheme.dangerRed : AppTheme.textPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isDestructive ? AppTheme.dangerRed : AppTheme.forestGreen).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              if (!isDestructive)
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
