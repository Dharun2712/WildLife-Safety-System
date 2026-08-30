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
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.notification_important_outlined), selectedIcon: Icon(Icons.notification_important_rounded), label: 'Alerts'),
            NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map_rounded), label: 'Map'),
            NavigationDestination(icon: Icon(Icons.videocam_outlined), selectedIcon: Icon(Icons.videocam_rounded), label: 'Monitor'),
            NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// 1. RANGER HOME TAB — Tactical Dashboard
// ═══════════════════════════════════════════════════
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
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(alertsProvider);
          ref.invalidate(dangerZonesProvider);
          ref.invalidate(camerasProvider);
          ref.invalidate(detectionsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Ranger gradient app bar
            SliverAppBar(
              expandedHeight: 170,
              pinned: true,
              backgroundColor: AppTheme.rangerBlue,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () {
                    ref.invalidate(alertsProvider);
                    ref.invalidate(dangerZonesProvider);
                    ref.invalidate(camerasProvider);
                    ref.invalidate(detectionsProvider);
                  },
                )
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(gradient: AppTheme.rangerGradient),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Officer ${auth.user?['full_name'] ?? 'Ranger'} 🛡️',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Mudumalai Wildlife Reserve',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8, height: 8,
                                      decoration: BoxDecoration(
                                        color: AppTheme.safeGreen,
                                        shape: BoxShape.circle,
                                        boxShadow: [BoxShadow(color: AppTheme.safeGreen.withValues(alpha: 0.4), blurRadius: 4)],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text('ON DUTY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.5)),
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
              title: const Text('Ranger HQ'),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Metric Cards Grid
                  Row(
                    children: [
                      Expanded(
                        child: _GlassMetricCard(
                          title: 'Active Alerts',
                          count: alertsAsync.value?.where((a) => a['status'] == 'active' || a['status'] == 'needs_verification' || a['status'] == 'monitoring').length.toString() ?? '...',
                          icon: Icons.warning_amber_rounded,
                          color: AppTheme.dangerRed,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _GlassMetricCard(
                          title: 'Danger Zones',
                          count: zonesAsync.value?.length.toString() ?? '...',
                          icon: Icons.radar_rounded,
                          color: AppTheme.approachingAmber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _GlassMetricCard(
                          title: 'Live Cameras',
                          count: '${camerasAsync.value?.where((c) => c['status'] == 'online').length ?? 0}/${camerasAsync.value?.length ?? 0}',
                          icon: Icons.videocam_rounded,
                          color: AppTheme.rangerBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _GlassMetricCard(
                          title: 'Detections',
                          count: detectionsAsync.value?.length.toString() ?? '...',
                          icon: Icons.pets_rounded,
                          color: AppTheme.forestGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Action Required
                  Row(
                    children: [
                      Icon(Icons.priority_high_rounded, size: 20, color: AppTheme.dangerRed),
                      const SizedBox(width: 8),
                      const Text('Action Required', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  alertsAsync.when(
                    data: (alerts) {
                      final pending = alerts.where((a) => a['status'] == 'needs_verification' || a['status'] == 'active').toList();
                      if (pending.isEmpty) {
                        return _PremiumEmptyState(
                          icon: Icons.check_circle_outline_rounded,
                          color: AppTheme.safeGreen,
                          title: 'All Sectors Normal',
                          subtitle: 'No pending alerts require your attention',
                        );
                      }
                      return Column(
                        children: pending.take(3).map((a) => _RangerAlertActionCard(alert: a, ref: ref)).toList(),
                      );
                    },
                    loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                    error: (err, _) => Text('Error: $err'),
                  ),
                  const SizedBox(height: 28),

                  // Recent Detections
                  Row(
                    children: [
                      Icon(Icons.timeline_rounded, size: 20, color: AppTheme.forestGreen),
                      const SizedBox(width: 8),
                      const Text('Recent AI Detections', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  detectionsAsync.when(
                    data: (dets) {
                      if (dets.isEmpty) {
                        return _PremiumEmptyState(
                          icon: Icons.pets_rounded,
                          color: Colors.grey,
                          title: 'No detections yet',
                          subtitle: 'AI camera detections will appear here',
                        );
                      }
                      return Column(
                        children: dets.take(4).map((d) {
                          final animal = d['animal_type'] ?? 'unknown';
                          final isSim = d['is_simulation'] == true;
                          final conf = (((d['confidence'] ?? 0) as num) * 100).toStringAsFixed(0);
                          final animalColor = AppTheme.animalColors[animal] ?? Colors.grey;

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
                                      color: animalColor,
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
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: animalColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Text(
                                                AppConstants.animalEmojis[animal] ?? '🐾',
                                                style: const TextStyle(fontSize: 24),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${AppConstants.animalNames[animal] ?? animal} ${isSim ? "(Sim)" : ""}',
                                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Camera: ${d['camera_id']} • Conf: $conf%',
                                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            d['timestamp'] != null
                                                ? d['timestamp'].toString().split('T').last.split('.').first
                                                : '',
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
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
}

// Premium glassmorphism metric card
class _GlassMetricCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;

  const _GlassMetricCard({required this.title, required this.count, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          ...AppTheme.elevatedShadow,
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(count, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Premium empty state
class _PremiumEmptyState extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _PremiumEmptyState({required this.icon, required this.color, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// 2. RANGER ALERTS TAB & ACTIONS
// ═══════════════════════════════════════════════════
class _RangerAlertsTab extends ConsumerWidget {
  const _RangerAlertsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(alertsProvider),
          )
        ],
      ),
      body: alertsAsync.when(
        data: (alerts) {
          if (alerts.isEmpty) {
            return Center(
              child: _PremiumEmptyState(
                icon: Icons.inbox_rounded,
                color: Colors.grey,
                title: 'No incidents',
                subtitle: 'Incidents will appear here',
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(alertsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
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
    final statusColor = AppTheme.getStatusColor(status);
    final animalColor = AppTheme.animalColors[animal] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (isNeedsVerify || isActive) ? statusColor.withValues(alpha: 0.3) : Colors.grey.shade200,
          width: (isNeedsVerify || isActive) ? 1.5 : 1,
        ),
        boxShadow: [
          if (isNeedsVerify || isActive)
            BoxShadow(
              color: statusColor.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ...AppTheme.elevatedShadow,
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: animalColor.withValues(alpha: 0.1),
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
                        '${AppConstants.animalNames[animal] ?? animal} Incident',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Zone ${alert['zone_code'] ?? 'A'} • Conf: $conf% • ${alertId.toString().substring(0, alertId.toString().length > 8 ? 8 : alertId.toString().length)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: AppTheme.getStatusGradient(status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Lat ${(alert['latitude'] as num?)?.toStringAsFixed(4)}, Lng ${(alert['longitude'] as num?)?.toStringAsFixed(4)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const Divider(height: 20),

            // Action buttons
            if (!isClosed)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (isNeedsVerify) ...[
                    _actionButton(
                      context,
                      icon: Icons.check_rounded,
                      label: 'Verify & Activate',
                      gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF22C55E)]),
                      onTap: () => _executeAction(context, '/api/alerts/$alertId/verify', 'Verified & Activated'),
                    ),
                    _actionButton(
                      context,
                      icon: Icons.close_rounded,
                      label: 'Reject',
                      isOutlined: true,
                      outlineColor: AppTheme.dangerRed,
                      onTap: () => _executeAction(context, '/api/alerts/$alertId/reject', 'Detection Rejected'),
                    ),
                  ],
                  if (isActive)
                    _actionButton(
                      context,
                      icon: Icons.done_all_rounded,
                      label: 'Acknowledge',
                      gradient: AppTheme.rangerGradient,
                      onTap: () => _executeAction(context, '/api/alerts/$alertId/acknowledge', 'Alert Acknowledged'),
                    ),
                  if (isActive || isAck) ...[
                    _actionButton(
                      context,
                      icon: Icons.edit_location_alt_rounded,
                      label: 'Move Zone',
                      isOutlined: true,
                      onTap: () => _showUpdateLocationDialog(context, alertId, (alert['latitude'] as num?)?.toDouble() ?? 11.569, (alert['longitude'] as num?)?.toDouble() ?? 76.632),
                    ),
                    _actionButton(
                      context,
                      icon: Icons.people_outline_rounded,
                      label: 'Tourists',
                      isOutlined: true,
                      onTap: () => _showTouristsInZoneDialog(context, alertId),
                    ),
                    _actionButton(
                      context,
                      icon: Icons.lock_outline_rounded,
                      label: 'Close Alert',
                      gradient: AppTheme.dangerGradient,
                      onTap: () => _executeAction(context, '/api/alerts/$alertId/close', 'Alert Closed'),
                    ),
                  ],
                ],
              )
            else
              Text(
                'Incident Resolved / Closed by Ranger.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade500),
              ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(BuildContext context, {
    required IconData icon,
    required String label,
    LinearGradient? gradient,
    bool isOutlined = false,
    Color? outlineColor,
    required VoidCallback onTap,
  }) {
    if (isOutlined) {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: outlineColor ?? AppTheme.textPrimary,
          side: BorderSide(color: (outlineColor ?? Colors.grey).withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        onPressed: onTap,
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),
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
        title: const Text('Tourists in Zone'),
        content: FutureBuilder(
          future: ApiService().dio.get('/api/tourists/locations/nearby', queryParameters: {'alert_id': alertId}),
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            final data = snapshot.data?.data as Map<String, dynamic>?;
            final tourists = data?['tourists'] as List<dynamic>? ?? [];
            if (tourists.isEmpty) {
              return const Text('No tourists currently detected in this danger zone.');
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

// ═══════════════════════════════════════════════════
// 3. RANGER MAP TAB
// ═══════════════════════════════════════════════════
class _RangerMapTab extends ConsumerWidget {
  const _RangerMapTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zonesAsync = ref.watch(dangerZonesProvider);
    final alertsAsync = ref.watch(alertsProvider);
    final touristsAsync = ref.watch(touristsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tactical Map')),
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
              // Frosted glass legend
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tactical Legend', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white, letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _legendItem('🐯 Tiger', const Color(0xFFFF6F00)),
                          _legendItem('🐘 Elephant', const Color(0xFF00D2FF)),
                          _legendItem('🦁 Lion', const Color(0xFFEF4444)),
                        ],
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

  Widget _legendItem(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4)],
          ),
        ),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════
// 4. RANGER MONITOR TAB
// ═══════════════════════════════════════════════════
class _RangerMonitorTab extends ConsumerWidget {
  const _RangerMonitorTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final camerasAsync = ref.watch(camerasProvider);
    final detReportAsync = ref.watch(reportsProvider('detections'));
    final incReportAsync = ref.watch(reportsProvider('incidents'));

    return Scaffold(
      appBar: AppBar(title: const Text('Monitor & Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Icon(Icons.videocam_rounded, size: 20, color: AppTheme.rangerBlue),
              const SizedBox(width: 8),
              const Text('Camera Network', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          camerasAsync.when(
            data: (cameras) => Column(
              children: cameras.map((c) {
                final isOnline = c['status'] == 'online';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.elevatedShadow,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isOnline ? AppTheme.safeGreen : Colors.grey).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.videocam_rounded, color: isOnline ? AppTheme.safeGreen : Colors.grey, size: 22),
                    ),
                    title: Text('${c['camera_id']} - ${c['name']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text('Type: ${c['type']} • ${c['status'].toString().toUpperCase()}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    trailing: Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        color: isOnline ? AppTheme.safeGreen : Colors.grey,
                        shape: BoxShape.circle,
                        boxShadow: isOnline ? [BoxShadow(color: AppTheme.safeGreen.withValues(alpha: 0.4), blurRadius: 6)] : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Unable to load camera data.'),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Icon(Icons.analytics_rounded, size: 20, color: AppTheme.forestGreen),
              const SizedBox(width: 8),
              const Text('Incident Summary (7d)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          incReportAsync.when(
            data: (inc) => Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.elevatedShadow,
              ),
              child: Column(
                children: [
                  _reportRow('Total Alerts', '${inc['total_alerts'] ?? 0}'),
                  _reportRow('Active Danger Zones', '${inc['active_danger_zones'] ?? 0}'),
                  _reportRow('Closed Alerts', '${inc['closed'] ?? 0}'),
                  _reportRow('Rejected Alerts', '${inc['rejected'] ?? 0}'),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Icon(Icons.pets_rounded, size: 20, color: AppTheme.approachingAmber),
              const SizedBox(width: 8),
              const Text('Wildlife Breakdown', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          detReportAsync.when(
            data: (det) {
              final list = det['by_animal'] as List<dynamic>? ?? [];
              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.elevatedShadow,
                ),
                child: Column(
                  children: list.map((a) {
                    final animalName = AppConstants.animalNames[a['animal_type']] ?? a['animal_type'];
                    final avgConf = (((a['avg_confidence'] ?? 0) as num) * 100).toStringAsFixed(0);
                    return _reportRow(
                      '${AppConstants.animalEmojis[a['animal_type']] ?? '🐾'} $animalName',
                      '${a['count']} detections (Avg: $avgConf%)',
                    );
                  }).toList(),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// 5. RANGER PROFILE TAB
// ═══════════════════════════════════════════════════
class _RangerProfileTab extends StatelessWidget {
  final AuthState auth;
  final VoidCallback onLogout;

  const _RangerProfileTab({required this.auth, required this.onLogout});

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
              gradient: AppTheme.rangerGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                const Text('Ranger Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
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
                      (auth.user?['full_name'] ?? 'R').substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  auth.user?['full_name'] ?? 'Ranger Officer',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Badge: ${auth.user?['badge_number'] ?? "MWR-001"} • RANGER',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 4),
                Text(
                  auth.user?['email'] ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

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
                  _menuItem(Icons.security_rounded, 'Security Protocols', () {}),
                  Divider(height: 1, indent: 56, color: Colors.grey.shade100),
                  _menuItem(Icons.tune_rounded, 'Detection Threshold', () {}),
                  Divider(height: 1, indent: 56, color: Colors.grey.shade100),
                  _menuItem(Icons.info_outline_rounded, 'ForestGuard v1.0.0', () {}),
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
              child: _menuItem(Icons.logout_rounded, 'Sign Out', onLogout, isDestructive: true),
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
                  color: (isDestructive ? AppTheme.dangerRed : AppTheme.rangerBlue).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
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
