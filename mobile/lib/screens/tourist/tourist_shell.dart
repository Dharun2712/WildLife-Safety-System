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
class _TouristHomeTab extends ConsumerWidget {
  final AuthState auth;
  const _TouristHomeTab({required this.auth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safetyAsync = ref.watch(safetyStatusProvider);
    final alertsAsync = ref.watch(alertsProvider);
    final zonesAsync = ref.watch(dangerZonesProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(safetyStatusProvider);
          ref.invalidate(alertsProvider);
          ref.invalidate(dangerZonesProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Premium gradient app bar with hero welcome
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: AppTheme.forestGreen,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.forestGradient,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: Colors.white.withValues(alpha: 0.15),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                ),
                                child: Center(
                                  child: Text(
                                    (auth.user?['full_name'] ?? 'T').substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hello, ${auth.user?['full_name'] ?? 'Tourist'} 👋',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Stay informed, stay safe',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              title: const Text('ForestGuard'),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Safety Status Card with glow
                  safetyAsync.when(
                    data: (status) => _PremiumSafetyCard(status: status),
                    loading: () => const SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => _PremiumSafetyCard(
                      status: {'status': 'safe', 'message': AppConstants.safetyMessages['safe']!},
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Active Alerts Section
                  _sectionHeader('Active Alerts', Icons.warning_amber_rounded),
                  const SizedBox(height: 10),
                  alertsAsync.when(
                    data: (alerts) {
                      final active = alerts.where((a) =>
                          a['status'] != 'closed' && a['status'] != 'rejected').toList();
                      if (active.isEmpty) {
                        return _EmptyStateCard(
                          icon: Icons.check_circle_outline_rounded,
                          color: AppTheme.safeGreen,
                          title: 'No Active Alerts',
                          subtitle: 'All clear — enjoy your visit',
                        );
                      }
                      return Column(
                        children: active.take(3).map((a) => _PremiumAlertCard(alert: a)).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => _EmptyStateCard(
                      icon: Icons.cloud_off_rounded,
                      color: Colors.grey,
                      title: 'Unable to load alerts',
                      subtitle: 'Pull down to refresh',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Danger Zones
                  _sectionHeader('Active Danger Zones', Icons.radar_rounded),
                  const SizedBox(height: 10),
                  zonesAsync.when(
                    data: (zones) {
                      if (zones.isEmpty) {
                        return _EmptyStateCard(
                          icon: Icons.landscape_rounded,
                          color: AppTheme.safeGreen,
                          title: 'No Active Danger Zones',
                          subtitle: 'The forest area is currently safe',
                        );
                      }
                      return Column(
                        children: zones.map((z) => _PremiumDangerZoneCard(zone: z)).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox(),
                  ),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.forestGreen),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

// Premium safety card with glow border
class _PremiumSafetyCard extends StatelessWidget {
  final Map<String, dynamic> status;
  const _PremiumSafetyCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = (status['status'] as String?) ?? 'safe';
    final color = AppTheme.getStatusColor(s);
    final message = status['message'] ?? AppConstants.safetyMessages[s] ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          ...AppTheme.elevatedShadow,
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppTheme.getStatusGradient(s),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      s == 'safe' ? Icons.check_circle_rounded
                          : s == 'approaching' ? Icons.warning_rounded
                          : Icons.dangerous_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      s.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  s == 'safe' ? Icons.shield_rounded
                      : s == 'approaching' ? Icons.shield_moon_rounded
                      : Icons.gpp_bad_rounded,
                  color: color,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Safety Status',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            message as String,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
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
// TOURIST ALERTS TAB
// ═══════════════════════════════════════════════════
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
            indicatorWeight: 3,
            tabs: [Tab(text: 'Alerts'), Tab(text: 'Notifications')],
          ),
        ),
        body: TabBarView(
          children: [
            // Alerts tab
            alertsAsync.when(
              data: (alerts) {
                if (alerts.isEmpty) {
                  return Center(child: _EmptyStateCard(
                    icon: Icons.notifications_none_rounded,
                    color: Colors.grey,
                    title: 'No alerts',
                    subtitle: 'You\'re all caught up',
                  ));
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(alertsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: alerts.length,
                    itemBuilder: (_, i) => _PremiumAlertCard(alert: alerts[i]),
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
                  return Center(child: _EmptyStateCard(
                    icon: Icons.inbox_rounded,
                    color: Colors.grey,
                    title: 'No notifications',
                    subtitle: 'Notifications will appear here',
                  ));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifs.length,
                  itemBuilder: (_, i) {
                    final n = notifs[i];
                    final isWarning = n['type'] == 'wildlife_warning';
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
                              decoration: BoxDecoration(
                                color: isWarning ? AppTheme.dangerRed : AppTheme.infoBlue,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (isWarning ? AppTheme.dangerRed : AppTheme.infoBlue).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isWarning ? Icons.warning_rounded : Icons.info_rounded,
                                    color: isWarning ? AppTheme.dangerRed : AppTheme.infoBlue,
                                    size: 20,
                                  ),
                                ),
                                title: Text(n['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                subtitle: Text(
                                  n['message'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                                trailing: n['is_read'] == true ? null : Container(
                                  width: 10, height: 10,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.dangerGradient,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.dangerRed.withValues(alpha: 0.3),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
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

// ═══════════════════════════════════════════════════
// TOURIST SAFETY TAB
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
          // Safety Guidelines
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.elevatedShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.forestGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shield_rounded, color: AppTheme.forestGreen, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text('Safety Guidelines', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 16),
                _safetyTip('Keep a safe distance from all wildlife'),
                _safetyTip('Follow ranger instructions immediately'),
                _safetyTip('Stay on designated paths and zones'),
                _safetyTip('Do not feed or provoke animals'),
                _safetyTip('Keep your GPS enabled for safety alerts'),
                _safetyTip('Report any wildlife sighting to rangers'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Status Guide
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.elevatedShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.infoBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.info_rounded, color: AppTheme.infoBlue, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text('Safety Status Guide', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 16),
                _statusInfo('SAFE', AppTheme.safeGreen, 'No active wildlife alert near you'),
                _statusInfo('APPROACHING', AppTheme.approachingAmber, 'You are nearing an active safety zone'),
                _statusInfo('INSIDE', AppTheme.dangerRed, 'You are within an active safety zone'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.approachingAmber.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.approachingAmber.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.approachingAmber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: AppTheme.approachingAmber, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Safety radii are operational demo parameters and not scientific or guaranteed safety measures.',
                    style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _safetyTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppTheme.safeGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.check_rounded, color: AppTheme.safeGreen, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, height: 1.3))),
        ],
      ),
    );
  }

  Widget _statusInfo(String label, Color color, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 0.5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(desc, style: const TextStyle(fontSize: 13, height: 1.3))),
        ],
      ),
    );
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
