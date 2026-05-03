import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import '../../data/models/bill_model.dart';

class BillListScreen extends StatefulWidget {
  const BillListScreen({super.key});

  @override
  State<BillListScreen> createState() => _BillListScreenState();
}

class _BillListScreenState extends State<BillListScreen> {
  List<Bill> _bills = [];
  bool _isLoading = false;
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _fetchBills();
  }

  Future<void> _fetchBills() async {
    setState(() => _isLoading = true);
    try {
      final response = await apiClient.dio
          .get("/payments/history"); // Endpoint lấy lịch sử bill
      if (response.statusCode == 200) {
        setState(() {
          _bills =
              (response.data as List).map((j) => Bill.fromJson(j)).toList();
        });
      }
    } catch (e) {}
    setState(() => _isLoading = false);
  }

  void _showPaymentQR(Bill bill) {
    // Giả lập VietQR hoặc QR thanh toán
    // Nội dung: "BILL ID" để hệ thống tự động gạch nợ
    String qrUrl =
        "https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=Thanh+toan+BILL+${bill.id}";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Quét mã để thanh toán",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Image.network(qrUrl, height: 200),
            const SizedBox(height: 20),
            Text("Số tiền: ${currencyFormatter.format(bill.totalAmount)}",
                style: const TextStyle(
                    fontSize: 18,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Nội dung chuyển khoản:"),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10)),
              child: Text("BILL ${bill.id}",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
            const Text(
                "Hệ thống sẽ tự động cập nhật sau 1-2 phút chuyển khoản.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hóa đơn của tôi")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _bills.length,
              itemBuilder: (context, index) {
                final bill = _bills[index];
                bool isPaid = bill.status == "paid";
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Tháng ${bill.month}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color:
                                    isPaid ? Colors.green[50] : Colors.red[50],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(isPaid ? "ĐÃ ĐÓNG" : "CHƯA ĐÓNG",
                                  style: TextStyle(
                                      color: isPaid ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const Divider(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Tiêu thụ:"),
                            Text("${bill.consumption} m3",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Tổng tiền:"),
                            Text(currencyFormatter.format(bill.totalAmount),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                    fontSize: 18)),
                          ],
                        ),
                        if (!isPaid) ...[
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _showPaymentQR(bill),
                              icon: const Icon(Icons.qr_code),
                              label: const Text("THANH TOÁN NGAY"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
