import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../config/api_config.dart';

class AuthService {
  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'current_user';
  final _secureStorage = const FlutterSecureStorage();

  Future<bool> login(String username, String password) async {
    try {
      print('[v0] Attempting login for user: $username');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.tokenEndpoint}'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': username,
          'password': password,
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Connection timeout'),
      );

      print('[v0] Login response status: ${response.statusCode}');
      print('[v0] Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];

        await _secureStorage.write(key: _tokenKey, value: token);
        await _secureStorage.write(key: _userKey, value: username);

        print('[v0] Login successful, token stored');
        return true;
      } else if (response.statusCode == 401) {
        print('[v0] Invalid credentials');
        return false;
      } else {
        print('[v0] Login error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('[v0] Login exception: $e');
      return false;
    }
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<String?> getCurrentUser() async {
    return await _secureStorage.read(key: _userKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userKey);
  }
}
