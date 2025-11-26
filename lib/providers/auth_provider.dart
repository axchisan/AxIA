import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _currentUser;
  String? _error;

  bool get isLoading => _isLoading;
  String? get currentUser => _currentUser;
  String? get error => _error;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _authService.login(username, password);
      if (success) {
        _currentUser = username;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Invalid credentials';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> checkAuthentication() async {
    final isAuth = await _authService.isAuthenticated();
    if (isAuth) {
      _currentUser = await _authService.getCurrentUser();
      notifyListeners();
    }
    return isAuth;
  }
}
