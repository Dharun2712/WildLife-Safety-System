import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../config/constants.dart';
import '../../services/api_service.dart';
import '../../widgets/forest_map_view.dart';
import '../../widgets/detection_alert_modal.dart';
import '../../widgets/sos_active_dialog.dart';
import '../../widgets/popup_notification.dart';
import '../../services/sound_service.dart';

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
          eventType == 'tourist_warning' ||
          eventType == 'danger_zone_updated') {

        SoundService.instance.playAlertSound();
        ref.invalidate(dangerZonesProvider);
        ref.invalidate(alertsProvider);
        ref.invalidate(safetyStatusProvider);

        if (mounted) {
          PopupNotification.show(
            context,
            title: '⚠️ Wildlife Detected',
            message: '${data['animal_type'] ?? 'Wildlife'} spotted near your area!',
            icon: Icons.warning_rounded,
            color: AppTheme.error,
          );
          DetectionAlertModal.show(
            context,
            detection: data,
            isRanger: false,
            onViewOnMap: () {
              setState(() => _currentIndex = 1);
            },
            onTriggerSOS: () => _triggerSOS(),
          );
        }
      }

      // SOS verified — ranger verified tourist's SOS
      if (eventType == 'sos_verified') {
        SoundService.instance.stopSound();
        ref.invalidate(sosRequestsProvider);
        if (mounted) {
          PopupNotification.show(
            context,
            title: 'SOS Verified ✅',
            message: 'Ranger ${data['verified_by'] ?? ''} has verified your SOS and is responding!',
            icon: Icons.verified_rounded,
            color: AppTheme.secondary,
            duration: const Duration(seconds: 6),
          );
        }
      }

      // SOS acknowledged — ranger resolved tourist's SOS
      if (eventType == 'sos_acknowledged') {
        SoundService.instance.stopSound();
        ref.invalidate(sosRequestsProvider);
        if (mounted) {
          PopupNotification.show(
            context,
            title: 'SOS Resolved ✅',
            message: 'Ranger ${data['acknowledged_by'] ?? ''} has resolved your emergency. You are safe!',
            icon: Icons.check_circle_rounded,
            color: AppTheme.safeGreen,
            duration: const Duration(seconds: 6),
          );
        }
      }

      // Alert acknowledged — ranger resolved wildlife alert
      if (eventType == 'alert_acknowledged') {
        SoundService.instance.stopSound();
        ref.invalidate(alertsProvider);
        if (mounted) {
          PopupNotification.show(
            context,
            title: 'Threat Resolved ✅',
            message: 'Ranger ${data['acknowledged_by'] ?? ''} has acknowledged the ${data['animal_type'] ?? 'wildlife'} alert.',
            icon: Icons.check_circle_rounded,
            color: AppTheme.safeGreen,
          );
        }
      }

      // Alert verified — ranger verified wildlife detection
      if (eventType == 'alert_verified') {
        ref.invalidate(alertsProvider);
        if (mounted) {
          PopupNotification.show(
            context,
            title: 'Threat Verified',
            message: 'Ranger ${data['verified_by'] ?? ''} confirmed the ${data['animal_type'] ?? 'wildlife'} detection.',
            icon: Icons.verified_rounded,
            color: AppTheme.secondary,
          );
        }
      }

      // Alert closed notification
      if (eventType == 'alert_closed_notification') {
        SoundService.instance.stopSound();
        ref.invalidate(alertsProvider);
        ref.invalidate(safetyStatusProvider);
        if (mounted) {
          PopupNotification.show(
            context,
            title: 'Alert Closed',
            message: data['message'] ?? 'Wildlife alert has been closed by ranger.',
            icon: Icons.shield_rounded,
            color: AppTheme.safeGreen,
          );
        }
      }
    });
  }

  void _triggerSOS() async {
    SoundService.instance.playAlertSound();
    try {
      await ApiService().dio.post('/api/sos', data: {
        'latitude': 11.5690,
        'longitude': 76.6320,
        'message': 'Emergency! I need immediate assistance!',
      });
    } catch (_) {}
    if (mounted) {
      SOSActiveDialog.show(context);
    }
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
              onPressed: () => _triggerSOS(),
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
class _TouristHomeTab extends ConsumerStatefulWidget {
  final AuthState auth;
  final VoidCallback onViewMap;
  const _TouristHomeTab({super.key, required this.auth, required this.onViewMap});

  @override
  ConsumerState<_TouristHomeTab> createState() => _TouristHomeTabState();
}

class _TouristHomeTabState extends ConsumerState<_TouristHomeTab> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _simulatedActiveAlerts = [];

  void _triggerSimulatedAlert() {
    final animals = [
      {'type': 'tiger', 'name': 'Bengal Tiger', 'emoji': '🐅', 'camera': 'C-04', 'zone': 'Sector 4 - Zone A'},
      {'type': 'elephant', 'name': 'Asian Elephant', 'emoji': '🐘', 'camera': 'C-01', 'zone': 'Sector 2 - Zone B'},
      {'type': 'bear', 'name': 'Sloth Bear', 'emoji': '🐻', 'camera': 'C-07', 'zone': 'Sector 4 - Zone D'},
      {'type': 'leopard', 'name': 'Indian Leopard', 'emoji': '🐆', 'camera': 'C-03', 'zone': 'Sector 1 - Zone C'},
    ];
    final selected = animals[DateTime.now().second % animals.length];

    final payload = {
      'id': 'sim_${DateTime.now().millisecondsSinceEpoch}',
      'animal_type': selected['type'],
      'confidence': 0.95,
      'camera_id': selected['camera'],
      'zone_code': selected['zone'],
      'latitude': 11.5690,
      'longitude': 76.6320,
      'status': 'active',
      'verification_status': 'ACTIVE',
      'created_at': 'Just now',
    };

    SoundService.instance.playAlertSound();
    DetectionAlertModal.show(
      context,
      detection: payload,
      isRanger: false,
      onAcknowledge: () {
        setState(() {
          _simulatedActiveAlerts.insert(0, payload);
        });
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
          );
        }
      },
      onViewOnMap: widget.onViewMap,
      onTriggerSOS: () async {
        try {
          await ApiService().dio.post('/api/sos', data: {
            'latitude': 11.5690,
            'longitude': 76.6320,
            'message': 'Emergency! I need immediate assistance!',
          });
        } catch (_) {}
        if (mounted) SOSActiveDialog.show(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final safetyAsync = ref.watch(safetyStatusProvider);
    final alertsAsync = ref.watch(alertsProvider);
    final zonesAsync = ref.watch(dangerZonesProvider);
    final detectionsAsync = ref.watch(detectionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: AppTheme.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Center(
                child: Text(
                  (widget.auth.user?['full_name'] ?? 'T').substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text('ForestGuard', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppTheme.primary)),
          ],
        ),
        actions: [
          // Interactive Simulated Detection Alert Button
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
              ref.invalidate(safetyStatusProvider);
              ref.invalidate(alertsProvider);
              ref.invalidate(dangerZonesProvider);
            },
          ),
          const SizedBox(width: 4),
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
          controller: _scrollController,
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 140),
          children: [
            // Stitch Safety Status Banner (Danger when any alerts active, Safety Status: All Clear when none)
            Builder(
              builder: (context) {
                final alerts = alertsAsync.value ?? [];
                final backendActive = alerts.where((a) {
                  final s = (a['status'] ?? '').toString().toLowerCase();
                  final isAck = a['ranger_acknowledged'] == true || s == 'acknowledged' || s == 'closed' || s == 'solved' || s == 'rejected';
                  return !isAck;
                }).toList();

                final simulatedActive = _simulatedActiveAlerts.where((a) {
                  final s = (a['status'] ?? '').toString().toLowerCase();
                  final isAck = a['ranger_acknowledged'] == true || s == 'acknowledged' || s == 'closed' || s == 'solved';
                  return !isAck;
                }).toList();

                final allActiveAlerts = [...simulatedActive, ...backendActive];
                final hasActive = allActiveAlerts.isNotEmpty;

                Map<String, dynamic> bannerStatus;
                if (hasActive) {
                  final first = allActiveAlerts.first;
                  final animalKey = (first['animal_type'] ?? 'wildlife').toString().toLowerCase();
                  final animalName = AppConstants.animalNames[animalKey] ?? animalKey.toUpperCase();
                  bannerStatus = {
                    'status': 'danger',
                    'message': 'WARNING: Active $animalName threat detected in your area!',
                  };
                } else {
                  final s = safetyAsync.value?['status']?.toString().toLowerCase();
                  if (s == 'inside' || s == 'danger') {
                    bannerStatus = {
                      'status': 'danger',
                      'message': safetyAsync.value?['message'] ?? 'WARNING: You are inside an active danger zone!',
                    };
                  } else {
                    bannerStatus = {
                      'status': 'safe',
                      'message': 'Conditions are stable and all clear. Enjoy your visit.',
                    };
                  }
                }
                return _StitchSafetyBanner(status: bannerStatus);
              },
            ),
            const SizedBox(height: 16),

            // Stitch 2-Column Widgets Grid (Weather + Trail)
            Row(
              children: [
                Expanded(child: _StitchWeatherWidget()),
                const SizedBox(width: 12),
                Expanded(child: _StitchTrailWidget()),
              ],
            ),
            const SizedBox(height: 20),

            // Stitch Nearby Activity Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Nearby Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                TextButton.icon(
                  onPressed: widget.onViewMap,
                  icon: const Text('Expand Map', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.secondary)),
                  label: const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.secondary),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Map Preview Snippet
            _StitchMapPreviewCard(onViewMap: widget.onViewMap, zonesAsync: zonesAsync),
            const SizedBox(height: 22),

            // ═══════════════════════════════════════════════════
            // RECENT DETECTIONS — FEATURED BIG BOX CAROUSEL
            // ═══════════════════════════════════════════════════
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.visibility_rounded, size: 20, color: AppTheme.primary),
                    SizedBox(width: 8),
                    Text('Recent Detections', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppTheme.primaryContainer.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Text('AI Live Sentinel', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            detectionsAsync.when(
              data: (dets) {
                if (dets.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
                    ),
                    child: const Text('No recent wildlife sightings recorded.'),
                  );
                }
                return SizedBox(
                  height: 175,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: dets.length,
                    itemBuilder: (ctx, i) {
                      final d = dets[i];
                      final animalKey = (d['animal_type'] ?? 'unknown').toString().toLowerCase();
                      final animalName = AppConstants.animalNames[animalKey] ?? animalKey.toUpperCase();
                      final conf = (((d['confidence'] ?? 0.85) as num) * 100).toStringAsFixed(0);
                      final cam = d['camera_id'] ?? 'C-01';

                      return InkWell(
                        onTap: () {
                          DetectionAlertModal.show(
                            context,
                            detection: d,
                            isRanger: false,
                            onViewOnMap: widget.onViewMap,
                            onTriggerSOS: () async {
                              try {
                                await ApiService().dio.post('/api/sos', data: {
                                  'latitude': 11.5690,
                                  'longitude': 76.6320,
                                  'message': 'Emergency! I need immediate assistance!',
                                });
                              } catch (_) {}
                              if (context.mounted) SOSActiveDialog.show(context);
                            },
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 240,
                          margin: const EdgeInsets.only(right: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF012D1D), Color(0xFF134E39)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.2),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF012D1D).withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Animal Icon Badge Box
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                    ),
                                    child: Center(child: Icon(AppConstants.getAnimalIcon(animalKey), color: Colors.white, size: 26)),
                                  ),
                                  const Spacer(),
                                  // Confidence Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF22C55E).withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.4)),
                                    ),
                                    child: Text(
                                      '$conf% Conf',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF4ADE80)),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                animalName,
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.videocam_outlined, color: Colors.white70, size: 14),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Camera $cam • Mudumalai Sector 4',
                                      style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Tap to inspect', style: TextStyle(fontSize: 10, color: Color(0xFF4ADE80), fontWeight: FontWeight.w700)),
                                  Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF4ADE80)),
                                ],
                              ),
                            ],
                          ),
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

            // ═══════════════════════════════════════════════════
            // ACTIVE ALERTS & SOLVED CASES
            // ═══════════════════════════════════════════════════
            alertsAsync.when(
              data: (alerts) {
                final backendActive = alerts.where((a) {
                  final s = (a['status'] ?? '').toString();
                  final isAck = a['ranger_acknowledged'] == true || s == 'acknowledged';
                  return s != 'closed' && s != 'rejected' && !isAck;
                }).toList();

                final simulatedActive = _simulatedActiveAlerts.where((a) {
                  final s = (a['status'] ?? '').toString();
                  final isAck = a['ranger_acknowledged'] == true || s == 'acknowledged';
                  return !isAck;
                }).toList();

                final allActiveAlerts = [...simulatedActive, ...backendActive];

                final backendSolved = alerts.where((a) {
                  final s = (a['status'] ?? '').toString();
                  final isAck = a['ranger_acknowledged'] == true || s == 'acknowledged';
                  return isAck || s == 'closed';
                }).toList();

                final simulatedSolved = _simulatedActiveAlerts.where((a) {
                  final s = (a['status'] ?? '').toString();
                  final isAck = a['ranger_acknowledged'] == true || s == 'acknowledged';
                  return isAck;
                }).toList();

                final allSolvedCases = [...simulatedSolved, ...backendSolved];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- ACTIVE ALERTS SECTION ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 22, color: AppTheme.error),
                            SizedBox(width: 8),
                            Text('Active Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                          ],
                        ),
                        if (allActiveAlerts.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppTheme.error, borderRadius: BorderRadius.circular(12)),
                            child: Text(
                              '${allActiveAlerts.length} THREATS',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (allActiveAlerts.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
                          boxShadow: AppTheme.ambientShadow,
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: AppTheme.safeGreen, size: 32),
                            SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('All Sectors Normal', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.primary)),
                                SizedBox(height: 2),
                                Text('No active wildlife proximity threats detected.', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                              ],
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: allActiveAlerts.map((a) => _StitchAlertBigBoxCard(alert: a, onViewMap: widget.onViewMap)).toList(),
                      ),

                    const SizedBox(height: 24),

                    // --- SOLVED CASES SECTION ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.verified_rounded, size: 22, color: AppTheme.safeGreen),
                            SizedBox(width: 8),
                            Text('Solved Cases', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                          ],
                        ),
                        if (allSolvedCases.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppTheme.safeGreen, borderRadius: BorderRadius.circular(12)),
                            child: Text(
                              '${allSolvedCases.length} RESOLVED',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (allSolvedCases.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield_outlined, color: AppTheme.onSurfaceVariant, size: 22),
                            SizedBox(width: 12),
                            Text('No solved cases recorded yet.', style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant)),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: allSolvedCases.map((a) => _StitchSolvedCaseCard(alert: a, onViewMap: widget.onViewMap)).toList(),
                      ),
                  ],
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

