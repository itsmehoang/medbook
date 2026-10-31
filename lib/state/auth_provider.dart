import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isAuthenticated = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  AuthProvider() {
    checkAuth();
  }

  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _apiService.getToken();
      if (token != null && token.isNotEmpty) {
        _currentUser = await _apiService.getMe();
        _isAuthenticated = true;
      } else {
        _isAuthenticated = false;
        _currentUser = null;
      }
    } catch (e) {
      _isAuthenticated = false;
      _currentUser = null;
      await _apiService.removeToken();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String phone, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.login(phone, password);
      _currentUser = UserModel.fromJson(result['user']);
      _isAuthenticated = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String fullName,
    required String phone,
    required String password,
    String? email,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.register(
        fullName: fullName,
        phone: phone,
        password: password,
        email: email,
      );
      _currentUser = UserModel.fromJson(result['user']);
      _isAuthenticated = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _apiService.removeToken();
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}

