import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../core/database_service.dart';

class ReadingProvider extends ChangeNotifier {
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  Future<void> submitReading({
    required int customerId,
    required double reading,
    required String month,
    required File image,
    required bool isOnline,
  }) async {
    if (isOnline) {
      try {
        // 1. Upload ảnh
        String fileName = image.path.split('/').last;
        FormData formData = FormData.fromMap({
          "file": await MultipartFile.fromFile(image.path, filename: fileName),
        });

        final uploadResp = await apiClient.dio.post(
          "/uploads/meter-image/$customerId",
          data: formData,
        );

        String imageUrl = uploadResp.data["image_url"];

        // 2. Ghi chỉ số
        await apiClient.dio.post(
          "/readings/",
          data: {
            "customer_id": customerId,
            "reading": reading,
            "month": month,
            "image_url": imageUrl,
          },
        );
      } catch (e) {
        // Nếu đang online mà lỗi mạng đột ngột, chuyển sang lưu offline
        if (e is DioException) {
          await _saveOffline(customerId, reading, month, image);
          rethrow; // Để UI biết là đã chuyển sang offline
        }
        rethrow;
      }
    } else {
      await _saveOffline(customerId, reading, month, image);
    }
  }

  Future<void> _saveOffline(int customerId, double reading, String month, File image) async {
    await dbService.saveReadingOffline({
      'customer_id': customerId,
      'reading': reading,
      'month': month,
      'image_path': image.path,
    });
    notifyListeners();
  }

  Future<int> getPendingCount() async {
    final pending = await dbService.getPendingReadings();
    return pending.length;
  }

  Future<void> syncOfflineReadings() async {
    final pending = await dbService.getPendingReadings();
    if (pending.isEmpty) return;

    _isSyncing = true;
    notifyListeners();

    for (var item in pending) {
      try {
        // 1. Upload ảnh
        File file = File(item['image_path']);
        FormData formData = FormData.fromMap({
          "file": await MultipartFile.fromFile(file.path),
        });
        final uploadResp = await apiClient.dio.post(
          "/uploads/meter-image/${item['customer_id']}",
          data: formData,
        );

        // 2. Ghi số
        await apiClient.dio.post(
          "/readings/",
          data: {
            "customer_id": item['customer_id'],
            "reading": item['reading'],
            "month": item['month'],
            "image_url": uploadResp.data["image_url"],
          },
        );

        // 3. Xóa sau khi sync thành công
        await dbService.deletePendingReading(item['id']);
      } catch (e) {
        // Nếu lỗi (vd: vẫn mất mạng), giữ lại để sync sau
      }
    }

    _isSyncing = false;
    notifyListeners();
  }
}
