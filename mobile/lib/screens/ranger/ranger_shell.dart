import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/providers.dart';
import '../../services/api_service.dart';
import '../../widgets/forest_map_view.dart';
import '../../widgets/detection_alert_modal.dart';

class RangerShell extends ConsumerStatefulWidget {
  const RangerShell({super.key});

  @override
  ConsumerState<RangerShell> createState() => _RangerShellState();
}

class _RangerShellState extends ConsumerState<RangerShell> {
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
          eventType == 'danger_zone_updated') {

        final data = event['data'] is Map ? Map<String, dynamic>.from(event['data']) : event;

        // Invalidate providers so map and alerts refresh reactively
        ref.invalidate(dangerZonesProvider);
        ref.invalidate(alertsProvider);
        ref.invalidate(touristsProvider);
        ref.invalidate(camerasProvider);

        if (mounted) {
          DetectionAlertModal.show(
            context,
            detection: data,
            isRanger: true,
            onViewOnMap: () {
              setState(() => _currentIndex = 2); // Switch to Ranger Map tab
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
          _RangerHomeTab(auth: auth),
          const _RangerAlertsTab(),
          const _RangerMapTab(),
          const _RangerMonitorTab(),
          _RangerProfileTab(auth: auth, onLogout: () async {
            final router = GoRouter.of(context);
            await ref.read(authProvider.notifier).logout();
            router.go('/role-select');
          }),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.notification_important_outlined), selectedIcon: Icon(Icons.notification_important), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.videocam_outlined), selectedIcon: Icon(Icons.videocam), label: 'Monitor'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// ==========================================
// 1. RANGER HOME TAB
// ==========================================
class _RangerHomeTab extends ConsumerWidget {
  final AuthState auth;
  const _RangerHomeTab({required this.auth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);
    final zonesAsync = ref.watch(dangerZonesProvider);
    final camerasAsync = ref.watch(camerasProvider);
    final detectionsAsync = ref.watch(detectionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranger Operations HQ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(alertsProvider);
              ref.invalidate(dangerZonesProvider);
              ref.invalidate(camerasProvider);
              ref.invalidate(detectionsProvider);
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(alertsProvider);
          ref.invalidate(dangerZonesProvider);
          ref.invalidate(camerasProvider);
          ref.invalidate(detectionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Officer ${auth.user?['full_name'] ?? 'Ranger'} 🛡️',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text('Mudumalai Wildlife Reserve Sector', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF1565C0)),
                  ),
                  child: const Text('ON DUTY', style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold, fontSize: 11)),
                )
              ],
            ),
            const SizedBox(height: 20),

            // Operational Metric Cards
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Active Alerts',
                    count: alertsAsync.value?.where((a) => a['status'] == 'active' || a['status'] == 'needs_verification' || a['status'] == 'monitoring').length.toString() ?? '...',
                    icon: Icons.warning_amber_rounded,
                    color: AppTheme.dangerRed,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Danger Zones',
                    count: zonesAsync.value?.length.toString() ?? '...',
                    icon: Icons.radar,
                    color: AppTheme.approachingAmber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Live Cameras',
                    count: '${camerasAsync.value?.where((c) => c['status'] == 'online').length ?? 0}/${camerasAsync.value?.length ?? 0}',
                    icon: Icons.videocam,
                    color: const Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Total Detections',
                    count: detectionsAsync.value?.length.toString() ?? '...',
                    icon: Icons.pets,
                    color: AppTheme.forestGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // High Priority Pending Verification Alerts
            const Text('Action Required (High Priority)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            alertsAsync.when(
              data: (alerts) {
                final pending = alerts.where((a) => a['status'] == 'needs_verification' || a['status'] == 'active').toList();
                if (pending.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: AppTheme.safeGreen, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('All Sectors Normal', style: TextStyle(fontWeight: FontWeight.w600)),
                                Text('No pending unverified alerts or unacknowledged incidents.', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: pending.take(3).map((a) => _RangerAlertActionCard(alert: a, ref: ref)).toList(),
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
              error: (err, _) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: $err'))),
            ),
            const SizedBox(height: 20),

            // Recent Wildlife Detections Feed
            const Text('Recent Live AI Detections', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            detectionsAsync.when(
              data: (dets) {
                if (dets.isEmpty) {
                  return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No detections recorded yet.')));
                }
                return Column(
                  children: dets.take(4).map((d) {
                    final animal = d['animal_type'] ?? 'unknown';
                    final isSim = d['is_simulation'] == true;
                    final conf = (((d['confidence'] ?? 0) as num) * 100).toStringAsFixed(0);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Text(AppConstants.animalEmojis[animal] ?? '🐾', style: const TextStyle(fontSize: 26)),
                        title: Text('${AppConstants.animalNames[animal] ?? animal} ${isSim ? "(Simulated)" : ""}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text('Camera: ${d['camera_id']} • Conf: $conf% • ${d['status']}'),
                        trailing: Text(
                          d['timestamp'] != null ? d['timestamp'].toString().split('T').last.split('.').first : '',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;

  const _MetricCard({required this.title, required this.count, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. RANGER ALERTS TAB & ACTIONS
// ==========================================
class _RangerAlertsTab extends ConsumerWidget {
  const _RangerAlertsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident & Alert Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(alertsProvider),
          )
        ],
      ),
      body: alertsAsync.when(
        data: (alerts) {
          if (alerts.isEmpty) {
            return const Center(child: Text('No alerts in database.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(alertsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: alerts.length,
              itemBuilder: (ctx, i) => _RangerAlertActionCard(alert: alerts[i], ref: ref),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading alerts: $err')),
      ),
    );
  }
}

class _RangerAlertActionCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  final WidgetRef ref;

  const _RangerAlertActionCard({required this.alert, required this.ref});

  @override
  Widget build(BuildContext context) {
    final animal = alert['animal_type'] ?? 'unknown';
    final emoji = AppConstants.animalEmojis[animal] ?? '🐾';
    final status = alert['status'] ?? 'unknown';
    final isNeedsVerify = status == 'needs_verification';
    final isActive = status == 'active';
    final isAck = status == 'acknowledged' || status == 'monitoring';
    final isClosed = status == 'closed' || status == 'rejected';
    final alertId = alert['id'] ?? '';
    final conf = (((alert['confidence'] ?? 0) as num) * 100).toStringAsFixed(0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isNeedsVerify ? AppTheme.approachingAmber : isActive ? AppTheme.dangerRed : Colors.grey.shade300,
          width: isNeedsVerify || isActive ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AppConstants.animalNames[animal] ?? animal} Incident',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      Text('Zone ${alert['zone_code'] ?? 'A'} • Confidence: $conf% • ID: ${alertId.toString().substring(0, alertId.toString().length > 8 ? 8 : alertId.toString().length)}'),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.getStatusColor(status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(color: AppTheme.getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Coordinates: Lat ${(alert['latitude'] as num?)?.toStringAsFixed(4)}, Lng ${(alert['longitude'] as num?)?.toStringAsFixed(4)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const Divider(height: 20),

            // Action Buttons based on Alert State Machine
            if (!isClosed)
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (isNeedsVerify) ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.safeGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Verify & Activate', style: TextStyle(fontSize: 12)),
                      onPressed: () => _executeAction(context, '/api/alerts/$alertId/verify', 'Verified & Activated Danger Zone'),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: AppTheme.dangerRed, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject AI Detection', style: TextStyle(fontSize: 12)),
                      onPressed: () => _executeAction(context, '/api/alerts/$alertId/reject', 'Detection Rejected'),
                    ),
                  ],
                  if (isActive)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      icon: const Icon(Icons.done_all, size: 16),
                      label: const Text('Acknowledge', style: TextStyle(fontSize: 12)),
                      onPressed: () => _executeAction(context, '/api/alerts/$alertId/acknowledge', 'Alert Acknowledged'),
                    ),
                  if (isActive || isAck) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      icon: const Icon(Icons.edit_location_alt, size: 16),
                      label: const Text('Update Animal Location', style: TextStyle(fontSize: 12)),
                      onPressed: () => _showUpdateLocationDialog(context, alertId, (alert['latitude'] as num?)?.toDouble() ?? 11.569, (alert['longitude'] as num?)?.toDouble() ?? 76.632),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.blueGrey, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      icon: const Icon(Icons.people_outline, size: 16),
                      label: const Text('Tourists in Zone', style: TextStyle(fontSize: 12)),
                      onPressed: () => _showTouristsInZoneDialog(context, alertId),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      icon: const Icon(Icons.lock_outline, size: 16),
                      label: const Text('Close Alert', style: TextStyle(fontSize: 12)),
                      onPressed: () => _executeAction(context, '/api/alerts/$alertId/close', 'Alert & Danger Zone Closed'),
                    ),
                  ],
                ],
              )
            else
              Text(
                'Incident Resolved / Closed by Ranger.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _executeAction(BuildContext context, String endpoint, String successMsg) async {
    try {
      await ApiService().dio.patch(endpoint);
      ref.invalidate(alertsProvider);
      ref.invalidate(dangerZonesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ $successMsg')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Action failed: $e')));
      }
    }
  }

  void _showUpdateLocationDialog(BuildContext context, String alertId, double currentLat, double currentLng) {
    final latCtl = TextEditingController(text: (currentLat + 0.0015).toStringAsFixed(4));
    final lngCtl = TextEditingController(text: (currentLng + 0.0015).toStringAsFixed(4));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move Danger Zone Center'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter updated wildlife coordinates to dynamically move the active danger zone for all tourists and rangers in real-time.', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            TextField(controller: latCtl, decoration: const InputDecoration(labelText: 'New Latitude')),
            const SizedBox(height: 8),
            TextField(controller: lngCtl, decoration: const InputDecoration(labelText: 'New Longitude')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newLat = double.tryParse(latCtl.text);
              final newLng = double.tryParse(lngCtl.text);
              if (newLat == null || newLng == null) return;
              Navigator.pop(ctx);
              try {
                await ApiService().dio.patch('/api/alerts/$alertId/location', data: {
                  'latitude': newLat,
                  'longitude': newLng,
                });
                ref.invalidate(alertsProvider);
                ref.invalidate(dangerZonesProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Wildlife danger zone moved in real-time!')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Location update failed: $e')));
                }
              }
            },
            child: const Text('Broadcast Update'),
          ),
        ],
      ),
    );
  }

  void _showTouristsInZoneDialog(BuildContext context, String alertId) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Authorized Incident Tourist View'),
        content: FutureBuilder(
          future: ApiService().dio.get('/api/tourists/locations/nearby', queryParameters: {'alert_id': alertId}),
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return Text('Error fetching tourist data: ${snapshot.error}');
            }
            final data = snapshot.data?.data as Map<String, dynamic>?;
            final tourists = data?['tourists'] as List<dynamic>? ?? [];
            if (tourists.isEmpty) {
              return const Text('No tourists currently detected inside or approaching this danger radius.');
            }
            return SizedBox(
              width: double.maxFinite,
              height: 200,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: tourists.length,
                itemBuilder: (ctx, i) {
                  final t = tourists[i];
                  return ListTile(
                    leading: const Icon(Icons.person_pin_circle, color: AppTheme.dangerRed),
                    title: Text('Tourist ID: ${t['tourist_id'].toString().substring(0, 6)}...'),
                    subtitle: Text('Distance: ${t['distance_meters']}m • Status: ${t['status']}'),
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}

// ==========================================
// 3. RANGER MAP TAB
// ==========================================
class _RangerMapTab extends ConsumerWidget {
  const _RangerMapTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zonesAsync = ref.watch(dangerZonesProvider);
    final alertsAsync = ref.watch(alertsProvider);
    final touristsAsync = ref.watch(touristsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ranger Tactical Sector OpenStreetMap')),
      body: zonesAsync.when(
        data: (zones) {
          final alerts = alertsAsync.value ?? [];
          final tourists = touristsAsync.value ?? [];
          return Stack(
            children: [
              ForestMapView(
                dangerZones: zones,
                alerts: alerts,
                touristLocations: tourists,
                isRanger: true,
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Card(
                  color: Colors.grey.shade900.withOpacity(0.9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tactical Legend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _legendItem('🐯 Tiger (2000m)', const Color(0xFFFF6F00)),
                            _legendItem('🐘 Elephant (2500m)', const Color(0xFF00D2FF)),
                            _legendItem('🦁 Lion (2000m)', const Color(0xFFEF4444)),
                          ],
                        ),
                      ],
                    ),
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

  Widget _legendItem(String title, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ==========================================
// 4. RANGER MONITOR & REPORTING TAB
// ==========================================
class _RangerMonitorTab extends ConsumerWidget {
  const _RangerMonitorTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final camerasAsync = ref.watch(camerasProvider);
    final detReportAsync = ref.watch(reportsProvider('detections'));
    final incReportAsync = ref.watch(reportsProvider('incidents'));

    return Scaffold(
      appBar: AppBar(title: const Text('Live Camera & Incident Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Camera Network Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          camerasAsync.when(
            data: (cameras) => Column(
              children: cameras.map((c) => Card(
                child: ListTile(
                  leading: const Icon(Icons.videocam, color: AppTheme.safeGreen),
                  title: Text('${c['camera_id']} - ${c['name']}'),
                  subtitle: Text('Type: ${c['type']} • Status: ${c['status'].toString().toUpperCase()}'),
                  trailing: const Icon(Icons.circle, color: AppTheme.safeGreen, size: 12),
                ),
              )).toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Unable to load camera data.'),
          ),
          const SizedBox(height: 20),

          const Text('Incident Intelligence Summary (7 Days)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          incReportAsync.when(
            data: (inc) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _reportRow('Total Alerts Recorded', '${inc['total_alerts'] ?? 0}'),
                    _reportRow('Currently Active Danger Zones', '${inc['active_danger_zones'] ?? 0}'),
                    _reportRow('Successfully Closed Alerts', '${inc['closed'] ?? 0}'),
                    _reportRow('Rejected Low-Conf Alerts', '${inc['rejected'] ?? 0}'),
                  ],
                ),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 16),

          const Text('Wildlife Sighting Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          detReportAsync.when(
            data: (det) {
              final list = det['by_animal'] as List<dynamic>? ?? [];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: list.map((a) => _reportRow('${AppConstants.animalNames[a['animal_type']] ?? a['animal_type']}', '${a['count']} detections (Avg Conf: ${(((a['avg_confidence'] ?? 0) as num) * 100).toStringAsFixed(0)}%)')).toList(),
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _reportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ==========================================
// 5. RANGER PROFILE TAB
// ==========================================
class _RangerProfileTab extends StatelessWidget {
  final AuthState auth;
  final VoidCallback onLogout;

  const _RangerProfileTab({required this.auth, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ranger Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF1565C0).withValues(alpha: 0.15),
                    child: Text(
                      (auth.user?['full_name'] ?? 'R').substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1565C0)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(auth.user?['full_name'] ?? 'Ranger Officer', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        Text('Badge: ${auth.user?['badge_number'] ?? "MWR-001"} • Role: RANGER', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(auth.user?['email'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(leading: const Icon(Icons.security), title: const Text('Sector Security Protocols'), trailing: const Icon(Icons.chevron_right), onTap: () {}),
          ListTile(leading: const Icon(Icons.tune), title: const Text('Detection Threshold Config'), trailing: const Icon(Icons.chevron_right), onTap: () {}),
          ListTile(leading: const Icon(Icons.info_outline), title: const Text('ForestGuard Version 1.0.0'), trailing: const Icon(Icons.chevron_right), onTap: () {}),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.dangerRed),
            title: const Text('Sign Out', style: TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold)),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}
