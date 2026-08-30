import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../config/constants.dart';
import '../../widgets/forest_map_view.dart';
import '../../widgets/detection_alert_modal.dart';

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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.warning_amber), selectedIcon: Icon(Icons.warning), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.shield_outlined), selectedIcon: Icon(Icons.shield), label: 'Safety'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// --- Tourist Home Tab ---
class _TouristHomeTab extends ConsumerWidget {
  final AuthState auth;
  const _TouristHomeTab({required this.auth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safetyAsync = ref.watch(safetyStatusProvider);
    final alertsAsync = ref.watch(alertsProvider);
    final zonesAsync = ref.watch(dangerZonesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ForestGuard')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(safetyStatusProvider);
          ref.invalidate(alertsProvider);
          ref.invalidate(dangerZonesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Welcome
            Text(
              'Hello, ${auth.user?['full_name'] ?? 'Tourist'} 👋',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text('Stay informed, stay safe', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 20),

            // Safety Status Card
            safetyAsync.when(
              data: (status) => _SafetyCard(status: status),
              loading: () => const Card(child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))),
              error: (_, __) => _SafetyCard(status: {'status': 'safe', 'message': AppConstants.safetyMessages['safe']!}),
            ),
            const SizedBox(height: 16),

            // Active Alerts
            const Text('Active Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            alertsAsync.when(
              data: (alerts) {
                final active = alerts.where((a) => a['status'] != 'closed' && a['status'] != 'rejected').toList();
                if (active.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle, color: AppTheme.safeGreen, size: 40),
                          const SizedBox(height: 8),
                          const Text('No active alerts', style: TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: active.take(3).map((a) => _AlertCard(alert: a)).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Unable to load alerts'))),
            ),
            const SizedBox(height: 16),

            // Active Danger Zones
            const Text('Active Danger Zones', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            zonesAsync.when(
              data: (zones) {
                if (zones.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.landscape, color: AppTheme.safeGreen, size: 40),
                          const SizedBox(height: 8),
                          const Text('No active danger zones', style: TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: zones.map((z) => _DangerZoneCard(zone: z)).toList(),
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

class _SafetyCard extends StatelessWidget {
  final Map<String, dynamic> status;
  const _SafetyCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = (status['status'] as String?) ?? 'safe';
    final color = AppTheme.getStatusColor(s);
    final message = status['message'] ?? AppConstants.safetyMessages[s] ?? '';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    s.toUpperCase(),
                    style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1),
                  ),
                ),
                const Spacer(),
                Icon(
                  s == 'safe' ? Icons.check_circle : s == 'approaching' ? Icons.warning : Icons.dangerous,
                  color: color,
                  size: 28,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Safety Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(message as String, style: const TextStyle(fontSize: 14, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final animal = alert['animal_type'] ?? 'unknown';
    final emoji = AppConstants.animalEmojis[animal] ?? '🐾';
    final confidence = ((alert['confidence'] ?? 0) as num) * 100;
    final status = alert['status'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(emoji, style: const TextStyle(fontSize: 28)),
        title: Text('${AppConstants.animalNames[animal] ?? animal} Detected',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Confidence: ${confidence.toStringAsFixed(0)}% • $status'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.getStatusColor(status).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(status.toUpperCase(),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.getStatusColor(status))),
        ),
      ),
    );
  }
}

class _DangerZoneCard extends StatelessWidget {
  final Map<String, dynamic> zone;
  const _DangerZoneCard({required this.zone});

  @override
  Widget build(BuildContext context) {
    final animal = zone['animal_type'] ?? 'unknown';
    final emoji = AppConstants.animalEmojis[animal] ?? '🐾';
    final radius = zone['radius_meters'] ?? 0;
    final isSim = zone['is_simulation'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(emoji, style: const TextStyle(fontSize: 28)),
        title: Text('${AppConstants.animalNames[animal]} Zone${isSim ? " (SIM)" : ""}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Radius: ${radius}m'),
        trailing: const Icon(Icons.radio_button_checked, color: AppTheme.dangerRed),
      ),
    );
  }
}

// --- Tourist Map Tab ---
class _TouristMapTab extends ConsumerWidget {
  const _TouristMapTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zonesAsync = ref.watch(dangerZonesProvider);
    final alertsAsync = ref.watch(alertsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Forest OpenStreetMap')),
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
                    constraints: const BoxConstraints(maxHeight: 180),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                    ),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      shrinkWrap: true,
                      children: zones.map((z) => _DangerZoneCard(zone: z)).toList(),
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

// --- Tourist Alerts Tab ---
class _TouristAlertsTab extends ConsumerWidget {
  const _TouristAlertsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);
    final notifAsync = ref.watch(notificationsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Alerts & Notifications'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [Tab(text: 'Alerts'), Tab(text: 'Notifications')],
          ),
        ),
        body: TabBarView(
          children: [
            // Alerts tab
            alertsAsync.when(
              data: (alerts) {
                if (alerts.isEmpty) {
                  return const Center(child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_none, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No alerts', style: TextStyle(color: Colors.grey)),
                    ],
                  ));
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(alertsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: alerts.length,
                    itemBuilder: (_, i) => _AlertCard(alert: alerts[i]),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Unable to load alerts')),
            ),
            // Notifications tab
            notifAsync.when(
              data: (notifs) {
                if (notifs.isEmpty) {
                  return const Center(child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No notifications', style: TextStyle(color: Colors.grey)),
                    ],
                  ));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: notifs.length,
                  itemBuilder: (_, i) {
                    final n = notifs[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          n['type'] == 'wildlife_warning' ? Icons.warning : Icons.info,
                          color: n['type'] == 'wildlife_warning' ? AppTheme.dangerRed : AppTheme.infoBlue,
                        ),
                        title: Text(n['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(n['message'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                        trailing: n['is_read'] == true ? null : Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(color: AppTheme.dangerRed, shape: BoxShape.circle),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Unable to load notifications')),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Tourist Safety Tab ---
class _TouristSafetyTab extends StatelessWidget {
  const _TouristSafetyTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safety Center')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.shield, color: AppTheme.forestGreen),
                    SizedBox(width: 8),
                    Text('Safety Guidelines', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 12),
                  _safetyTip('Keep a safe distance from all wildlife'),
                  _safetyTip('Follow ranger instructions immediately'),
                  _safetyTip('Stay on designated paths and zones'),
                  _safetyTip('Do not feed or provoke animals'),
                  _safetyTip('Keep your GPS enabled for safety alerts'),
                  _safetyTip('Report any wildlife sighting to rangers'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.info, color: AppTheme.infoBlue),
                    SizedBox(width: 8),
                    Text('Safety Status Guide', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 12),
                  _statusInfo('SAFE', AppTheme.safeGreen, 'No active wildlife alert near you'),
                  _statusInfo('APPROACHING', AppTheme.approachingAmber, 'You are nearing an active safety zone'),
                  _statusInfo('INSIDE', AppTheme.dangerRed, 'You are within an active safety zone'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: AppTheme.dangerRed.withValues(alpha: 0.05),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: AppTheme.dangerRed),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Safety radii are operational demo parameters and not scientific or guaranteed safety measures.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _safetyTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: AppTheme.safeGreen, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _statusInfo(String label, Color color, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(desc, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

// --- Tourist Profile Tab ---
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.forestGreen.withValues(alpha: 0.15),
                    child: Text(
                      (auth.user?['full_name'] ?? 'T').substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.forestGreen),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(auth.user?['full_name'] ?? 'Tourist',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        Text(auth.user?['email'] ?? '',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.forestGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('TOURIST',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.forestGreen)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About ForestGuard'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.dangerRed),
            title: const Text('Logout', style: TextStyle(color: AppTheme.dangerRed)),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}
