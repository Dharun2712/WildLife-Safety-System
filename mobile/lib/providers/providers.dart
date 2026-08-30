import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

/// Auth state
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? role;
  final Map<String, dynamic>? user;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.role,
    this.user,
    this.error,
  });

  AuthState copyWith({bool? isAuthenticated, bool? isLoading, String? role, Map<String, dynamic>? user, String? error}) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      role: role ?? this.role,
      user: user ?? this.user,
      error: error,
    );
  }
}

/// Auth provider
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();
  final WebSocketService _wsService = WebSocketService();

  AuthNotifier() : super(const AuthState());

  WebSocketService get wsService => _wsService;

  Future<bool> login(String username, String password, {String? role}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _authService.login(username, password, role: role);
      final user = data['user'] as Map<String, dynamic>;

      // Connect WebSocket
      _wsService.connect(data['access_token']);

      state = AuthState(
        isAuthenticated: true,
        role: user['role'],
        user: user,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e),
      );
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _authService.register(
        username: username,
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      final user = data['user'] as Map<String, dynamic>;
      _wsService.connect(data['access_token']);

      state = AuthState(
        isAuthenticated: true,
        role: user['role'],
        user: user,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  Future<void> logout() async {
    _wsService.disconnect();
    await _authService.logout();
    state = const AuthState();
  }

  Future<void> checkAuth() async {
    try {
      final token = await _authService.getToken();
      if (token != null) {
        final profile = await _authService.getProfile();
        _wsService.connect(token);
        state = AuthState(
          isAuthenticated: true,
          role: profile['role'],
          user: profile,
        );
      }
    } catch (_) {
      state = const AuthState();
    }
  }

  String _parseError(dynamic e) {
    if (e.toString().contains('401')) return 'Invalid username or password';
    if (e.toString().contains('409')) return 'Username or email already taken';
    if (e.toString().contains('Connection')) return 'Cannot connect to server';
    return 'An error occurred. Please try again.';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// --- Data Providers ---

final forestsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await ApiService().dio.get('/api/forests');
  return List<Map<String, dynamic>>.from(response.data);
});

final alertsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final response = await ApiService().dio.get('/api/alerts');
  return List<Map<String, dynamic>>.from(response.data);
});

final dangerZonesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final response = await ApiService().dio.get('/api/danger-zones', queryParameters: {'status': 'active'});
  return List<Map<String, dynamic>>.from(response.data);
});

final notificationsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final response = await ApiService().dio.get('/api/notifications');
  return List<Map<String, dynamic>>.from(response.data);
});

final camerasProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await ApiService().dio.get('/api/cameras');
  return List<Map<String, dynamic>>.from(response.data);
});

final detectionsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final response = await ApiService().dio.get('/api/wildlife/detections', queryParameters: {'limit': '50'});
  return List<Map<String, dynamic>>.from(response.data);
});

final reportsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, type) async {
  final response = await ApiService().dio.get('/api/reports/$type');
  return response.data as Map<String, dynamic>;
});

// Selected forest
final selectedForestProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

// Safety status
final safetyStatusProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  try {
    final response = await ApiService().dio.get('/api/tourists/safety-status');
    return response.data as Map<String, dynamic>;
  } catch (_) {
    return {'status': 'safe', 'message': 'Unable to determine safety status', 'active_danger_zones': []};
  }
});

// WebSocket service provider
final webSocketProvider = Provider<WebSocketService>((ref) {
  return ref.watch(authProvider.notifier).wsService;
});

// Tourist incident locations provider (Ranger RBAC)
final touristsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  try {
    final response = await ApiService().dio.get('/api/tourists/locations');
    return List<Map<String, dynamic>>.from(response.data);
  } catch (_) {
    return [];
  }
});
