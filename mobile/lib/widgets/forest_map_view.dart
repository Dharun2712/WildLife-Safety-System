import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../config/constants.dart';
import '../config/theme.dart';
import 'detection_alert_modal.dart';

/// Enum to support modular map tile providers (OpenStreetMap default, extensible to Mapbox/Google)
enum MapProviderType { openStreetMap, cartoDark, satellite }

/// Interactive GIS Map Widget using OpenStreetMap (flutter_map)
/// Supports forest zone polygons, camera nodes, wildlife markers,
/// multiple simultaneous circular danger zones, user GPS location, marker popups,
/// zoom/pan controls, and RBAC-scoped tourist markers.
class ForestMapView extends StatefulWidget {
  final List<dynamic> dangerZones;
  final List<dynamic> alerts;
  final List<dynamic> touristLocations;
  final bool isRanger;
  final MapProviderType providerType;
  final LatLng? initialCenter;
  final double initialZoom;

  const ForestMapView({
    super.key,
    this.dangerZones = const [],
    this.alerts = const [],
    this.touristLocations = const [],
    this.isRanger = false,
    this.providerType = MapProviderType.openStreetMap,
    this.initialCenter,
    this.initialZoom = 13.5,
  });

  @override
  State<ForestMapView> createState() => _ForestMapViewState();
}

