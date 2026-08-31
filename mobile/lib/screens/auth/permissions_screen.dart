import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// ForestGuard - Permissions & Safety Features Onboarding (Images 1, 2, 3)
class PermissionsScreen extends StatefulWidget {
  final int initialView; // 0: Enable Safety Features (Image 2), 1: Location Unavailable (Image 1), 2: Action Required (Image 3)
  const PermissionsScreen({super.key, this.initialView = 0});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  late int _currentView;
  bool _locationAccessEnabled = false;
  bool _safetyAlertsEnabled = false;

  @override
  void initState() {
    super.initState();
    _currentView = widget.initialView;
  }

  @override
  Widget build(BuildContext context) {
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_currentView) {
      case 1:
        return _buildLocationUnavailableView();
      case 2:
        return _buildActionRequiredView();
      case 0:
      default:
        return _buildEnableSafetyFeaturesView();
    }
  }

  // 1. Image 1: Location Unavailable & Your Location Privacy
  Widget _buildLocationUnavailableView() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Location Unavailable Card (Image 1)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.ambientShadow,
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFDAD6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_off_rounded, color: Color(0xFFBA1A1A), size: 30),
              ),
              const SizedBox(height: 16),
              const Text(
                'Location Unavailable',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Unable to determine your current safety status. ForestGuard requires your location to provide accurate wildlife alerts and emergency assistance in the field.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _currentView = 0),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.gps_fixed_rounded, size: 18),
                  label: const Text('ENABLE LOCATION', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Your Location Privacy Card (Image 1)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.ambientShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFFE5F7ED),
                    child: Icon(Icons.shield_outlined, color: AppTheme.secondary, size: 20),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Your Location Privacy',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildPrivacyPoint(
                icon: Icons.check_circle_outline_rounded,
                title: 'Safety First',
                desc: 'Your location data is collected primarily to provide real-time wildlife proximity alerts and ensure rapid emergency response.',
              ),
              const SizedBox(height: 16),
              _buildPrivacyPoint(
                icon: Icons.visibility_off_outlined,
                title: 'Restricted Access',
                desc: 'Location history is only viewed by authorized park personnel during active safety incidents or emergency SOS activations.',
              ),
              const SizedBox(height: 16),
              _buildPrivacyPoint(
                icon: Icons.delete_outline_rounded,
                title: 'Data Retention',
                desc: 'Routine location pings are automatically anonymized and purged after 48 hours unless tied to an active incident.',
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildPrivacyPoint({required IconData icon, required String title, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  // 2. Image 2: Enable Safety Features Screen
  Widget _buildEnableSafetyFeaturesView() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 20),
        // Shield Emblem (Image 2)
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Icon(Icons.shield_outlined, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Enable Safety Features',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: -0.5),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your location is used to determine if you are approaching or inside an active wildlife safety zone. Notifications keep you informed in real-time.',
          style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant, height: 1.4),
        ),

        const SizedBox(height: 32),

        // Location Access Card with Switch (Image 2)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on_outlined, color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Location Access', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                        Switch(
                          value: _locationAccessEnabled,
                          activeThumbColor: AppTheme.secondary,
                          onChanged: (val) => setState(() => _locationAccessEnabled = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Allow ForestGuard to track your position against known wildlife zones.',
                      style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Safety Alerts Card with Switch (Image 2)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_none_outlined, color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Safety Alerts', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                        Switch(
                          value: _safetyAlertsEnabled,
                          activeThumbColor: AppTheme.secondary,
                          onChanged: (val) => setState(() => _safetyAlertsEnabled = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Receive instant push notifications when danger is detected nearby.',
                      style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),

        // Continue Button (Image 2)
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              if (!_locationAccessEnabled || !_safetyAlertsEnabled) {
                setState(() => _currentView = 2); // Show Action Required error (Image 3)
              } else {
                setState(() => _currentView = 1); // Show Location Unavailable/Privacy view (Image 1)
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('CONTINUE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        const Center(
          child: Text(
            'You can change these settings later in Profile > Privacy.',
            style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
          ),
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  // 3. Image 3: Action Required Missing Permissions Error View
  Widget _buildActionRequiredView() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 20),
        // Red Shield Warning Badge (Image 3)
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFFFDAD6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_outlined, color: Color(0xFFBA1A1A), size: 34),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Action Required',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: -0.5),
        ),
        const SizedBox(height: 8),
        const Text(
          'ForestGuard relies on your device settings to keep you safe in the field. Please review the missing permissions below.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant, height: 1.4),
        ),

        const SizedBox(height: 28),

        // Location Access Disabled Card (Image 3)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.location_off_outlined, color: AppTheme.onSurfaceVariant, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Location Access', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    SizedBox(height: 4),
                    Text(
                      'Without GPS, we cannot map nearby danger zones, track your route, or send location-specific SOS signals.',
                      style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Instant Alerts Disabled Card (Image 3)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.notifications_off_outlined, color: AppTheme.onSurfaceVariant, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Instant Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    SizedBox(height: 4),
                    Text(
                      'Without notifications, you will miss critical, time-sensitive warnings about sudden weather changes or wildlife proximity.',
                      style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 36),

        // Enable in Settings Button (Image 3)
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _currentView = 0),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.settings_outlined, size: 18),
            label: const Text('Enable in Settings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ),

        const SizedBox(height: 16),

        Center(
          child: TextButton(
            onPressed: () => setState(() => _currentView = 0),
            child: const Text('Retry', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary)),
          ),
        ),

        const SizedBox(height: 30),
      ],
    );
  }
}
