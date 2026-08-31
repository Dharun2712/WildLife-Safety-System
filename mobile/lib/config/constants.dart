/// ForestGuard - App Constants
/// API URLs and configuration loaded from build config.
class AppConstants {
  // Backend API - Deployed on Render Cloud
  static const String apiBaseUrl =
      'https://wildlife-safety-system.onrender.com';
  static const String wsBaseUrl =
      'wss://wildlife-safety-system.onrender.com/ws';

  // For Android Emulator localhost fallback:
  // static const String apiBaseUrl = 'http://10.0.2.2:8000';
  // static const String wsBaseUrl = 'ws://10.0.2.2:8000/ws';

  // App Info
  static const String appName = 'ForestGuard';
  static const String appVersion = '1.0.0';

  // Location
  static const int locationUpdateIntervalSeconds = 30;
  static const double defaultLatitude = 11.5690;
  static const double defaultLongitude = 76.6320;
  static const double defaultZoom = 13.0;

  // WebSocket
  static const int wsReconnectBaseDelayMs = 1000;
  static const int wsReconnectMaxDelayMs = 30000;

  // Safety labels
  static const Map<String, String> safetyMessages = {
    'safe': 'No active wildlife safety alert near your current location.',
    'approaching': 'You are approaching an active wildlife safety zone.',
    'inside':
        'Your current location is within an active wildlife safety zone. '
        'Remain at a safe location and follow official ranger instructions.',
  };

  // Animal info
  static const Map<String, String> animalEmojis = {
    'tiger': '',
    'elephant': '',
    'lion': '',
    'leopard': '',
    'bear': '',
  };

  static const Map<String, String> animalNames = {
    'tiger': 'Tiger',
    'elephant': 'Elephant',
    'lion': 'Lion',
    'leopard': 'Leopard',
    'bear': 'Bear',
  };
}
