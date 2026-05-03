import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'logger_service.dart';

class ApiClient {
  late Dio dio;
  final storage = const FlutterSecureStorage();
  final String baseUrl = "http://10.0.2.2:8000/api/v1"; // 10.0.2.2 cho Android Emulator

  ApiClient() {
    dio = Dio(BaseOptions(baseUrl: baseUrl));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        AppLogger.i("API Request: ${options.method} ${options.path}");
        String? token = await storage.read(key: "access_token");
        if (token != null) {
          options.headers["Authorization"] = "Bearer $token";
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        AppLogger.e("API Error: ${e.response?.statusCode} - ${e.message}");
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          // Token hết hạn, thử refresh
          bool success = await refreshToken();
          if (success) {
            // Retry request cũ
            return handler.resolve(await _retry(e.requestOptions));
          }
        }
        return handler.next(e);
      },
    ));
  }

  Future<bool> refreshToken() async {
    String? refresh = await storage.read(key: "refresh_token");
    if (refresh == null) return false;

    try {
      final response = await Dio().post(
        "$baseUrl/auth/refresh",
        data: {"refresh_token": refresh},
      );

      if (response.statusCode == 200) {
        await storage.write(key: "access_token", value: response.data["access_token"]);
        return true;
      }
    } catch (e) {
      // Refresh token cũng hết hạn -> Yêu cầu logout
    }
    return false;
  }

  Future<Response> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    String? token = await storage.read(key: "access_token");
    options.headers?["Authorization"] = "Bearer $token";

    return dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}

final apiClient = ApiClient();
