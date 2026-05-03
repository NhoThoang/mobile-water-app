class Customer {
  final int id;
  final String name;
  final String address;
  final String customerType;
  final String status;

  Customer({
    required this.id,
    required this.name,
    required this.address,
    required this.customerType,
    required this.status,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      customerType: json['customer_type'] ?? 'residential',
      status: json['status'] ?? 'active',
    );
  }
}
