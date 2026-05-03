import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'customer_provider.dart';
import '../auth/auth_provider.dart';
import '../reading/reading_provider.dart';
import '../reading/reading_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().fetchCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final customerProv = context.watch<CustomerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hộ dân", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<ReadingProvider>(
            builder: (context, readingProv, _) {
              return FutureBuilder<int>(
                future: readingProv.getPendingCount(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  if (count == 0) return const SizedBox();
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.sync, color: Colors.orange),
                        onPressed: readingProv.isSyncing 
                          ? null 
                          : () async {
                              await readingProv.syncOfflineReadings();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Đã đồng bộ dữ liệu thành công!")),
                                );
                              }
                            },
                      ),
                      if (readingProv.isSyncing)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                        )
                      else
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red, 
                              shape: BoxShape.circle
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text("$count", 
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), 
                              textAlign: TextAlign.center
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => context.read<AuthProvider>().logout(),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: "Tìm kiếm tên hoặc địa chỉ...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = "";
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => customerProv.fetchCustomers(),
              child: customerProv.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildCustomerList(customerProv),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList(CustomerProvider customerProv) {
    final filteredCustomers = customerProv.customers.where((customer) {
      final name = customer.name.toLowerCase();
      final address = customer.address.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || address.contains(query);
    }).toList();

    if (filteredCustomers.isEmpty) {
      return const Center(
        child: Text("Không tìm thấy hộ dân nào."),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: Text(
            "Tìm thấy ${filteredCustomers.length} hộ dân",
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: filteredCustomers.length,
            itemBuilder: (context, index) {
              final customer = filteredCustomers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF0061FF).withOpacity(0.1),
                    child: const Icon(Icons.home, color: Color(0xFF0061FF)),
                  ),
                  title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text(customer.address, style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Chip(
                            label: Text(customer.customerType.toUpperCase(), style: const TextStyle(fontSize: 10)),
                            backgroundColor: Colors.blue[50],
                          ),
                          if (customer.lastReading != null) ...[
                            const SizedBox(width: 8),
                            Chip(
                              label: Text("${customer.lastReading} m3", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                              backgroundColor: Colors.blue[50],
                              avatar: const Icon(Icons.speed, size: 12, color: Colors.blue),
                            ),
                          ],
                        ],
                      )
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReadingScreen(customer: customer),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
