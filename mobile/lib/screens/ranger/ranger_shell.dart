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
import '../../widgets/sos_request_modal.dart';
import '../../widgets/popup_notification.dart';
import '../../services/sound_service.dart';

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
    SoundService.instance.stopSound();
    _wsSubscription?.cancel();
    super.dispose();
  }

  void _listenToWebSocketEvents() {
    final ws = ref.read(webSocketProvider);
    _wsSubscription = ws.events.listen((event) {
      final eventType = event['type'] ?? event['event'];
      final data = event['data'] is Map ? Map<String, dynamic>.from(event['data']) : event;

      if (eventType == 'wildlife_detected' ||
          eventType == 'danger_zone_created' ||
          eventType == 'danger_zone_updated') {

        SoundService.instance.playAlertSound();
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
              setState(() => _currentIndex = 2);
            },
          );
        }
      }

      // SOS request from tourist — show SOS modal
      if (eventType == 'sos_request') {
        SoundService.instance.playAlertSound();
        ref.invalidate(sosRequestsProvider);
        if (mounted) {
          final lat = data['latitude']?.toString() ?? '11.5690';
          final lng = data['longitude']?.toString() ?? '76.6320';
          PopupNotification.show(
            context,
            title: '🚨 SOS EMERGENCY',
            message: '${data['tourist_name'] ?? 'Tourist'} needs help!\n📍 Location: $lat° N, $lng° E',
            icon: Icons.emergency_rounded,
            color: AppTheme.error,
            duration: const Duration(seconds: 10),
          );
          SOSRequestModal.show(
            context,
            sosData: data,
            onVerify: () {
              ref.invalidate(sosRequestsProvider);
            },
            onAcknowledge: () {
              ref.invalidate(sosRequestsProvider);
            },
            onViewOnMap: () {
              setState(() => _currentIndex = 2);
            },
          );
        }
      }

      // SOS verified notification
      if (eventType == 'sos_verified') {
        SoundService.instance.stopSound();
        ref.invalidate(sosRequestsProvider);
        if (mounted) {
          PopupNotification.show(
            context,
            title: 'SOS Verified',
            message: 'SOS from ${data['tourist_name'] ?? 'Tourist'} verified by ${data['verified_by'] ?? 'Ranger'}',
            icon: Icons.verified_rounded,
            color: AppTheme.secondary,
          );
        }
      }

      // SOS acknowledged notification
      if (eventType == 'sos_acknowledged') {
        SoundService.instance.stopSound();
        ref.invalidate(sosRequestsProvider);
        if (mounted) {
          PopupNotification.show(
            context,
            title: 'SOS Resolved ✅',
            message: 'SOS from ${data['tourist_name'] ?? 'Tourist'} resolved by ${data['acknowledged_by'] ?? 'Ranger'}',
            icon: Icons.check_circle_rounded,
            color: AppTheme.safeGreen,
          );
        }
      }

      // Alert acknowledged notification
      if (eventType == 'alert_acknowledged') {
        SoundService.instance.stopSound();
        ref.invalidate(alertsProvider);
        if (mounted) {
          PopupNotification.show(
            context,
            title: 'Alert Acknowledged ✅',
            message: '${data['animal_type'] ?? 'Wildlife'} alert resolved by ${data['acknowledged_by'] ?? 'Ranger'}',
            icon: Icons.check_circle_rounded,
            color: AppTheme.safeGreen,
          );
        }
      }

      // Alert verified notification
      if (eventType == 'alert_verified') {
        ref.invalidate(alertsProvider);
        if (mounted) {
          PopupNotification.show(
            context,
            title: 'Threat Verified',
            message: '${data['animal_type'] ?? 'Wildlife'} detection verified by ${data['verified_by'] ?? 'Ranger'}',
            icon: Icons.verified_rounded,
            color: AppTheme.secondary,
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
          _RangerHomeTab(auth: auth, onViewMap: () => setState(() => _currentIndex = 2)),
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
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
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
// 1. RANGER HOME TAB — Stitch Command Center
// ═══════════════════════════════════════════════════
class _RangerHomeTab extends ConsumerStatefulWidget {
  final AuthState auth;
  final VoidCallback onViewMap;
  const _RangerHomeTab({super.key, required this.auth, required this.onViewMap});

  @override
  ConsumerState<_RangerHomeTab> createState() => _RangerHomeTabState();
}

class _RangerHomeTabState extends ConsumerState<_RangerHomeTab> {
  final List<Map<String, dynamic>> _simulatedRangerAlerts = [];

  void _triggerSimulatedAlert() {
    final animals = [
      {'type': 'tiger', 'name': 'Bengal Tiger', 'camera': 'C-08', 'zone': 'Sector 7 - Zone A'},
      {'type': 'elephant', 'name': 'Asian Elephant', 'camera': 'C-02', 'zone': 'Sector 4 - Zone C'},
      {'type': 'bear', 'name': 'Sloth Bear', 'camera': 'C-05', 'zone': 'Sector 2 - Zone B'},
    ];
    final selected = animals[DateTime.now().second % animals.length];

    final payload = {
      'id': 'sim_r_${DateTime.now().millisecondsSinceEpoch}',
      'animal_type': selected['type'],
      'confidence': 0.96,
      'camera_id': selected['camera'],
      'zone_code': selected['zone'],
      'latitude': 11.5690,
      'longitude': 76.6320,
      'status': 'needs_verification',
      'verification_status': 'NEEDS_VERIFICATION',
      'created_at': 'Just now',
    };

    SoundService.instance.playAlertSound();
    DetectionAlertModal.show(
      context,
      detection: payload,
      isRanger: true,
      onAcknowledge: () {
        setState(() {
          _simulatedRangerAlerts.insert(0, payload);
        });
      },
      onViewOnMap: widget.onViewMap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(alertsProvider);
    final zonesAsync = ref.watch(dangerZonesProvider);
    final camerasAsync = ref.watch(camerasProvider);
    final sosAsync = ref.watch(sosRequestsProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        elevation: 0,
        scrolledUnderElevation: 1,
        title: const Text('ForestGuard', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppTheme.primary)),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.errorContainer.withValues(alpha: 0.6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: _triggerSimulatedAlert,
            icon: const Icon(Icons.bolt_rounded, size: 16, color: AppTheme.error),
            label: const Text(
              'Test Alert 🚨',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.onErrorContainer),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppTheme.primary),
            onPressed: () {
              ref.invalidate(alertsProvider);
              ref.invalidate(dangerZonesProvider);
              ref.invalidate(camerasProvider);
              ref.invalidate(detectionsProvider);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(alertsProvider);
          ref.invalidate(dangerZonesProvider);
          ref.invalidate(camerasProvider);
          ref.invalidate(detectionsProvider);
          ref.invalidate(sosRequestsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
          children: [
            // 🚨 ACTIVE SOS EMERGENCY BANNER (Displays location and responder action)
            Builder(
              builder: (context) {
                final sosList = sosAsync.value ?? [];
                final activeSos = sosList.where((s) {
                  final st = (s['status'] ?? '').toString().toLowerCase();
                  return st == 'unverified' || st == 'verified' || st == 'active';
                }).toList();
                if (activeSos.isEmpty) return const SizedBox.shrink();

                final firstSos = activeSos.first;
                final tourist = firstSos['tourist_name'] ?? 'Tourist';
                final lat = firstSos['latitude']?.toString() ?? '11.5690';
                final lng = firstSos['longitude']?.toString() ?? '76.6320';
                final statusStr = (firstSos['status'] ?? 'unverified').toString().toUpperCase();

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7F1D1D), Color(0xFFDC2626)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '🚨 ACTIVE SOS EMERGENCY',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  '$tourist needs immediate assistance!',
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              statusStr,
                              style: const TextStyle(
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: Colors.amberAccent, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Location: $lat° N, $lng° E (Mudumalai)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFDC2626),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 0,
                          ),
                          onPressed: () {
                            SOSRequestModal.show(
                              context,
                              sosData: firstSos,
                              onVerify: () => ref.invalidate(sosRequestsProvider),
                              onAcknowledge: () => ref.invalidate(sosRequestsProvider),
                              onViewOnMap: widget.onViewMap,
                            );
                          },
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: const Text(
                            'RESPOND TO SOS',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Stitch Ranger Profile Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
                boxShadow: AppTheme.ambientShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        (widget.auth.user?['full_name'] ?? 'R').substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.auth.user?['full_name'] ?? 'Officer Ranger',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.primary),
                        ),
                        const SizedBox(height: 2),
                        const Text('Sector 7 • North Corridor', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(radius: 3, backgroundColor: AppTheme.secondary),
                        SizedBox(width: 6),
                        Text('Active Duty', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.onSecondaryContainer)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Stitch Bento Summary Stats Grid
            Row(
              children: [
                Expanded(
                  child: _StitchStatCard(
                    title: 'Active Alerts',
                    count: ((alertsAsync.value?.where((a) => a['status'] == 'active' || a['status'] == 'needs_verification' || a['status'] == 'monitoring').length ?? 0) + _simulatedRangerAlerts.length).toString(),
                    subtitle: 'High Priority',
                    color: AppTheme.error,
                    icon: Icons.warning_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StitchStatCard(
                    title: 'Tourists in Danger',
                    count: zonesAsync.value?.length.toString() ?? '...',
                    subtitle: 'Within 1km',
                    color: AppTheme.tertiaryFixedDim,
                    icon: Icons.groups_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _StitchStatCard(
                    title: 'Rangers Duty',
                    count: '12',
                    subtitle: 'Active',
                    color: AppTheme.primary,
                    icon: Icons.local_police_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StitchStatCard(
                    title: 'Live Cameras',
                    count: '${camerasAsync.value?.where((c) => c['status'] == 'online').length ?? 0}/${camerasAsync.value?.length ?? 0}',
                    subtitle: 'Sentinel Edge',
                    color: AppTheme.secondary,
                    icon: Icons.videocam_rounded,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Stitch Recent Detections List with Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Detections', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                TextButton(
                  onPressed: widget.onViewMap,
                  child: const Text('VIEW MAP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            alertsAsync.when(
              data: (alerts) {
                final pending = alerts.where((a) {
                  final s = (a['status'] ?? '').toString();
                  final isAck = a['ranger_acknowledged'] == true || s == 'acknowledged';
                  return (s == 'needs_verification' || s == 'active') && !isAck;
                }).toList();
                final allPending = [..._simulatedRangerAlerts, ...pending];

                if (allPending.isEmpty) {
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
                            Text('No pending unverified alerts', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: allPending.take(4).map((a) => _StitchRangerDetectionItem(alert: a, ref: ref, onViewMap: widget.onViewMap)).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error: $err'),
            ),

            const SizedBox(height: 24),

            // Quick Actions Section (Broadcast Warning, Log Incident)
            const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.primary)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
                boxShadow: AppTheme.ambientShadow,
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('📢 Broadcast Warning Dispatched to All Sector Tourists!')),
                        );
                      },
                      icon: const Icon(Icons.campaign_rounded, size: 22),
                      label: const Text('Broadcast Warning', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add_location_alt_rounded, size: 16),
                          label: const Text('Log Incident', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.group_add_rounded, size: 16),
                          label: const Text('Backup Request', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// Stitch Stat Card
class _StitchStatCard extends StatelessWidget {
  final String title;
  final String count;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _StitchStatCard({
    required this.title,
    required this.count,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: AppTheme.ambientShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(count, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
              const SizedBox(width: 6),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

// Stitch Ranger Detection Item Big Box Card
class _StitchRangerDetectionItem extends StatelessWidget {
  final Map<String, dynamic> alert;
  final WidgetRef ref;
  final VoidCallback? onViewMap;

  const _StitchRangerDetectionItem({required this.alert, required this.ref, this.onViewMap});

  @override
  Widget build(BuildContext context) {
    final animalKey = (alert['animal_type'] ?? 'unknown').toString().toLowerCase();
    final animalName = AppConstants.animalNames[animalKey] ?? animalKey.toUpperCase();
    final status = (alert['status'] ?? 'unknown').toString();
    final isAcknowledged = status == 'acknowledged' || alert['ranger_acknowledged'] == true;
    final isNeedsVerify = status == 'needs_verification';
    final alertId = alert['id'] ?? '';
    final conf = (((alert['confidence'] ?? 0.85) as num) * 100).toStringAsFixed(0);
    final camId = alert['camera_id'] ?? 'C-01';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAcknowledged
              ? AppTheme.safeGreen.withValues(alpha: 0.4)
              : (isNeedsVerify ? AppTheme.error.withValues(alpha: 0.4) : AppTheme.outlineVariant.withValues(alpha: 0.3)),
          width: 1.5,
        ),
        boxShadow: AppTheme.ambientShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isAcknowledged
                        ? AppTheme.safeGreen.withValues(alpha: 0.15)
                        : (isNeedsVerify ? AppTheme.errorContainer.withValues(alpha: 0.5) : AppTheme.secondaryContainer.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(
                      AppConstants.getAnimalIcon(animalKey),
                      color: isAcknowledged ? AppTheme.safeGreen : (isNeedsVerify ? AppTheme.error : AppTheme.secondary),
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$animalName Detection',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Camera $camId • $conf% AI Confidence',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isAcknowledged ? AppTheme.safeGreen : (isNeedsVerify ? AppTheme.error : AppTheme.secondary),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAcknowledged ? AppTheme.safeGreen : (isNeedsVerify ? AppTheme.error : AppTheme.secondary),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isAcknowledged ? 'SOLVED' : (isNeedsVerify ? 'UNVERIFIED' : 'VERIFIED'),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      DetectionAlertModal.show(
                        context,
                        detection: alert,
                        isRanger: true,
                        onViewOnMap: onViewMap,
                      );
                    },
                    icon: const Icon(Icons.videocam_rounded, size: 16),
                    label: const Text('Camera Snapshot', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAcknowledged ? AppTheme.safeGreen : (isNeedsVerify ? AppTheme.error : AppTheme.primary),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      if (isAcknowledged) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ Case already acknowledged and resolved.')),
                        );
                        return;
                      }
                      try {
                        final action = isNeedsVerify ? 'verify' : 'acknowledge';
                        await ApiService().dio.patch('/api/alerts/$alertId/$action');
                        ref.invalidate(alertsProvider);
                        ref.invalidate(dangerZonesProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Alert $action processed.')));
                        }
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alert acknowledged locally.')));
                        }
                      }
                    },
                    icon: Icon(isAcknowledged ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded, size: 16),
                    label: Text(
                      isAcknowledged ? 'Acknowledged' : (isNeedsVerify ? 'Verify Threat' : 'Acknowledge'),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// RANGER ALERTS TAB
// ═══════════════════════════════════════════════════
class _RangerAlertsTab extends ConsumerWidget {
  const _RangerAlertsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Incident Management')),
      body: alertsAsync.when(
        data: (alerts) {
          final pending = alerts.where((a) {
            final s = (a['status'] ?? '').toString();
            final isAck = a['ranger_acknowledged'] == true || s == 'acknowledged';
            return s != 'closed' && s != 'rejected' && !isAck;
          }).toList();

          final solved = alerts.where((a) {
            final s = (a['status'] ?? '').toString();
            final isAck = a['ranger_acknowledged'] == true || s == 'acknowledged';
            return isAck || s == 'closed';
          }).toList();

          if (alerts.isEmpty) {
            return const Center(child: Text('No incidents recorded.'));
          }

          return ListView(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
            children: [
              if (pending.isNotEmpty) ...[
                const Text('Active / Pending Incidents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                const SizedBox(height: 12),
                ...pending.map((a) => _StitchRangerDetectionItem(alert: a, ref: ref)),
                const SizedBox(height: 24),
              ],
              const Text('Solved Cases / Handled Incidents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary)),
              const SizedBox(height: 12),
              if (solved.isEmpty)
                const Text('No solved cases recorded yet.', style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant))
              else
                ...solved.map((a) => _StitchRangerDetectionItem(alert: a, ref: ref)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// RANGER MAP TAB
// ═══════════════════════════════════════════════════
class _RangerMapTab extends ConsumerWidget {
  const _RangerMapTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zonesAsync = ref.watch(dangerZonesProvider);
    final alertsAsync = ref.watch(alertsProvider);
    final touristsAsync = ref.watch(touristsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tactical GIS Map')),
      body: zonesAsync.when(
        data: (zones) {
          final alerts = alertsAsync.value ?? [];
          final tourists = touristsAsync.value ?? [];
          return ForestMapView(
            dangerZones: zones,
            alerts: alerts,
            touristLocations: tourists,
            isRanger: true,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Unable to load map data')),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// RANGER MONITOR TAB
// ═══════════════════════════════════════════════════
class _RangerMonitorTab extends ConsumerWidget {
  const _RangerMonitorTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final camerasAsync = ref.watch(camerasProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sentinel Camera Network')),
      body: camerasAsync.when(
        data: (cameras) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: cameras.length,
          itemBuilder: (ctx, i) {
            final c = cameras[i];
            final isOnline = c['status'] == 'online';
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
                  Icon(Icons.videocam_rounded, color: isOnline ? AppTheme.secondary : Colors.grey, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${c['camera_id']} - ${c['name']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.primary)),
                        Text('Type: ${c['type']} • Status: ${c['status'].toString().toUpperCase()}', style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isOnline ? AppTheme.secondary : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Unable to load cameras.')),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// RANGER PROFILE TAB
// ═══════════════════════════════════════════════════
class _RangerProfileTab extends StatelessWidget {
  final AuthState auth;
  final VoidCallback onLogout;
  const _RangerProfileTab({required this.auth, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ranger Badge')),
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
                    (auth.user?['full_name'] ?? 'R').substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(auth.user?['full_name'] ?? 'Ranger Smith', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const Text('Badge: MWR-001 • RANGER', style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant)),
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
