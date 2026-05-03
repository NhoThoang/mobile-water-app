import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'logger_service.dart';

class ApiClient {
  late Dio dio;
  final storage = const FlutterSecureStorage();
  final String baseUrl = "https://thoang5.nhothoang.store/api/v1";

  // MinIO base URL for images
  String get minioBaseUrl {
    // In production, we use the same domain with the /water-meter-images/ path handled by Nginx
    return baseUrl.replaceFirst("/api/v1", "/water-meter-images");
  }

  String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith("http")) return path;
    
    // Ensure minioBaseUrl doesn't end with a slash
    String base = minioBaseUrl;
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    
    // Ensure path doesn't start with a slash
    String cleanPath = path;
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }
    
    return "$base/$cleanPath";
  }

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        AppLogger.i("💡 API Request: ${options.method} ${options.path}");
        String? token = await storage.read(key: "access_token");
        if (token != null) {
          options.headers["Authorization"] = "Bearer $token";
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        AppLogger.i("✅ API Response [${response.statusCode}]: ${response.requestOptions.path}");
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        AppLogger.e("⛔ API Error [${e.response?.statusCode}]: ${e.requestOptions.path}");
        
        if (e.response?.statusCode == 502) {
          AppLogger.e("⚠️ Bad Gateway: The remote server at $baseUrl is failing to reach the backend.");
        }

        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          bool success = await refreshToken();
          if (success) {
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
        await storage.write(
            key: "access_token", value: response.data["access_token"]);
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
