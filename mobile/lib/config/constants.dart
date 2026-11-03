import 'package:flutter/material.dart';

/// ForestGuard - App Constants
/// API URLs and configuration loaded from build config.
class AppConstants {
  // Backend API - Deployed on Render Cloud
  static const String apiBaseUrl =
      'https://wildlife-safety-system.onrender.com';
  static const String wsBaseUrl =
      'wss://wildlife-safety-system.onrender.com/ws';

  // App Info
  static const String appName = 'ForestGuard';
  static const String appVersion = '1.0.0';

  // MapTiler Configuration
  static const String mapTilerApiKey = '8Yw0FgmmTm08f2u2Gc49';
  static const String mapTilerSatelliteUrl =
      'https://api.maptiler.com/maps/satellite/{z}/{x}/{y}.jpg?key=8Yw0FgmmTm08f2u2Gc49';
  static const String mapTilerHybridUrl =
      'https://api.maptiler.com/maps/hybrid/{z}/{x}/{y}.jpg?key=8Yw0FgmmTm08f2u2Gc49';

  // Location
  static const int locationUpdateIntervalSeconds = 30;
  static const double defaultLatitude = 11.5690;
  static const double defaultLongitude = 76.6320;
  static const double defaultZoom = 13.0;

  // WebSocket
  static const int wsReconnectBaseDelayMs = 500;
  static const int wsReconnectMaxDelayMs = 5000;

  // Safety labels
  static const Map<String, String> safetyMessages = {
    'safe': 'No active alerts. Conditions are stable and all clear.',
    'approaching': 'You are approaching an active wildlife safety zone.',
    'inside':
        'Your current location is within an active wildlife safety zone. '
        'Remain at a safe location and follow official ranger instructions.',
  };

  // Animal info (Rich species display names, emojis & Material Icons)
  static const Map<String, String> animalEmojis = {
    'tiger': '🐅',
    'bengal tiger': '🐅',
    'elephant': '🐘',
    'asian elephant': '🐘',
    'lion': '🦁',
    'african lion': '🦁',
    'leopard': '🐆',
    'indian leopard': '🐆',
    'bear': '🐻',
    'sloth bear': '🐻',
    'sloth': '🐻',
  };

  static const Map<String, IconData> animalIcons = {
    'tiger': Icons.pets_rounded,
    'bengal tiger': Icons.pets_rounded,
    'elephant': Icons.forest_rounded,
    'asian elephant': Icons.forest_rounded,
    'lion': Icons.cruelty_free_rounded,
    'african lion': Icons.cruelty_free_rounded,
    'leopard': Icons.radar_rounded,
    'indian leopard': Icons.radar_rounded,
    'bear': Icons.landscape_rounded,
    'sloth bear': Icons.landscape_rounded,
    'sloth': Icons.landscape_rounded,
  };

  static IconData getAnimalIcon(String animalType) {
    final key = animalType.toLowerCase();
    return animalIcons[key] ?? Icons.pets_rounded;
  }

  static const Map<String, String> animalNames = {
    'tiger': 'Bengal Tiger',
    'bengal tiger': 'Bengal Tiger',
    'elephant': 'Asian Elephant',
    'asian elephant': 'Asian Elephant',
    'lion': 'African Lion',
    'african lion': 'African Lion',
    'leopard': 'Indian Leopard',
    'indian leopard': 'Indian Leopard',
    'bear': 'Sloth Bear',
    'sloth bear': 'Sloth Bear',
    'sloth': 'Sloth Bear',
  };
}
