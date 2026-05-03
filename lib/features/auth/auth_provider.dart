import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api_client.dart';
import 'package:dio/dio.dart';

enum AuthStatus { initial, authenticated, unauthenticated, authenticating }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  final storage = const FlutterSecureStorage();
  String? _username;
  String? _role;

  AuthStatus get status => _status;
  String? get username => _username;
  String? get role => _role;

  Future<bool> login(String username, String password) async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    try {
      final response = await apiClient.dio.post(
        "/auth/login",
        data: {
          "username": username,
          "password": password,
        },
      );

      if (response.statusCode == 200) {
        await storage.write(key: "access_token", value: response.data["access_token"]);
        await storage.write(key: "refresh_token", value: response.data["refresh_token"]);
        
        // Fetch user profile to get role
        final profileResponse = await apiClient.dio.get("/auth/me");
        if (profileResponse.statusCode == 200) {
          _role = profileResponse.data["role"];
          _username = profileResponse.data["username"];
        }

        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
    return false;
  }

  Future<void> logout() async {
    String? refresh = await storage.read(key: "refresh_token");
    if (refresh != null) {
      try {
        await apiClient.dio.post("/auth/logout", data: {"refresh_token": refresh});
      } catch (e) {
        // Ignore logout error
      }
    }
    await storage.deleteAll();
    _status = AuthStatus.unauthenticated;
    _username = null;
    _role = null;
    notifyListeners();
  }

  Future<void> checkAuth() async {
    String? token = await storage.read(key: "access_token");
    if (token != null) {
      try {
        final response = await apiClient.dio.get("/auth/me");
        if (response.statusCode == 200) {
          _role = response.data["role"];
          _username = response.data["username"];
          _status = AuthStatus.authenticated;
        } else {
          _status = AuthStatus.unauthenticated;
        }
      } catch (e) {
        // Nếu lỗi 401, ApiClient sẽ tự refresh. Nếu vẫn lỗi thì coi như chưa auth
        if (e is DioException && e.response?.statusCode == 401) {
           // Đợi một chút để ApiClient thử refresh (nếu có cơ chế đó chạy ngầm)
           // Hoặc đơn giản là để unauthenticated nếu refresh thất bại
           _status = AuthStatus.unauthenticated;
        } else {
           _status = AuthStatus.unauthenticated;
        }
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}
