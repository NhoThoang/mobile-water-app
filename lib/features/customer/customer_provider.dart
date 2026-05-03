import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../data/models/customer_model.dart';

class CustomerProvider extends ChangeNotifier {
  List<Customer> _customers = [];
  bool _isLoading = false;

  List<Customer> get customers => _customers;
  bool get isLoading => _isLoading;

  Future<void> fetchCustomers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiClient.dio.get("/customers/");
      if (response.statusCode == 200) {
        _customers = (response.data as List)
            .map((json) => Customer.fromJson(json))
            .toList();
      }
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
