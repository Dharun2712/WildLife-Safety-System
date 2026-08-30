import '../services/api_service.dart';

/// ForestGuard Auth Service — Login, Register, Token management.
class AuthService {
  final _api = ApiService();

  Future<Map<String, dynamic>> login(String username, String password, {String? role}) async {
    final response = await _api.dio.post('/api/auth/login', data: {
      'username': username,
      'password': password,
      if (role != null) 'role': role,
    });

    final data = response.data as Map<String, dynamic>;
    await _api.setTokens(data['access_token'], data['refresh_token']);
    return data;
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final response = await _api.dio.post('/api/auth/register', data: {
      'username': username,
      'email': email,
      'password': password,
      'full_name': fullName,
      'role': 'tourist',
      if (phone != null) 'phone': phone,
    });

    final data = response.data as Map<String, dynamic>;
    await _api.setTokens(data['access_token'], data['refresh_token']);
    return data;
  }

  Future<void> logout() async {
    await _api.clearTokens();
  }

  Future<String?> getToken() async {
    return await _api.getToken();
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _api.dio.get('/api/users/me');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _api.dio.put('/api/users/me', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _api.dio.post('/api/users/me/password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }
}
