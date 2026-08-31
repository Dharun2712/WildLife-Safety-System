import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/forest_map_view.dart';
import '../../widgets/detection_alert_modal.dart';
import '../../widgets/sos_active_dialog.dart';
import '../camera/camera_monitoring_screen.dart';

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
          color: AppTheme.surfaceContainerLowest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: const Border(
            top: BorderSide(color: AppTheme.primary, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2D3436).withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.warning_amber_rounded), selectedIcon: Icon(Icons.warning_rounded), label: 'Alerts'),
            NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map_rounded), label: 'Map'),
            NavigationDestination(icon: Icon(Icons.visibility_outlined), selectedIcon: Icon(Icons.visibility_rounded), label: 'Monitor'),
            NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// 1. RANGER HOME TAB — Stitch Command Dashboard
// ═══════════════════════════════════════════════════
class _RangerHomeTab extends ConsumerWidget {
  final AuthState auth;
  final VoidCallback onViewMap;

  const _RangerHomeTab({required this.auth, required this.onViewMap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);
    final rangerName = auth.user?['full_name'] ?? 'Officer Miller';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: const Row(
          children: [
            Icon(Icons.shield_rounded, color: AppTheme.primary, size: 24),
            SizedBox(width: 8),
            Text('ForestGuard', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: AppTheme.primary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppTheme.primary),
            onPressed: () {
              ref.invalidate(alertsProvider);
              ref.invalidate(dangerZonesProvider);
              ref.invalidate(camerasProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(alertsProvider);
          ref.invalidate(dangerZonesProvider);
          ref.invalidate(camerasProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good Morning, $rangerName',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.primary, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: AppTheme.onSurfaceVariant),
                    SizedBox(width: 4),
                    Text('Assignment: ', style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant)),
                    Text('Demo Forest • All Zones', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Stitch 4-Card Stats Bento Grid
            Row(
              children: [
                Expanded(
                  child: _StitchStatBentoCard(
                    title: 'Active Alerts',
                    count: alertsAsync.value?.where((a) => a['status'] == 'active' || a['status'] == 'needs_verification').length.toString() ?? '3',
                    icon: Icons.campaign_rounded,
                    isDanger: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StitchStatBentoCard(
                    title: 'Pending',
                    count: '2',
                    icon: Icons.schedule_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StitchStatBentoCard(
                    title: 'Resolved',
                    count: '14',
                    icon: Icons.check_circle_rounded,
                    iconColor: AppTheme.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StitchStatBentoCard(
                    title: 'Tourists',
                    count: '12',
                    icon: Icons.groups_rounded,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Priority Action Required Title
            const Row(
              children: [
                Icon(Icons.warning_rounded, color: AppTheme.error, size: 22),
                SizedBox(width: 8),
                Text('Priority Action Required', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.onSurface)),
              ],
            ),

            const SizedBox(height: 12),

            // Large Critical Alert Card (Tiger Sighting Hero Card)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.error, width: 2),
                boxShadow: AppTheme.sosShadow,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Area
                  Stack(
                    children: [
                      Container(
                        height: 160,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage('https://images.unsplash.com/photo-1561731216-c3a4d99437d5?auto=format&fit=crop&w=800&q=80'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: AppTheme.error, borderRadius: BorderRadius.circular(20)),
                              child: const Row(
                                children: [
                                  Icon(Icons.pets_rounded, color: Colors.white, size: 12),
                                  SizedBox(width: 4),
                                  Text('Tiger', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('Zone A', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified_rounded, color: AppTheme.secondaryContainer, size: 14),
                              SizedBox(width: 4),
                              Text('94% Confidence', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Apex Predator Detected', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: AppTheme.errorContainer, borderRadius: BorderRadius.circular(6)),
                              child: const Text('5m ago', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.error)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Motion sensor triggered. Subject confirmed via ML model. Tourist groups in adjacent Zone B require immediate rerouting.',
                          style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  DetectionAlertModal.show(
                                    context,
                                    detection: {'animal_type': 'tiger', 'confidence': 0.94, 'status': 'active'},
                                    isRanger: true,
                                  );
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                                child: const Text('VIEW ALERT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: onViewMap,
                                icon: const Icon(Icons.map_rounded, size: 16),
                                label: const Text('VIEW MAP', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // RANGER COMMAND Reports & Analytics Section (Image 4)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
                boxShadow: AppTheme.ambientShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('RANGER COMMAND', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.secondary, letterSpacing: 1)),
                          Text('Reports & Analytics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.onSurface)),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('Export', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Top Metrics Cards Row (Image 4)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppTheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Detections', style: TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant)),
                              SizedBox(height: 4),
                              Text('1,248', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.onSurface)),
                              Text('+12% vs last month', style: TextStyle(fontSize: 9, color: AppTheme.secondary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppTheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Active Alerts', style: TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant)),
                              SizedBox(height: 4),
                              Text('14', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.onSurface)),
                              Text('3 High Priority', style: TextStyle(fontSize: 9, color: Color(0xFFBA1A1A), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Avg Response Time Hero Card (Image 4)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Avg Response Time', style: TextStyle(fontSize: 10, color: Colors.white70)),
                        const SizedBox(height: 2),
                        const Text('12m 45s', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFFA0F4C8))),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: const LinearProgressIndicator(
                            value: 0.75,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation(Color(0xFFA0F4C8)),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Response Timeline Section (Image 4)
                  const Text('Response Timeline', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.onSurface)),
                  const SizedBox(height: 10),
                  _buildTimelineItem('Poaching Alert Triggered', 'Sector 4, Near River Basin • 10:42 AM', const Color(0xFFBA1A1A)),
                  _buildTimelineItem('Acknowledged by Unit Alpha', 'Ranger J. Smith en route • 10:45 AM', AppTheme.secondary),
                  _buildTimelineItem('On Scene Investigation', 'Status pending update • In Progress', AppTheme.outlineVariant),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(String title, String subtitle, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 5, backgroundColor: dotColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.onSurface)),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StitchStatBentoCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final bool isDanger;
  final Color? iconColor;

  const _StitchStatBentoCard({
    required this.title,
    required this.count,
    required this.icon,
    this.isDanger = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDanger ? AppTheme.errorContainer : AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDanger ? AppTheme.error.withValues(alpha: 0.3) : AppTheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isDanger ? AppTheme.onErrorContainer : AppTheme.onSurfaceVariant,
                ),
              ),
              Icon(
                icon,
                size: 16,
                color: isDanger ? AppTheme.error : (iconColor ?? AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDanger ? AppTheme.error : AppTheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// 2. ALERTS TAB (Matching Image 4: Alerts Main Screen)
// ═══════════════════════════════════════════════════
class _RangerAlertsTab extends StatefulWidget {
  const _RangerAlertsTab();

  @override
  State<_RangerAlertsTab> createState() => _RangerAlertsTabState();
}

class _RangerAlertsTabState extends State<_RangerAlertsTab> {
  int _activeTabIndex = 0; // 0: ACTIVE, 1: PENDING, 2: RESOLVED

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppTheme.primary),
          onPressed: () {},
        ),
        title: const Text(
          'ForestGuard',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: AppTheme.primary),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'RM',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Header Row with Filter Icon Button (Image 4)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Alerts',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary,
                  letterSpacing: -0.5,
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.tune_rounded, color: AppTheme.primary, size: 20),
                  onPressed: () {},
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Tab Filter Pills Row: ACTIVE / PENDING / RESOLVED (Image 4)
          Row(
            children: [
              _buildTabPill(0, 'ACTIVE', isRed: true),
              const SizedBox(width: 10),
              _buildTabPill(1, 'PENDING'),
              const SizedBox(width: 10),
              _buildTabPill(2, 'RESOLVED'),
            ],
          ),

          const SizedBox(height: 20),

          // Card 1: Tiger Sighting (Red Accent - Image 4)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFDAD6)),
              boxShadow: AppTheme.ambientShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: Color(0xFFBA1A1A), width: 5)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFDAD6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFBA1A1A), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Tiger Sighting',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFDAD6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFBA1A1A)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: 12, color: AppTheme.onSurfaceVariant),
                                SizedBox(width: 2),
                                Text('Zone Alpha-4', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CAMERA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 0.5)),
                          SizedBox(height: 2),
                          Text('Cam_N_12', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.onSurface)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CONFIDENCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 0.5)),
                          SizedBox(height: 2),
                          Text('98%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFBA1A1A))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TIME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 0.5)),
                          SizedBox(height: 2),
                          Text('2 mins ago', style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFBA1A1A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('DISPATCH UNIT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.surfaceContainerHigh,
                            foregroundColor: AppTheme.onSurface,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('VIEW FEED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Card 2: Bear Activity (Mint Accent - Image 4)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
              boxShadow: AppTheme.ambientShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: Color(0xFFA0F4C8), width: 5)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE5F7ED),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.pets_rounded, color: AppTheme.secondary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Bear Activity',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5F7ED),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.secondary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: 12, color: AppTheme.onSurfaceVariant),
                                SizedBox(width: 2),
                                Text('Sector 3 – Riverbend', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CAMERA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 0.5)),
                          SizedBox(height: 2),
                          Text('Trail_C_04', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.onSurface)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CONFIDENCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 0.5)),
                          SizedBox(height: 2),
                          Text('85%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TIME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 0.5)),
                          SizedBox(height: 2),
                          Text('15 mins ago', style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Card 3: Sensor Disturbance (Dark Green Accent - Image 4)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
              boxShadow: AppTheme.ambientShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: AppTheme.primary, width: 5)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHigh,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.sensors_rounded, color: AppTheme.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Sensor Disturbance',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.primary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: 12, color: AppTheme.onSurfaceVariant),
                                SizedBox(width: 2),
                                Text('Perimeter Fence East', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SENSOR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 0.5)),
                          SizedBox(height: 2),
                          Text('Motion_E_99', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.onSurface)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TYPE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 0.5)),
                          SizedBox(height: 2),
                          Text('Vibration', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.onSurface)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TIME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 0.5)),
                          SizedBox(height: 2),
                          Text('42 mins ago', style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildTabPill(int index, String label, {bool isRed = false}) {
    final isActive = _activeTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? (isRed ? const Color(0xFFBA1A1A) : AppTheme.primary)
                : AppTheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: isActive ? Colors.white : AppTheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// 3. MAP TAB
// ═══════════════════════════════════════════════════
class _RangerMapTab extends ConsumerWidget {
  const _RangerMapTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zonesAsync = ref.watch(dangerZonesProvider);
    final alertsAsync = ref.watch(alertsProvider);
    final touristsAsync = ref.watch(touristsProvider);

    return Scaffold(
      body: ForestMapView(
        dangerZones: zonesAsync.value ?? [],
        alerts: alertsAsync.value ?? [],
        touristLocations: touristsAsync.value ?? [],
        isRanger: true,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// 4. MONITOR TAB (Image 1: Active Cameras Monitoring)
// ═══════════════════════════════════════════════════
class _RangerMonitorTab extends StatelessWidget {
  const _RangerMonitorTab();

  @override
  Widget build(BuildContext context) {
    return const CameraMonitoringScreen();
  }
}

// ═══════════════════════════════════════════════════
// 5. PROFILE TAB (Matching Image 5: Elena Vance Profile & Support)
// ═══════════════════════════════════════════════════
class _RangerProfileTab extends StatefulWidget {
  final AuthState auth;
  final VoidCallback onLogout;

  const _RangerProfileTab({required this.auth, required this.onLogout});

  @override
  State<_RangerProfileTab> createState() => _RangerProfileTabState();
}

class _RangerProfileTabState extends State<_RangerProfileTab> {
  bool _showSettingsView = false;

  @override
  Widget build(BuildContext context) {
    if (_showSettingsView) {
      return _RangerSettingsScreen(
        onBack: () => setState(() => _showSettingsView = false),
        onLogout: widget.onLogout,
      );
    }

    final userName = widget.auth.user?['full_name'] ?? 'Elena Vance';
    final userEmail = widget.auth.user?['email'] ?? 'elena.vance@example.com';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: const Row(
          children: [
            SizedBox(width: 16),
            Icon(Icons.forest_rounded, color: AppTheme.primary, size: 24),
            SizedBox(width: 8),
            Text('ForestGuard', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: AppTheme.primary)),
          ],
        ),
        leadingWidth: 200,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppTheme.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Centered Profile Card with Pencil Edit Button (Image 5)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    const CircleAvatar(
                      radius: 46,
                      backgroundImage: NetworkImage('https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=400&q=80'),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  userName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
                const SizedBox(height: 2),
                Text(
                  userEmail,
                  style: const TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5F7ED),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: AppTheme.secondary),
                          SizedBox(width: 4),
                          Text('Expert Guide', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.cabin_rounded, size: 14, color: AppTheme.onSurfaceVariant),
                          SizedBox(width: 4),
                          Text('14 Zones Visited', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 1: ACCOUNT SETTINGS (Image 5)
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'ACCOUNT SETTINGS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.onSurfaceVariant, letterSpacing: 1),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.ambientShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildProfileRow(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications & Alert Preferences',
                  subtitle: 'Manage wildlife and weather alerts',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 60),
                _buildProfileRow(
                  icon: Icons.gps_fixed_rounded,
                  title: 'Location Permissions & Privacy',
                  subtitle: 'GPS tracking and data sharing',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 60),
                _buildProfileRow(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark Mode / Language',
                  subtitle: 'System theme and locale',
                  onTap: () => setState(() => _showSettingsView = true),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 2: SUPPORT (Image 5)
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'SUPPORT',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.onSurfaceVariant, letterSpacing: 1),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.ambientShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildProfileRow(
                  icon: Icons.shield_outlined,
                  title: 'Safety Center / Help',
                  subtitle: 'Emergency protocols and FAQs',
                  iconColor: const Color(0xFFFFDAD6),
                  iconSymbolColor: const Color(0xFFBA1A1A),
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 60),
                _buildProfileRow(
                  icon: Icons.info_outline_rounded,
                  title: 'About ForestGuard',
                  subtitle: 'Version 2.4.1',
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Red Outlined Logout Button (Image 5)
          Container(
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: OutlinedButton.icon(
              onPressed: widget.onLogout,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFBA1A1A),
                side: const BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFBA1A1A)),
              label: const Text(
                'Logout',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFBA1A1A)),
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildProfileRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFFE5F7ED),
    Color iconSymbolColor = AppTheme.primary,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconSymbolColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.onSurfaceVariant, size: 20),
    );
  }
}

// ═══════════════════════════════════════════════════
// 6. RANGER SETTINGS SCREEN (Matching Image 1: Settings)
// ═══════════════════════════════════════════════════
class _RangerSettingsScreen extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onLogout;

  const _RangerSettingsScreen({required this.onBack, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.primary),
          onPressed: onBack,
        ),
        title: const Text(
          'ForestGuard',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: AppTheme.primary),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'RM',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Title & Subtitle (Image 1)
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppTheme.primary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Manage your ranger device preferences.',
            style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant),
          ),

          const SizedBox(height: 24),

          // Main Card Container with 6 Mint Icon Settings Rows (Image 1)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
              boxShadow: AppTheme.ambientShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildStitchSettingRow(
                  icon: Icons.notifications_none_outlined,
                  title: 'Notification Settings',
                  subtitle: 'Push alerts & sounds',
                ),
                const Divider(height: 1, indent: 64),
                _buildStitchSettingRow(
                  icon: Icons.location_on_outlined,
                  title: 'Location Settings',
                  subtitle: 'GPS tracking & sharing',
                ),
                const Divider(height: 1, indent: 64),
                _buildStitchSettingRow(
                  icon: Icons.campaign_outlined,
                  title: 'Alert Preferences',
                  subtitle: 'Poacher & wildlife alerts',
                ),
                const Divider(height: 1, indent: 64),
                _buildStitchSettingRow(
                  icon: Icons.layers_outlined,
                  title: 'Map Settings',
                  subtitle: 'Terrain, layers & offline',
                ),
                const Divider(height: 1, indent: 64),
                _buildStitchSettingRow(
                  icon: Icons.camera_alt_outlined,
                  title: 'Camera Settings',
                  subtitle: 'Trap integration & capture',
                ),
                const Divider(height: 1, indent: 64),
                _buildStitchSettingRow(
                  icon: Icons.shield_outlined,
                  title: 'Security',
                  subtitle: 'Biometrics & passcode',
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Red Outlined Log Out Device Button (Image 1)
          Center(
            child: SizedBox(
              width: 180,
              height: 48,
              child: OutlinedButton(
                onPressed: onLogout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFBA1A1A),
                  side: const BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Log Out Device',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFBA1A1A)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildStitchSettingRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Color(0xFFE5F7ED),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.primary, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.primary, size: 20),
      onTap: () {},
    );
  }
}
