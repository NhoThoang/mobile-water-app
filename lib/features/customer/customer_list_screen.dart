import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'customer_provider.dart';
import '../auth/auth_provider.dart';
import '../reading/reading_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
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
        title: const Text("Hộ dân cần ghi số", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => context.read<AuthProvider>().logout(),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => customerProv.fetchCustomers(),
        child: customerProv.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: customerProv.customers.length,
                itemBuilder: (context, index) {
                  final customer = customerProv.customers[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 15),
                    elevation: 5,
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
                          Chip(
                            label: Text(customer.customerType.toUpperCase(), style: const TextStyle(fontSize: 10)),
                            backgroundColor: Colors.blue[50],
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
    );
  }
}
