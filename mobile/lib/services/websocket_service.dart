import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/constants.dart';

/// ForestGuard WebSocket Service
/// Real-time event streaming with auto-reconnect and exponential backoff.
class WebSocketService {
  WebSocketChannel? _channel;
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _reconnectAttempts = 0;
  bool _isConnected = false;
  bool _shouldReconnect = true;
  String? _token;

  Stream<Map<String, dynamic>> get events => _eventController.stream;
  bool get isConnected => _isConnected;

  void connect(String token) {
    _token = token;
    _shouldReconnect = true;
    _doConnect();
  }

  void _doConnect() {
    if (_token == null) return;

    try {
      final uri = Uri.parse('${AppConstants.wsBaseUrl}?token=$_token');
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;
      _reconnectAttempts = 0;

      _channel!.stream.listen(
        (data) {
          try {
            final message = jsonDecode(data as String) as Map<String, dynamic>;
            _eventController.add(message);
          } catch (_) {}
        },
        onDone: () {
          _isConnected = false;
          if (_shouldReconnect) _scheduleReconnect();
        },
        onError: (_) {
          _isConnected = false;
          if (_shouldReconnect) _scheduleReconnect();
        },
      );

      // Start ping timer
      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        sendMessage({'type': 'ping'});
      });
    } catch (_) {
      _isConnected = false;
      if (_shouldReconnect) _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    final delay = min(
      AppConstants.wsReconnectBaseDelayMs * pow(2, _reconnectAttempts).toInt(),
      AppConstants.wsReconnectMaxDelayMs,
    );
    _reconnectAttempts++;

    _reconnectTimer = Timer(Duration(milliseconds: delay), _doConnect);
  }

  void sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode(message));
      } catch (_) {}
    }
  }

  void sendLocationUpdate(double latitude, double longitude) {
    sendMessage({
      'type': 'location_update',
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  void disconnect() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _channel?.sink.close();
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _eventController.close();
  }
}
