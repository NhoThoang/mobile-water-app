import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/meter_reading_model.dart';
import '../../core/api_client.dart';
import 'reading_provider.dart';
import 'package:intl/intl.dart';

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
  DateTime _selectedMonth = DateTime.now();
  List<MeterReading> _history = [];
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final response = await apiClient.dio.get("/readings/customer/${widget.customer.id}");
      if (response.statusCode == 200) {
        setState(() {
          _history = (response.data as List).map((j) => MeterReading.fromJson(j)).toList();
          // Sắp xếp theo tháng giảm dần
          _history.sort((a, b) => b.month.compareTo(a.month));
        });
      }
    } catch (e) {
      debugPrint("Error fetching history: $e");
    } finally {
      setState(() => _isLoadingHistory = false);
    }
  }

  void _showImagePreview(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  apiClient.getImageUrl(imageUrl),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  },
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2023),
      lastDate: DateTime(2101),
      initialDatePickerMode: DatePickerMode.year,
      helpText: "Chọn kỳ hóa đơn",
    );
    if (picked != null && picked != _selectedMonth) {
      setState(() {
        _selectedMonth = picked;
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
      final monthStr = DateFormat('yyyy-MM').format(_selectedMonth);
      final readingProv = context.read<ReadingProvider>();
      
      // Mặc định thử online trước
      await readingProv.submitReading(
        customerId: widget.customer.id,
        reading: double.parse(_readingController.text),
        month: monthStr,
        image: _image!,
        isOnline: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã lưu chỉ số thành công!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      String msg = "Đã xảy ra lỗi!";
      bool isOfflineMode = false;

      if (e is DioException) {
        if (e.type == DioExceptionType.connectionError || 
            e.type == DioExceptionType.connectionTimeout) {
          msg = "Mất kết nối. Đã lưu vào bộ nhớ tạm để đồng bộ sau.";
          isOfflineMode = true;
        } else {
          msg = e.response?.data['detail'] ?? "Lỗi từ máy chủ!";
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: isOfflineMode ? Colors.orange : Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        if (isOfflineMode) Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
            
            // Chọn kỳ hóa đơn
            InkWell(
              onTap: _selectMonth,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: Colors.blue),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Kỳ hóa đơn (Tháng)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(DateFormat('MM / yyyy').format(_selectedMonth), 
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit, size: 20, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

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
            const SizedBox(height: 40),
            
            // Lịch sử tiêu thụ
            const Row(
              children: [
                Icon(Icons.history, color: Colors.grey),
                SizedBox(width: 10),
                Text("Lịch sử tiêu thụ gần đây", 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 15),
            
            if (_isLoadingHistory)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (_history.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Chưa có dữ liệu lịch sử.")))
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(2),
                    2: FlexColumnWidth(1),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: const BorderRadius.vertical(top: Radius.circular(15))),
                      children: const [
                        Padding(padding: EdgeInsets.all(12), child: Text("Tháng", style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(12), child: Text("Chỉ số", style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(12), child: Text("Ảnh", style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                    ..._history.take(6).map((item) => TableRow(
                      children: [
                        Padding(padding: const EdgeInsets.all(12), child: Text(item.month)),
                        Padding(
                          padding: const EdgeInsets.all(12), 
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${item.reading} m3", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                              Text("Tăng: ${item.consumption.toStringAsFixed(1)} m3", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          )
                        ),
                        Padding(
                          padding: const EdgeInsets.all(4), 
                          child: item.imageUrl != null 
                            ? IconButton(
                                icon: const Icon(Icons.image, color: Colors.blue, size: 20),
                                onPressed: () => _showImagePreview(item.imageUrl!),
                              )
                            : const Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.no_photography, size: 16, color: Colors.grey)),
                        ),
                      ],
                    )),
                  ],
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
