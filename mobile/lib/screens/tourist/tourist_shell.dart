import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../config/constants.dart';
import '../../widgets/forest_map_view.dart';
import '../../widgets/detection_alert_modal.dart';
import '../../widgets/sos_active_dialog.dart';

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

        ref.invalidate(dangerZonesProvider);
        ref.invalidate(alertsProvider);
        ref.invalidate(safetyStatusProvider);

        if (mounted) {
          DetectionAlertModal.show(
            context,
            detection: data,
            isRanger: false,
            onViewOnMap: () {
              setState(() => _currentIndex = 1);
            },
            onTriggerSOS: () {
              SOSActiveDialog.show(context);
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
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: [
              _TouristHomeTab(
                auth: auth,
                onViewMap: () => setState(() => _currentIndex = 1),
              ),
              const _TouristMapTab(),
              const _TouristAlertsTab(),
              const _TouristSafetyTab(),
              _TouristProfileTab(
                auth: auth,
                onLogout: () async {
                  final router = GoRouter.of(context);
                  await ref.read(authProvider.notifier).logout();
                  router.go('/role-select');
                },
              ),
            ],
          ),

          // Google Stitch Floating SOS Emergency Button (Pulsing Red FAB)
          Positioned(
            bottom: 90,
            right: 18,
            child: _StitchSOSButton(
              onPressed: () => SOSActiveDialog.show(context),
            ),
          ),
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
// GOOGLE STITCH SOS BUTTON (Pulsing Red FAB)
// ═══════════════════════════════════════════════════
class _StitchSOSButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _StitchSOSButton({required this.onPressed});

  @override
  State<_StitchSOSButton> createState() => _StitchSOSButtonState();
}

class _StitchSOSButtonState extends State<_StitchSOSButton> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: SizedBox(
        width: 64,
        height: 64,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulsing Ring
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                final scale = 1.0 + (_pulseController.value * 0.4);
                final opacity = 0.5 * (1.0 - _pulseController.value);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: opacity),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
            // Solid SOS FAB
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppTheme.error,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                boxShadow: AppTheme.sosShadow,
              ),
              child: const Center(
                child: Text(
                  'SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// TOURIST HOME TAB — Google Stitch Safety Dashboard
// ═══════════════════════════════════════════════════
class _TouristHomeTab extends ConsumerWidget {
  final AuthState auth;
  final VoidCallback onViewMap;
  const _TouristHomeTab({required this.auth, required this.onViewMap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safetyAsync = ref.watch(safetyStatusProvider);
    final alertsAsync = ref.watch(alertsProvider);
    final zonesAsync = ref.watch(dangerZonesProvider);
    final detectionsAsync = ref.watch(detectionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.85),
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  (auth.user?['full_name'] ?? 'T').substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text('ForestGuard', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppTheme.primary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppTheme.primary),
            onPressed: () {
              ref.invalidate(safetyStatusProvider);
              ref.invalidate(alertsProvider);
              ref.invalidate(dangerZonesProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(safetyStatusProvider);
          ref.invalidate(alertsProvider);
          ref.invalidate(dangerZonesProvider);
          ref.invalidate(detectionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // Stitch Safety Status Banner
            safetyAsync.when(
              data: (status) => _StitchSafetyBanner(status: status),
              loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => _StitchSafetyBanner(
                status: {'status': 'safe', 'message': AppConstants.safetyMessages['safe']!},
              ),
            ),
            const SizedBox(height: 16),

            // Stitch 2-Column Widgets Grid (Weather + Trail)
            Row(
              children: [
                Expanded(
                  child: _StitchWeatherWidget(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StitchTrailWidget(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Stitch Nearby Activity Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Nearby Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                TextButton.icon(
                  onPressed: onViewMap,
                  icon: const Text('Expand Map', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.secondary)),
                  label: const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.secondary),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Map Preview Snippet with Teardrop Badge Marker
            _StitchMapPreviewCard(onViewMap: onViewMap, zonesAsync: zonesAsync),
            const SizedBox(height: 16),

            // Recent AI Detections Carousel (Horizontal Scroll Cards)
            const Text('Recent Detections', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.primary)),
            const SizedBox(height: 10),
            detectionsAsync.when(
              data: (dets) {
                if (dets.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No recent wildlife sightings recorded.'),
                    ),
                  );
                }
                return SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: dets.length,
                    itemBuilder: (ctx, i) {
                      final d = dets[i];
                      final animal = d['animal_type'] ?? 'unknown';
                      final emoji = AppConstants.animalEmojis[animal] ?? '🐾';
                      final conf = (((d['confidence'] ?? 0) as num) * 100).toStringAsFixed(0);

                      return Container(
                        width: 200,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
                          boxShadow: AppTheme.ambientShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(emoji, style: const TextStyle(fontSize: 24)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('Conf: $conf%', style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              AppConstants.animalNames[animal] ?? animal,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.primary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Camera ${d['camera_id']} • Zone A',
                              style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
            ),

            const SizedBox(height: 24),

            // Active Alerts Section
            const Text('Active Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.primary)),
            const SizedBox(height: 10),
            alertsAsync.when(
              data: (alerts) {
                final active = alerts.where((a) => a['status'] != 'closed' && a['status'] != 'rejected').toList();
                if (active.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.ambientShadow,
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: AppTheme.safeGreen, size: 28),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('All Sectors Normal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            Text('No active wildlife proximity warnings', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: active.take(3).map((a) => _StitchAlertCard(alert: a)).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

// Stitch Verified Safety Banner Card
class _StitchSafetyBanner extends StatelessWidget {
  final Map<String, dynamic> status;
  const _StitchSafetyBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = (status['status'] as String?) ?? 'safe';
    final isClear = s == 'safe';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isClear ? AppTheme.secondaryContainer.withValues(alpha: 0.4) : AppTheme.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isClear ? AppTheme.secondary : AppTheme.error).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (isClear ? AppTheme.secondary : AppTheme.error).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isClear ? Icons.verified_rounded : Icons.warning_rounded,
              color: isClear ? AppTheme.secondary : AppTheme.error,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isClear ? 'Safety Status: All Clear' : 'PROXIMITY WARNING',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isClear ? AppTheme.onSecondaryContainer : AppTheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isClear ? 'Conditions are stable. Enjoy your visit.' : 'Active wildlife detected near your sector.',
                  style: TextStyle(
                    fontSize: 13,
                    color: (isClear ? AppTheme.onSecondaryContainer : AppTheme.onErrorContainer).withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Stitch Weather Widget
class _StitchWeatherWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: AppTheme.ambientShadow,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.wb_sunny_outlined, color: AppTheme.outline, size: 20),
              Text('North Sector', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.onSurfaceVariant)),
            ],
          ),
          SizedBox(height: 8),
          Text('72°F', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.primary)),
          SizedBox(height: 2),
          Text('Moderate UV Index', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// Stitch Trail Condition Widget
class _StitchTrailWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: AppTheme.ambientShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.hiking_rounded, color: AppTheme.outline, size: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Open', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.onSecondaryContainer)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Trails Dry', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.primary)),
          const SizedBox(height: 2),
          const Text('Good visibility today.', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// Map Preview Snippet
class _StitchMapPreviewCard extends StatelessWidget {
  final VoidCallback onViewMap;
  final AsyncValue<List<Map<String, dynamic>>> zonesAsync;
  const _StitchMapPreviewCard({required this.onViewMap, required this.zonesAsync});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onViewMap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppTheme.primaryContainer,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
          boxShadow: AppTheme.ambientShadow,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ForestMapView(
              dangerZones: zonesAsync.value ?? [],
              alerts: const [],
              isRanger: false,
            ),
            // Glass Overlay Banner
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.my_location_rounded, color: AppTheme.primary, size: 16),
                    SizedBox(width: 8),
                    Text('Mudumalai Sector 4 • GPS Online', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                    Spacer(),
                    Icon(Icons.open_in_full_rounded, size: 16, color: AppTheme.primary),
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

// Stitch Alert Card
class _StitchAlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  const _StitchAlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final animal = alert['animal_type'] ?? 'unknown';
    final emoji = AppConstants.animalEmojis[animal] ?? '🐾';
    final status = alert['status'] ?? '';
    final statusColor = AppTheme.getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: AppTheme.ambientShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppConstants.animalNames[animal] ?? animal} Proximity Alert',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.primary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Zone ${alert['zone_code'] ?? 'A'} • ${alert['verification_status'] ?? status}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// MAP TAB
// ═══════════════════════════════════════════════════
class _TouristMapTab extends ConsumerWidget {
  const _TouristMapTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zonesAsync = ref.watch(dangerZonesProvider);
    final alertsAsync = ref.watch(alertsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Live Forest Map')),
      body: zonesAsync.when(
        data: (zones) {
          final alerts = alertsAsync.value ?? [];
          return ForestMapView(
            dangerZones: zones,
            alerts: alerts,
            isRanger: false,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Unable to load map data')),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// ALERTS TAB
// ═══════════════════════════════════════════════════
class _TouristAlertsTab extends ConsumerWidget {
  const _TouristAlertsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications & Warnings')),
      body: alertsAsync.when(
        data: (alerts) {
          if (alerts.isEmpty) {
            return const Center(child: Text('No active warnings.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            itemBuilder: (_, i) => _StitchAlertCard(alert: alerts[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Unable to load alerts')),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// SAFETY TAB
// ═══════════════════════════════════════════════════
class _TouristSafetyTab extends StatelessWidget {
  const _TouristSafetyTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safety Center')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.ambientShadow,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Safety Protocol', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                SizedBox(height: 12),
                Text('• Stay on official designated paths.', style: TextStyle(fontSize: 14)),
                SizedBox(height: 6),
                Text('• Maintain distance if animals are spotted.', style: TextStyle(fontSize: 14)),
                SizedBox(height: 6),
                Text('• Use SOS button immediately in an emergency.', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// PROFILE TAB
// ═══════════════════════════════════════════════════
class _TouristProfileTab extends StatelessWidget {
  final AuthState auth;
  final VoidCallback onLogout;
  const _TouristProfileTab({required this.auth, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.ambientShadow,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primaryContainer,
                  child: Text(
                    (auth.user?['full_name'] ?? 'T').substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(auth.user?['full_name'] ?? 'Tourist', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    Text(auth.user?['email'] ?? '', style: const TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: onLogout,
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