// Stitch Verified Safety Banner Card
class _StitchSafetyBanner extends StatelessWidget {
  final Map<String, dynamic> status;
  const _StitchSafetyBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = (status['status'] as String?)?.toLowerCase() ?? 'safe';
    final isDanger = s == 'danger' || s == 'inside' || s == 'warning' || s == 'active';
    final isClear = !isDanger;
    final message = (status['message'] as String?) ??
        (isDanger ? 'Active wildlife threat detected near your sector.' : 'Conditions are stable and all clear. Enjoy your visit.');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isClear
            ? AppTheme.secondaryContainer.withValues(alpha: 0.4)
            : AppTheme.errorContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isClear ? AppTheme.secondary : AppTheme.error).withValues(alpha: 0.45),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (isClear ? AppTheme.secondary : AppTheme.error).withValues(alpha: 0.2),
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
                Row(
                  children: [
                    Text(
                      isClear ? 'Safety Status: All Clear' : 'Status: Danger',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isClear ? AppTheme.onSecondaryContainer : AppTheme.onErrorContainer,
                      ),
                    ),
                    if (isDanger) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.error,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'DANGER',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: (isClear ? AppTheme.onSecondaryContainer : AppTheme.onErrorContainer).withValues(alpha: 0.85),
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

// Stitch Active Alert Big Box Card
class _StitchAlertBigBoxCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  final VoidCallback? onViewMap;

  const _StitchAlertBigBoxCard({required this.alert, this.onViewMap});

  @override
  Widget build(BuildContext context) {
    final animalKey = (alert['animal_type'] ?? 'unknown').toString().toLowerCase();
    final animalName = AppConstants.animalNames[animalKey] ?? animalKey.toUpperCase();
    final zoneCode = alert['zone_code'] ?? alert['zone'] ?? 'Sector 4';
    final camId = alert['camera_id'] ?? 'C-01';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.error.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Vibrant Red Alert Indicator Strip
              Container(
                width: 6,
                color: AppTheme.error,
              ),

              // Main Card Content Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          // Animal Icon Badge Container
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppTheme.errorContainer.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
                            ),
                            child: Center(child: Icon(AppConstants.getAnimalIcon(animalKey), color: AppTheme.error, size: 26)),
                          ),
                          const SizedBox(width: 12),

                          // Title and Subtitle Column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$animalName Alert',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'AI VERIFIED • Camera $camId',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.error),
                                ),
                              ],
                            ),
                          ),

                          // Status Pill Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.error,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(color: AppTheme.error.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: const Text(
                              'ACTIVE THREAT',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Location & Telemetry Big Box Snippet
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: AppTheme.error, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Zone $zoneCode • 350m from current area',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Interactive Action Buttons Row
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primary,
                                side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                DetectionAlertModal.show(
                                  context,
                                  detection: alert,
                                  isRanger: false,
                                  onViewOnMap: onViewMap,
                                  onTriggerSOS: () async {
                                    try {
                                      await ApiService().dio.post('/api/sos', data: {
                                        'latitude': 11.5690,
                                        'longitude': 76.6320,
                                        'message': 'Emergency! I need immediate assistance!',
                                      });
                                    } catch (_) {}
                                    if (context.mounted) SOSActiveDialog.show(context);
                                  },
                                );
                              },
                              icon: const Icon(Icons.info_outline_rounded, size: 16),
                              label: const Text('View Alert', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              onPressed: onViewMap,
                              icon: const Icon(Icons.map_rounded, size: 16),
                              label: const Text('Threat Map', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Stitch Solved Case Card
class _StitchSolvedCaseCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  final VoidCallback? onViewMap;

  const _StitchSolvedCaseCard({required this.alert, this.onViewMap});

  @override
  Widget build(BuildContext context) {
    final animalKey = (alert['animal_type'] ?? 'unknown').toString().toLowerCase();
    final animalName = AppConstants.animalNames[animalKey] ?? animalKey.toUpperCase();
    final zoneCode = alert['zone_code'] ?? alert['zone'] ?? 'Sector 4';
    final ackBy = alert['acknowledged_by'] ?? alert['closed_by'] ?? 'Ranger Unit';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.safeGreen.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.safeGreen.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Vibrant Green Solved Indicator Strip
              Container(
                width: 6,
                color: AppTheme.safeGreen,
              ),

              // Main Card Content Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppTheme.safeGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.safeGreen.withValues(alpha: 0.3)),
                            ),
                            child: Center(child: Icon(AppConstants.getAnimalIcon(animalKey), color: AppTheme.safeGreen, size: 26)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$animalName Incident',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'ACKNOWLEDGED BY $ackBy',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.safeGreen),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.safeGreen,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(color: AppTheme.safeGreen.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'SOLVED CASE',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_user_rounded, color: AppTheme.safeGreen, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Zone $zoneCode • Threat handled & area monitored by Rangers',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary),
                              ),
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
          final activeAlerts = alerts.where((a) {
            final s = (a['status'] ?? '').toString();
            final isAck = a['ranger_acknowledged'] == true || s == 'acknowledged';
            return s != 'closed' && s != 'rejected' && !isAck;
          }).toList();

          final solvedCases = alerts.where((a) {
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
              if (activeAlerts.isNotEmpty) ...[
                const Text('Active Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                const SizedBox(height: 12),
                ...activeAlerts.map((a) => _StitchAlertBigBoxCard(alert: a)),
                const SizedBox(height: 24),
              ],
              const Text('Solved Cases', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary)),
              const SizedBox(height: 12),
              if (solvedCases.isEmpty)
                const Text('No solved cases recorded yet.', style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant))
              else
                ...solvedCases.map((a) => _StitchSolvedCaseCard(alert: a)),
            ],
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
