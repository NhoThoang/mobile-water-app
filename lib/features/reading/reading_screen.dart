import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../data/models/customer_model.dart';
import '../../core/api_client.dart';

class ReadingScreen extends StatefulWidget {
  final Customer customer;
  const ReadingScreen({super.key, required this.customer});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final _readingController = TextEditingController();
  File? _image;
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    if (_readingController.text.isEmpty || _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập chỉ số và chụp ảnh!")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Upload ảnh trước
      String fileName = _image!.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(_image!.path, filename: fileName),
      });

      final uploadResp = await apiClient.dio.post(
        "/uploads/meter-image/${widget.customer.id}",
        data: formData,
      );

      String imageUrl = uploadResp.data["image_url"];

      // 2. Ghi chỉ số
      final now = DateTime.now();
      String monthStr = "${now.year}-${now.month.toString().padLeft(2, '0')}";

      await apiClient.dio.post(
        "/readings/",
        data: {
          "customer_id": widget.customer.id,
          "reading": double.parse(_readingController.text),
          "month": monthStr,
          "image_url": imageUrl,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã lưu chỉ số thành công!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: ${e.toString()}")),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ghi số: ${widget.customer.name}")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              elevation: 0,
              color: Colors.blue[50],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: const Padding(
                padding: EdgeInsets.all(15),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 10),
                    Expanded(child: Text("Vui lòng chụp ảnh rõ chỉ số trên đồng hồ nước.")),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _readingController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: "Chỉ số mới (m3)",
                hintText: "0.0",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                prefixIcon: const Icon(Icons.speed),
              ),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: _image == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 60, color: Colors.grey),
                          SizedBox(height: 10),
                          Text("Bấm để chụp ảnh", style: TextStyle(color: Colors.grey)),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(_image!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0061FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("XÁC NHẬN & LƯU", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
