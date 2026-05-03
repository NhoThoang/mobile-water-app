class Customer {
  final int id;
  final String name;
  final String address;
  final String customerType;
  final String status;
  final double? lastReading;
  final String? lastMonth;

  Customer({
    required this.id,
    required this.name,
    required this.address,
    required this.customerType,
    required this.status,
    this.lastReading,
    this.lastMonth,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      customerType: json['customer_type'] ?? 'residential',
      status: json['status'] ?? 'active',
      lastReading: json['last_reading'] != null ? (json['last_reading'] as num).toDouble() : null,
      lastMonth: json['last_month'],
    );
  }
}