class _ForestMapViewState extends State<ForestMapView> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;

  // Mudumalai Forest Center (11.5690° N, 76.6320° E)
  static final LatLng _defaultForestCenter = LatLng(
    AppConstants.defaultLatitude,
    AppConstants.defaultLongitude,
  );

  // Camera C-01 Location
  static final LatLng _cameraC01Location = LatLng(11.5690, 76.6320);

  // Forest Zone Polygons (Mudumalai Perimeter + Zones A, B, C, D)
  static final List<LatLng> _forestBoundary = [
    LatLng(11.6200, 76.5800),
    LatLng(11.6200, 76.6800),
    LatLng(11.5200, 76.6800),
    LatLng(11.5200, 76.5800),
  ];

  static final List<LatLng> _zoneABoundary = [
    LatLng(11.6200, 76.6200),
    LatLng(11.6200, 76.6800),
    LatLng(11.5600, 76.6800),
    LatLng(11.5600, 76.6200),
  ];

  static final List<LatLng> _zoneBBoundary = [
    LatLng(11.6200, 76.5800),
    LatLng(11.6200, 76.6200),
    LatLng(11.5600, 76.6200),
    LatLng(11.5600, 76.5800),
  ];

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initLocationTracking() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() => _currentPosition = pos);
      }

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((pos) {
        if (mounted) {
          setState(() => _currentPosition = pos);
        }
      });
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  void _recenterMyPosition() {
    if (_currentPosition != null) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        15.0,
      );
    } else {
      _recenterForest();
    }
  }

  void _recenterForest() {
    _mapController.move(widget.initialCenter ?? _defaultForestCenter, widget.initialZoom);
  }

  void _zoomIn() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1.0);
  }

  void _zoomOut() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1.0);
  }

  String _getTileUrl() {
    switch (widget.providerType) {
      case MapProviderType.cartoDark:
        return 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';
      case MapProviderType.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapProviderType.openStreetMap:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng center = widget.initialCenter ??
        (_currentPosition != null
            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
            : _defaultForestCenter);

    return Stack(
      children: [
        // Main OpenStreetMap View
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: widget.initialZoom,
            minZoom: 8.0,
            maxZoom: 18.0,
          ),
          children: [
            // 1. Tile Layer (OpenStreetMap)
            TileLayer(
              urlTemplate: _getTileUrl(),
              userAgentPackageName: 'com.forestguard.forestguard',
            ),

            // 2. Forest Zone Boundaries (Polygons)
            PolygonLayer(
              polygons: [
                // Mudumalai Forest Outer Perimeter
                Polygon(
                  points: _forestBoundary,
                  color: Colors.green.withOpacity(0.06),
                  borderColor: Colors.green.shade700,
                  borderStrokeWidth: 2.0,
                ),
                // Zone A Boundary
                Polygon(
                  points: _zoneABoundary,
                  color: Colors.red.withOpacity(0.08),
                  borderColor: Colors.red.shade400,
                  borderStrokeWidth: 1.5,
                ),
                // Zone B Boundary
                Polygon(
                  points: _zoneBBoundary,
                  color: Colors.amber.withOpacity(0.06),
                  borderColor: Colors.amber.shade600,
                  borderStrokeWidth: 1.5,
                ),
              ],
            ),

            // 3. Active Circular Danger Zones
            CircleLayer(
              circles: _buildDangerZoneCircles(),
            ),

            // 4. Interactive Markers Layer
            MarkerLayer(
              markers: _buildMapMarkers(context),
            ),
          ],
        ),

        // Map Control Floating Buttons (Top-Right / Bottom-Right)
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              _mapControlButton(
                icon: Icons.add,
                onPressed: _zoomIn,
                tooltip: 'Zoom In',
              ),
              const SizedBox(height: 8),
              _mapControlButton(
                icon: Icons.remove,
                onPressed: _zoomOut,
                tooltip: 'Zoom Out',
              ),
              const SizedBox(height: 12),
              _mapControlButton(
                icon: Icons.my_location,
                color: Colors.blueAccent,
                onPressed: _recenterMyPosition,
                tooltip: 'My Location',
              ),
              const SizedBox(height: 8),
              _mapControlButton(
                icon: Icons.park,
                color: AppTheme.forestGreen,
                onPressed: _recenterForest,
                tooltip: 'Forest Center',
              ),
            ],
          ),
        ),

        // Top Zone Telemetry Ribbon
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade900.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade700),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: widget.dangerZones.isNotEmpty ? Colors.redAccent : Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.dangerZones.isNotEmpty
                      ? '${widget.dangerZones.length} Active Threat Zone(s)'
                      : 'Perimeter Secure • Zone A',
                  style: TextStyle(
                    color: widget.dangerZones.isNotEmpty ? Colors.redAccent : Colors.greenAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Builds active circular danger zone overlays
  List<CircleMarker> _buildDangerZoneCircles() {
    final List<CircleMarker> circles = [];

    for (var dz in widget.dangerZones) {
      double lat = (dz['center_latitude'] ?? dz['latitude'] ?? 11.5690).toDouble();
      double lng = (dz['center_longitude'] ?? dz['longitude'] ?? 76.6320).toDouble();
      double radius = (dz['radius_meters'] ?? 1500).toDouble();

      circles.add(
        CircleMarker(
          point: LatLng(lat, lng),
          radius: radius,
          useRadiusInMeter: true,
          color: Colors.red.withOpacity(0.18),
          borderColor: Colors.redAccent,
          borderStrokeWidth: 2.0,
        ),
      );
    }

    return circles;
  }

  /// Builds all map markers (GPS, Camera, Wildlife, Tourists)
  List<Marker> _buildMapMarkers(BuildContext context) {
    final List<Marker> markers = [];

    // A. Current User GPS Location Marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          width: 44,
          height: 44,
          child: GestureDetector(
            onTap: () => _showMarkerDetails(
              context,
              title: widget.isRanger ? 'Ranger Location' : 'Your GPS Location',
              subtitle: '${_currentPosition!.latitude.toStringAsFixed(4)}° N, ${_currentPosition!.longitude.toStringAsFixed(4)}° E',
              icon: widget.isRanger ? Icons.security : Icons.person_pin_circle,
              color: widget.isRanger ? AppTheme.forestGreen : Colors.blueAccent,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: (widget.isRanger ? AppTheme.forestGreen : Colors.blueAccent).withOpacity(0.25),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Icon(
                  widget.isRanger ? Icons.security : Icons.my_location,
                  color: widget.isRanger ? AppTheme.forestGreen : Colors.blueAccent,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // B. Camera C-01 Sentinel Tower Marker
    markers.add(
      Marker(
        point: _cameraC01Location,
        width: 50,
        height: 50,
        child: GestureDetector(
          onTap: () => _showMarkerDetails(
            context,
            title: 'Sentinel Camera C-01',
            subtitle: 'Zone A Mudumalai Perimeter • Live AI Edge Sentinel',
            icon: Icons.videocam,
            color: Colors.greenAccent,
            actionText: 'View Camera Stream',
            onAction: () {
              Navigator.pop(context);
              DetectionAlertModal.show(
                context,
                detection: {
                  'animal_type': 'tiger',
                  'confidence': 0.94,
                  'camera_id': 'C-01',
                  'latitude': 11.5690,
                  'longitude': 76.6320,
                  'verification_status': 'VERIFIED',
                },
                isRanger: widget.isRanger,
              );
            },
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.greenAccent, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6)],
            ),
            child: const Icon(Icons.videocam, color: Colors.greenAccent, size: 24),
          ),
        ),
      ),
    );

    // C. Wildlife Threat Markers from Active Alerts/Detections
    for (var alert in widget.alerts) {
      final animal = (alert['animal_type'] ?? 'wildlife').toString().toLowerCase();
      final emoji = AppConstants.animalEmojis[animal] ?? '🐾';
      final lat = (alert['latitude'] is num) ? (alert['latitude'] as num).toDouble() : 11.5690;
      final lng = (alert['longitude'] is num) ? (alert['longitude'] as num).toDouble() : 76.6320;

      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () => DetectionAlertModal.show(
              context,
              detection: Map<String, dynamic>.from(alert),
              isRanger: widget.isRanger,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.shade900.withOpacity(0.9),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.redAccent, width: 2),
                boxShadow: const [BoxShadow(color: Colors.redAccent, blurRadius: 10)],
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
          ),
        ),
      );
    }

    // D. Ranger RBAC: Render Nearby Tourist Location Pins (Ranger View ONLY)
    if (widget.isRanger && widget.touristLocations.isNotEmpty) {
      for (var tourist in widget.touristLocations) {
        final tLat = (tourist['latitude'] is num) ? (tourist['latitude'] as num).toDouble() : 0.0;
        final tLng = (tourist['longitude'] is num) ? (tourist['longitude'] as num).toDouble() : 0.0;
        final name = tourist['user_name'] ?? tourist['full_name'] ?? 'Tourist';

        if (tLat != 0.0 && tLng != 0.0) {
          markers.add(
            Marker(
              point: LatLng(tLat, tLng),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => _showMarkerDetails(
                  context,
                  title: 'Tourist: $name',
                  subtitle: 'Authorized Incident Monitoring (Ranger RBAC)',
                  icon: Icons.person_pin,
                  color: Colors.amberAccent,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.amber.shade900,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amberAccent, width: 2),
                  ),
                  child: const Icon(Icons.person, color: Colors.amberAccent, size: 20),
                ),
              ),
            ),
          );
        }
      }
    }

    return markers;
  }

  Widget _mapControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    Color color = Colors.white,
  }) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.9),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade700),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
      ),
    );
  }

  void _showMarkerDetails(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? actionText,
    VoidCallback? onAction,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (actionText != null && onAction != null) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: onAction,
                    child: Text(actionText, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
